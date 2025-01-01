module top (
    input clk,
    output [5:0] leds);

wire [5:0] leds_n;

led_counter lc (
    .clk(clk),
    .leds(leds_n));

assign leds = ~leds_n; /* leds are connected with common cathode */

endmodule