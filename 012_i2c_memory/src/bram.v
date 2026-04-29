module bram #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 1024,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input clk,
    input wr_en,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

always @(posedge clk) begin
    if (wr_en) begin
        mem[addr] <= data_in;
    end

    data_out <= mem[addr];
end

endmodule