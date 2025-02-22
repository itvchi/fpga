`timescale 10ns/1ns
`include "eth_rst_gen.v"
`include "packet_timer.v"
`include "crc_gen.v"
`include "packet_generator.v"
`include "top.v"

module top_tb();

reg clk;
reg rst_btn_n;
wire [1:0] eth_txd;
wire eth_txen;
    wire [2:0] eth_rxd;
reg eth_rxerr;
    wire eth_crsdv;
wire led;

top UUT (
    .clk,
    .rst_btn_n,
    .eth_txd(eth_txd),
    .eth_txen(eth_txen),
    // .eth_rxd(.eth_rxd),
    .eth_rxerr(eth_rxerr),
    // .eth_crsdv(eth_crsdv),
    .led(led));

always #1 clk = ~clk; /* 50MHz clock */

initial begin
    clk = 1'b0;
    rst_btn_n = 1'b0;
    eth_rxerr = 1'b0;

    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
    #10;
    rst_btn_n <= 1'b1;
    #1400;

    $finish;
end

endmodule