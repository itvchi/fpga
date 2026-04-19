module fifo #(
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input clk,
    input n_rst,
    input wr_en,
    input [7:0] data_in,
    input rd_en,
    output reg [7:0] data_out,
    output full,
    output empty
);

reg [7:0] mem [0:DEPTH-1];

reg [ADDR_WIDTH:0] wr_ptr = 0;
reg [ADDR_WIDTH:0] rd_ptr = 0;

always @(posedge clk) begin
    if (!n_rst) begin
        wr_ptr <= 0;
    end else if (wr_en && !full) begin
        mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_in;
        wr_ptr <= wr_ptr + 1;
    end
end

always @(posedge clk) begin
    if (!n_rst) begin
        rd_ptr <= 0;
        data_out <= 0;
    end else if (rd_en && !empty) begin
        data_out <= mem[rd_ptr[ADDR_WIDTH-1:0]];
        rd_ptr <= rd_ptr + 1;
    end
end

assign empty = (wr_ptr == rd_ptr);
assign full = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);

endmodule