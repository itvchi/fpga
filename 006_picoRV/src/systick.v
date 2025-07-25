module systick (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [4:0] addr, /* 32 byte address space - up to 8 registers of word size */
    input [31:0] data_i,
    output reg ready,
    output reg [31:0] data_o,
    output reg irq);

reg [31:0]      r_config;       /* offset: 0x0  RW */
reg [31:0]      r_status;       /* offset: 0x4  R  */
reg [31:0]      r_counter;      /* offset: 0x8  RW */
reg [31:0]      r_preload;      /* offset: 0xC  RW */
reg [31:0]      r_wraps;        /* offset: 0x10 RW */

reg [15:0]      r_prescaler_counter;

wire            config_reset = r_config[0];
wire            config_enable = r_config[1];
wire            config_irq = r_config[2];
wire            config_wrap = r_config[3];
wire [15:0]     config_prescaler = r_config[31:16];

initial begin
    r_config <= 32'd0;
    r_status <= 32'd0;
    r_counter <= 32'd0;
    r_preload <= 32'd0;
    r_wraps <= 32'd0;
    irq <= 1'b0;
end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            r_config <= 32'd0;
            r_status <= 32'd0;
            r_counter <= 32'd0;
            r_preload <= 32'd0;
            r_wraps <= 32'd0;
            r_prescaler_counter <= 32'd0;
            ready <= 1'b0;
            irq <= 1'b0;
        end else begin
            ready <= 1'b0;
            irq <= 1'b0;
            r_config <= r_config;
            r_status <= r_status;

            if (select) begin
                if (wstrb == 'd0) begin
                    case (addr)
                        8'h0:   data_o <= r_config;
                        8'h4:   data_o <= r_status;
                        8'h8:   data_o <= r_counter;
                        8'hC:   data_o <= r_preload;
                        8'h10:  data_o <= r_wraps;
                    endcase
                end else begin
                    case (addr)
                        8'h0:   r_config <= data_i;
                        8'h8:   r_counter <= data_i;
                        8'hC:   r_preload <= data_i;
                        8'h10:  r_wraps <= data_i;
                    endcase
                end
                ready <= 1'b1;
            end
            
            if (config_reset) begin
                r_config <= 32'd0;
                r_status <= 32'd0;
                r_counter <= 32'd0;
                r_preload <= 32'd0;
                r_wraps <= 32'd0;
                r_prescaler_counter <= 32'd0;
            end else if (config_enable) begin
                r_status[0] <= 1'b1;

                if (r_prescaler_counter >= config_prescaler) begin
                    r_prescaler_counter <= 15'd0;

                    if (r_counter) begin
                        r_counter <= r_counter - 32'd1;
                    end else begin
                        r_status[0] <= 1'b0;
                        if (config_irq) begin
                            irq <= 1'b1;
                            r_counter <= r_preload;
                        end else if (config_wrap) begin
                            r_wraps <= r_wraps + 32'd1;
                            r_counter <= r_preload;
                        end else begin
                            r_config[1] <= 1'b0;
                        end
                    end
                end else begin 
                    r_prescaler_counter <= r_prescaler_counter + 15'd1;
                end
            end
        end
    end

endmodule