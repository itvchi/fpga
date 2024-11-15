`include "i2c_ip_core/i2cSlave_define.v"

module top_module(
    input clk,
    inout sda,
    input scl,
    output reg [5:0] led);

wire [7:0] pwm_reg [5:0];
wire [5:0] n_led;

reg  [23:0] r_rst;
wire n_rst;

initial begin
    r_rst <= 24'd0;
end

always @(posedge clk) begin
    if (r_rst[23] == 1'b0) begin
        r_rst <= r_rst + 24'd1;
    end
end

assign n_rst = r_rst[23];

i2cSlave u_i2cSlave(
    .clk(clk),
    .rst(~n_rst),
    .sda(sda),
    .scl(scl),
    .myReg0(pwm_reg[0]),
    .myReg1(pwm_reg[1]),
    .myReg2(pwm_reg[2]),
    .myReg3(pwm_reg[3]),
    .myReg4(pwm_reg[4]),
    .myReg5(pwm_reg[5])
);

pwm #(.CHANNELS(6)) led_pwm(
    .clk(clk),
    .n_rst(n_rst),
    .pwm_value(pwm_reg),
    .pwm_out(n_led)
);

assign led = ~n_led;

endmodule





