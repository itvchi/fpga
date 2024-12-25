module systick (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [3:0] addr, /* 16 byte address space - up to 4 registers of word size */
    input [31:0] data_i,
    output reg ready,
    output reg [31:0] data_o,
    output reg irq);

reg [31:0]      r_config;   /* offset: 0x0  RW */
reg [31:0]      r_status;   /* offset: 0x4  R  */
reg [31:0]      r_counter;  /* offset: 0x8  RW */

reg [15:0]      r_prescaler_counter;

wire            config_reset = r_config[0];
wire            config_enable = r_config[1];
wire            config_irq = r_config[2];
wire [15:0]     config_prescaler = r_config[31:16];

initial begin
    r_config <= 32'd0;
    r_status <= 32'd0;
    r_counter <= 32'd0;
    irq <= 1'b0;
end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            r_config <= 32'd0;
            r_status <= 32'd0;
            r_counter <= 32'd0;
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
                    endcase
                end else begin
                    case (addr)
                        8'h0:   r_config <= data_i;
                        8'h8:   r_counter <= data_i;
                    endcase
                end
                ready <= 1'b1;
            end
            
            if (config_reset) begin
                r_config <= 32'd0;
                r_status <= 32'd0;
                r_counter <= 32'd0;
                r_prescaler_counter <= 32'd0;
            end else if (config_enable) begin
                r_status[0] <= 1'b1;

                if (r_prescaler_counter >= config_prescaler) begin
                    r_prescaler_counter <= 15'd0;

                    if (r_counter) begin
                        r_counter <= r_counter - 32'd1;
                    end else begin
                        r_config[1] <= 1'b0;
                        r_status[0] <= 1'b0;
                        if (config_irq) begin
                            irq <= 1'b1;
                        end
                    end
                end else begin 
                    r_prescaler_counter <= r_prescaler_counter + 15'd1;
                end
            end
        end
    end

endmodule