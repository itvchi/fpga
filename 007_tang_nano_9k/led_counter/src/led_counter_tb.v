`timescale 10ns/1ns
`include "clock_divider.v"
`include "led_counter.v"

module led_counter_tb();

reg clk;
wire [5:0] leds;

led_counter UUT (
    .clk(clk), 
    .leds(leds));

always #2 clk = ~clk; /* 25MHz clock */

initial begin
    clk = 0;    

    $dumpfile("led_counter_tb.vcd");
    $dumpvars(0, led_counter_tb);
    #20000;
    $finish;
end

endmodule