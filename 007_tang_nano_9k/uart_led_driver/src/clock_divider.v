module clock_divider #(
    parameter INPUT_CLOCK = 1000000,
    parameter OUTPUT_CLOCK = 1000
) (
    input clk,
    output reg clk_en);

localparam TICKS = (INPUT_CLOCK/OUTPUT_CLOCK);
localparam BITS = $clog2(TICKS);

reg [BITS-1:0] counter;

initial begin
    counter <= 'd0;
    clk_en <= 'd0;
end

always @(posedge clk) begin
    clk_en <= 0;
    counter <= counter + 'd1;

    if (counter == (TICKS - 1)) begin
        clk_en <= 1'b1;
        counter <= 'd0;
    end
end

endmodule