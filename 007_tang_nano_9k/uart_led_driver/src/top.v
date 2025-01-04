module top (
    input clk,
    input rx,
    output tx,
    output [5:0] leds);

led_driver driver (
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .leds(leds));

endmodule