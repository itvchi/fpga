module top (
    input clk,
    input rst_n,
    input tready); /* External for testbench only (temporary) */

wire tvalid;
wire [31:0] tdata;

producer p(
    .clk(clk),
    .rst_n(rst_n),
    .m_tready(tready),
    .m_tdata(tdata),
    .m_tvalid(tvalid));

endmodule