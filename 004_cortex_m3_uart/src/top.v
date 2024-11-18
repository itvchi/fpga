module top (
    input clk,
    input reset_button,
    input uart0_rx,
    output uart0_tx,
    inout user_button,
    inout user_led
);

wire [13:0] unused_gpio;

Gowin_EMPU_Top your_instance_name(
		.sys_clk(clk), //input sys_clk
		.gpio({unused_gpio, user_button, user_led}), //inout [15:0] gpio
        .uart0_rxd(uart0_rx), //input uart0_rxd
		.uart0_txd(uart0_tx), //output uart0_txd
		.reset_n(reset_button) //input reset_n
	);

endmodule