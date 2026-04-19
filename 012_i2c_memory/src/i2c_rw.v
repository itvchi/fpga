module i2c_rw(
    input clk,
    inout sda,
    input scl
);

wire n_rst;

reset rst(
    .clk(clk),
    .n_rst(n_rst)
);

wire [7:0] data;

i2cSlave u_i2cSlave(
    .clk(clk),
    .rst(~n_rst),
    .sda(sda),
    .scl(scl),
    .myReg0(data),
    .myReg1(8'd0)
);

endmodule