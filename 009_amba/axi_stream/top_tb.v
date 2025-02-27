`timescale 10ns/1ns
`include "top.v"
`include "producer.v"
`include "fifo.v"
`include "fifo2stream.v"
`include "consumer.v"

module top_tb();

reg clk;
reg rst_n;
reg tready;

top UUT(
    .clk(clk),
    .rst_n(rst_n)); 

always #1 clk = ~clk; /* 50MHz clock */

initial begin
    clk = 1'b0;
    rst_n = 1'b0;

    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
    #5;
    rst_n <= 1'b1;
    #4000;

    $finish;
end

endmodule