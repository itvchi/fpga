module top (
    input clk,
    input rx,
    output tx);

uart #(
    .INPUT_CLOCK(27000000),
    .BAUD_RATE(9600))
serial (
    .clk(clk),
    .rx(rx),
    .tx(tx));

endmodule