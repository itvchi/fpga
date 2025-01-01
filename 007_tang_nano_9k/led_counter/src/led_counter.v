module led_counter (
    input clk,
    output [5:0] leds);

wire clk_en;
reg [5:0] led_cnt;

initial begin
    led_cnt <= 'd0;
end

clock_divider #(
    .INPUT_CLOCK(27000000), 
    .OUTPUT_CLOCK(2)
) clk_div (
    .clk(clk), 
    .clk_en(clk_en));

always @(posedge clk) begin
    if (clk_en) begin
        led_cnt <= led_cnt + 'd1;
    end
end

assign leds = led_cnt;

endmodule