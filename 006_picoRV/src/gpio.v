module gpio_pin (
    inout gpio,
    input af_in,
    output af_out,
    input [1:0] mode,  // 00=input, 01=output, 10=bridge, 11=reserved
    output in,
    input out);

    wire mode_input   = (mode == 2'b00);
    wire mode_output  = (mode == 2'b01);
    wire mode_bridge  = (mode == 2'b10);

    assign gpio =   mode_output ? out : 
                    mode_bridge ? af_in : 1'bz;

    assign af_out = mode_bridge ? gpio : 1'bz;

    assign in = mode_input ? gpio : 1'b0;

endmodule

module gpio (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [4:0] addr,
    input [31:0] data_i,
    output reg ready,
    output reg [31:0] data_o,
    inout [15:0] gpio,
    input [15:0] gpio_af_in,
    output [15:0] gpio_af_out);

reg [31:0]      r_mode;         /* offset: 0x00  RW */
reg [31:0]      r_out;          /* offset: 0x04  RW */
reg [31:0]      r_in;           /* offset: 0x08  R  */
reg [31:0]      r_set;          /* offset: 0x0C  W  */
reg [31:0]      r_reset;        /* offset: 0x10  W  */

wire [15:0]     gpio_in;

initial begin
    r_mode <= 32'd0;
    r_out <= 32'd0;
    r_in <= 32'd0;
    r_set <= 32'd0;
    r_reset <= 32'd0;
end

genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin : gpio_inst
        gpio_pin u_gpio_pin (
            .gpio(gpio[i]),
            .af_in(gpio_af_in[i]),
            .af_out(gpio_af_out[i]),
            .mode(r_mode[2*i +: 2]),
            .in(gpio_in[i]),
            .out(r_out[i])
        );
    end
endgenerate


always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        r_mode <= 32'd0;
        r_out <= 32'd0;
        r_in <= 32'd0;
        r_set <= 32'd0;
        r_reset <= 32'd0;
        ready <= 1'b0;
    end else begin
        ready <= 1'b0;
        r_in <= gpio_in;

        if (select) begin
            if (wstrb == 'd0) begin
                case (addr)
                    8'h00:  data_o <= r_mode;
                    8'h04:  data_o <= r_out;
                    8'h08:  data_o <= r_in;
                    8'h0C:  data_o <= 32'd0;
                    8'h10:  data_o <= 32'd0;
                endcase
            end else begin
                case (addr)
                    8'h00:  r_mode <= data_i;
                    8'h04:  r_out <= data_i;
                    8'h0C:  r_set <= data_i;
                    8'h10:  r_reset <= data_i;
                endcase
            end
            ready <= 1'b1;
        end
    end
end

endmodule