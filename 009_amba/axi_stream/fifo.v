module fifo #(
    parameter DEPTH=8,
    parameter DWIDTH=16
) (
    input clk,
    input rst_n,
    input wr_en,
    input rd_en,
    input [DWIDTH-1:0] din,
    output reg [DWIDTH-1:0] dout,
    output empty,
    output full);

reg [$clog2(DEPTH)-1:0] wptr;
wire [$clog2(DEPTH)-1:0] next_wptr;
reg [$clog2(DEPTH)-1:0] rptr;

reg [DWIDTH-1:0] memory [0:DEPTH-1];

/* Write process */
always @(posedge clk) begin
    if (!rst_n) begin
        wptr <= 0;
    end else begin
        if (wr_en & !full) begin
            memory[wptr] <= din;
            wptr <= wptr + 1;
        end
    end
end

/* Read process */
always @ (posedge clk) begin
    if (!rst_n) begin
        rptr <= 0;
    end else begin
        if (rd_en & !empty) begin
            dout <= memory[rptr];
            rptr <= rptr + 1;
        end
    end
end

/* Flags */
assign next_wptr  = (wptr + 1);
assign full  = (next_wptr == rptr);
assign empty = (wptr == rptr);

endmodule