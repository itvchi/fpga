module apb_pwm (
    input wire        pclk,
    input wire        preset_n,
    input wire        penable,
    input wire [7:0]  paddr,
    input wire        pwrite,
    input wire [31:0] pwdata,
    input wire [3:0]  pstrb,
    input wire [2:0]  pprot,
    input wire        psel,
    output reg [31:0] prdata,
    output reg        pready,
    output wire       pwm_out);

reg [31:0]      r_config;   /* offset: 0x0  RW */
reg [31:0]      r_counter;  /* offset: 0x4  R  */
reg [31:0]      r_reload;   /* offset: 0x8  RW */
reg [31:0]      r_trigger;  /* offset: 0xC  RW */

wire            config_reset = r_config[0];
wire            config_enable = r_config[1];
wire            config_dir = r_config[2]; /* 0 = up, 1 = down */
wire            config_active = r_config[3]; /* when r_counter > r_trigger; 0 = low, 1 = high */
wire [15:0]     config_prescaler = r_config[31:16];
reg [15:0]      r_prescaler_counter;

initial begin
    r_config <= 32'd0;
    r_counter <= 32'd0;
    r_reload <= 32'hFFFFFFFF;
    r_trigger <= 32'h7FFFFFFF;
    r_prescaler_counter <= 32'd0;
end

assign pwm_out = (r_counter > r_trigger) ? config_active : ~config_active;


always @(posedge pclk or negedge preset_n)
    if(!preset_n) begin
        pready <= 1'b0;
        r_config <= 32'd0;
        r_counter <= 32'd0;
        r_reload <= 32'hFFFFFFFF;
        r_trigger <= 32'h7FFFFFFF;
        r_prescaler_counter <= 32'd0;
    end else begin
        if (psel & !penable) begin
            /* setup state.  Inputs are stable.  Make outputs stable
            * for next clock cycle, the access state */
            if (pwrite) begin
                case (paddr)
                    8'h0:   r_config <= pwdata;
                    8'h8:   r_reload <= pwdata;
                    8'hC:   r_trigger <= pwdata;
                endcase
            end else begin
                case (paddr)
                    8'h0:   prdata <= r_config;
                    8'h4:   prdata <= r_counter;
                    8'h8:   prdata <= r_reload;
                    8'hC:   prdata <= r_trigger;
                endcase
            end
            pready <= 1'b1;
        end else begin
            /* access state */
            if (config_reset) begin
                r_config <= 32'd0;
                r_counter <= 32'd0;
                r_reload <= 32'hFFFFFFFF;
                r_trigger <= 32'h7FFFFFFF;
                r_prescaler_counter <= 32'd0;
            end
            pready <= 1'b0;
        end

        /* PWM counter */
        if (r_prescaler_counter >= config_prescaler) begin
            r_prescaler_counter <= 32'd0;

            if (r_counter >= r_reload) begin
                r_counter <= 32'd0;
            end else begin
                r_counter <= r_counter + 32'd1;
            end
        end else begin 
            r_prescaler_counter <= r_prescaler_counter + 32'd1;
        end
    end
endmodule