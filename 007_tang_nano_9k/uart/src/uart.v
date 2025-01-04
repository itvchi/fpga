module uart #(
    parameter INPUT_CLOCK = 27000000,
    parameter BAUD_RATE = 9600
) (
    input clk,
    input rx,
    output tx);

wire clk_en;

clock_divider #(
    .INPUT_CLOCK(INPUT_CLOCK), 
    .OUTPUT_CLOCK(2*BAUD_RATE)) 
clk_div (
    .clk(clk), 
    .clk_en(clk_en));

reg clk_counter;
wire [7:0] data;
wire data_valid;
wire busy;
reg data_ready;
reg start;

initial begin
    clk_counter <= 1'b0;
    data_ready <= 1'b0;
    start <= 1'b0;
end

wire clk_en_half;
assign clk_en_half = clk_en && clk_counter;

always @(posedge clk) begin
    start <= 1'b0;
    
    if (clk_en) begin 
        clk_counter <= clk_counter + 1'b1;
    end else begin
        clk_counter <= clk_counter;
    end

    if (data_valid) begin 
        data_ready <= 1'b1;
    end

    if (clk_en_half && data_ready && !busy) begin
        start <= 1'b1;
        data_ready <= 1'b0;
    end
end

/* RX part uses clk_en of 2*BAUD_RATE to sample incomming data in the middle */
uart_rx serial_rx (
    .clk(clk),
    .clk_en(clk_en),
    .rx(rx),
    .data(data),
    .data_valid(data_valid));

uart_tx serial_tx (
    .clk(clk),
    .clk_en(clk_en_half),
    .start(start),
    .data(data),
    .tx(tx),
    .busy(busy));

endmodule