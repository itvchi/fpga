`timescale 1ns/10ps
module ws2812_tb;

reg clk = 1'b1;
reg r_send;
reg [7:0] r_red;
reg [7:0] r_green;
reg [7:0] r_blue;
wire o_busy;
wire o_data;

	ws2812b_data ws(clk, r_send, r_red, r_green, r_blue, o_busy, o_data);

	always #10 clk = ~clk;

	always
	begin
		#50 r_red = 255;
		r_green = 128;
		r_blue = 64;
		#50 r_send = 1'b1;
		#10 r_send = 1'b0;
		#50000;

		#50 r_red = 64;
		r_green = 128;
		r_blue = 255;
		#50 r_send = 1'b1;
		#10 r_send = 1'b0;
		#50000;

		#50 r_red = 128;
		r_green = 128;
		r_blue = 128;
		#50 r_send = 1'b1;
		#10 r_send = 1'b0;
		#50000;

		$finish;
	end
endmodule