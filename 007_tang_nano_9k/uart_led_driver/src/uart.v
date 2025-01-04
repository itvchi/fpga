module uart #(
    parameter INPUT_CLOCK = 27000000,
    parameter BAUD_RATE = 9600
) (
    input clk,
    input rx,
    output [7:0] rx_data,
    output rx_valid,
    input tx_start,
    input [7:0] tx_data,
    output tx_busy,
    output tx);

wire clk_en;

clock_divider #(
    .INPUT_CLOCK(INPUT_CLOCK), 
    .OUTPUT_CLOCK(2*BAUD_RATE)) 
clk_div (
    .clk(clk), 
    .clk_en(clk_en));

reg clk_counter;
wire clk_en_half;

initial begin
    clk_counter <= 1'b0;
end

assign clk_en_half = clk_en && clk_counter;

always @(posedge clk) begin
    if (clk_en) begin 
        clk_counter <= clk_counter + 1'b1;
    end else begin
        clk_counter <= clk_counter;
    end
end

/* RX part uses clk_en of 2*BAUD_RATE to sample incomming data in the middle */
uart_rx serial_rx (
    .clk(clk),
    .clk_en(clk_en),
    .rx(rx),
    .data(rx_data),
    .data_valid(rx_valid));

uart_tx serial_tx (
    .clk(clk),
    .clk_en(clk_en_half),
    .start(tx_start),
    .data(tx_data),
    .tx(tx),
    .busy(tx_busy));

endmodule