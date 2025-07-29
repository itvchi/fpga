`timescale 100ns/100ps
`include "top.v"

module top_tb();

reg clk = 0;
wire freq;

always #5 clk = ~clk; /* 1MHz clock */

top UUT(
    .clk(clk),
    .freq(freq));

initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
    #120000000;

    $finish;
end

endmodule