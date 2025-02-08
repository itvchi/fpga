`timescale 10ns/1ns
`include "clock_divider.v"
`include "uart_tx.v"

module uart_tx_tb();

reg clk;
reg rst_n;
wire clk_en;
reg start;
reg [7:0] data;
wire tx;
wire busy;

always #2   clk = ~clk; /* 25MHz clock */

clock_divider #(
    .INPUT_CLOCK(25000000),
    .OUTPUT_CLOCK(1000000))
clk_div (
    .clk(clk), 
    .clk_en(clk_en));

uart_tx UUT (
    .clk(clk),
    .clk_en(clk_en),
    .rst_n(rst_n),
    .start(start),
    .data(data),
    .tx(tx),
    .busy(busy));

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    start = 1'b0;
    data <= 8'hC0;

    $dumpfile("uart_tx_tb.vcd");
    $dumpvars(0, uart_tx_tb);

    #10
    rst_n <= 1'b1;
    #100
    start <= 1'b1;
    #10
    start <= 1'b0;

    #100
    if (busy) begin
        @(negedge busy);
    end
    #100

    $finish;
end

endmodule