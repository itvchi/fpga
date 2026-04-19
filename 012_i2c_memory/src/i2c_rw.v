module i2c_rw(
    input clk,
    inout sda,
    input scl,
    output [3:0] hw_dbg
);

wire n_rst;

reset rst(
    .clk(clk),
    .n_rst(n_rst)
);

wire [7:0] data;
reg [7:0] counter = 8'd0;
wire i2c_reg_wr;

i2cSlave u_i2cSlave(
    .clk(clk),
    .rst(~n_rst),
    .sda(sda),
    .scl(scl),
    .i2c_reg_wr(i2c_reg_wr),
    .myReg0(data),
    .myReg1(counter)
);

always @(posedge clk) begin
    if (i2c_reg_wr) begin
        counter <= counter + 8'd1;
    end
end

endmodule