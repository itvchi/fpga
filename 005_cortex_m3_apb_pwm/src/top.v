module top (
    input clk,
    input reset_button,
    input uart0_rx,
    output uart0_tx,
    output user_led
);

wire        pclk;
wire        preset_n;
wire        penable;
wire [7:0]  paddr;
wire        pwrite;
wire [31:0] pwdata;
wire [3:0]  pstrb;
wire [2:0]  pprot;
wire        psel1;
wire [31:0] prdata1;
wire        pready1;

Gowin_EMPU_Top your_instance_name(
		.sys_clk(clk), //input sys_clk
		.uart0_rxd(uart0_rx), //input uart0_rxd
		.uart0_txd(uart0_tx), //output uart0_txd
		.master_pclk(pclk), //output master_pclk
		.master_prst(preset_n), //output master_prst
		.master_penable(penable), //output master_penable
		.master_paddr(paddr), //output [7:0] master_paddr
		.master_pwrite(pwrite), //output master_pwrite
		.master_pwdata(pwdata), //output [31:0] master_pwdata
		.master_pstrb(pstrb), //output [3:0] master_pstrb
		.master_pprot(pprot), //output [2:0] master_pprot
		.master_psel1(psel1), //output master_psel1
		.master_prdata1(prdata1), //input [31:0] master_prdata1
		.master_pready1(pready1), //input master_pready1
		.master_pslverr1(1'b0), //input master_pslverr1
		.reset_n(reset_button) //input reset_n
	);

apb_pwm pwm_controller(
	.pclk(pclk),
	.preset_n(preset_n),
	.penable(penable),
	.paddr(paddr),
	.pwrite(pwrite),
	.pwdata(pwdata),
	.pstrb(pstrb),
	.pprot(pprot),
	.psel(psel1),
	.prdata(prdata1),
	.pready(pready1),
	.pwm_out(user_led)
	);

endmodule