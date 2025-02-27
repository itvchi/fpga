module top (
    input clk,
    input rst_n);

wire tready;
wire fifo_full;
wire tvalid;
wire [31:0] tdata;
wire [31:0] mem_data;
wire empty;
wire rd_en;
wire tready2;
wire tvalid2;
wire [7:0] tdata2;

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
    .full(fifo_full),
    .rd_en(rd_en),
    .dout(mem_data),
    .empty(empty));

assign tready = !fifo_full;

fifo2stream f2s (
    .clk(clk),
    .rst_n(rst_n),
    .data(mem_data),
    .empty(empty),
    .rd_en(rd_en),
    .m_tready(tready2),
    .m_tdata(tdata2),
    .m_tvalid(tvalid2));

consumer c (
    .clk(clk),
    .rst_n(rst_n),
    .s_tvalid(tvalid2),
    .s_tdata(tdata2),
    .s_tready(tready2));

endmodule