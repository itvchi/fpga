`timescale 10ns/1ns
`include "lcd_rgb.v"
`include "pixel_generator.v"
`include "pattern_generator.v"

module lcd_rgb_tb();

reg clk;
reg rst_n;
wire [7:0] red;
wire [7:0] green;
wire [7:0] blue;
wire lcd_dclk;
wire lcd_de;
wire lcd_vsync;
wire lcd_hsync;

lcd_rgb UUT(
    .clk(clk),
    .rst_n(rst_n),
    .red(red),
    .green(green),
    .blue(blue),
    .dclk(lcd_dclk),
    .de(lcd_de),
    .vsync(lcd_vsync),
    .hsync(lcd_hsync));

/* Generate clock signal */
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

/* Generate reset signal */
initial begin
    rst_n <= 1'b0;
    #20
    rst_n = 1'b1;
end

initial begin
    $dumpfile("lcd_rgb_tb.vcd");
    $dumpvars(0, lcd_rgb_tb);

    /* Optional delay before first lcd_de assertion, which helps finding valid signals after front porch */
    #100;
    $dumpoff();
    while (!lcd_de) begin
        @(posedge clk);
    end
    $dumpon();

    #300000;
    $finish();
end

endmodule