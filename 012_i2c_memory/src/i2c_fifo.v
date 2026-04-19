module i2c_fifo(
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

reg wr_en;
reg rd_en;
wire full;
wire empty;
wire i2c_reg_wr;
wire i2c_reg_rd;
wire [7:0] data_in;
wire [7:0] data_out;

fifo #(
    .DEPTH(16)
) fifo_mem (
    .clk(clk),
    .n_rst(n_rst),
    .wr_en(wr_en),
    .data_in(data_in),
    .rd_en (rd_en),
    .data_out(data_out),
    .full(full),
    .empty(empty)
);

i2cSlave u_i2cSlave(
    .clk(clk),
    .rst(~n_rst),
    .sda(sda),
    .scl(scl),
    .i2c_reg_wr(i2c_reg_wr),
    .i2c_reg_rd(i2c_reg_rd),
    .myReg0(data_in),
    .myReg1(data_out)
);

always @(posedge clk) begin
    wr_en <= 1'b0;
    rd_en <= 1'b0;

    if (i2c_reg_wr && !full) begin
        wr_en <= 1'b1;
    end
    if (i2c_reg_rd && !empty) begin
        rd_en <= 1'b1;
    end
end

assign hw_dbg[0] = scl;
assign hw_dbg[1] = sda;
assign hw_dbg[2] = i2c_reg_wr;
assign hw_dbg[3] = i2c_reg_rd;

endmodule