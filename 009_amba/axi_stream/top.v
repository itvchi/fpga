module top (
    input clk,
    input rst_n);

wire tready;
wire fifo_full;
wire tvalid;
wire [31:0] tdata;

producer p(
    .clk(clk),
    .rst_n(rst_n),
    .m_tready(tready),
    .m_tdata(tdata),
    .m_tvalid(tvalid));

fifo #(
    .DEPTH(32), 
    .DWIDTH(32)
) f (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(tvalid),
    .din(tdata),
    .full(fifo_full));

assign tready = !fifo_full;

endmodule