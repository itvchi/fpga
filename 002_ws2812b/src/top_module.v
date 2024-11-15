module top_module (
    input i_clk,
    output o_data
);

wire [7:0] w_red;
wire [7:0] w_green;
wire [7:0] w_blue;
wire w_send;
wire w_busy;
    
    color_generator gen (i_clk, w_send, w_red, w_green, w_blue);
    ws2812b led (i_clk, w_send, w_red, w_green, w_blue, o_data);

endmodule