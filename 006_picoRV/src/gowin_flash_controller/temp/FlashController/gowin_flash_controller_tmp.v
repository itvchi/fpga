//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.9.03 Education
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Fri Dec 27 11:42:56 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Gowin_Flash_Controller_Top your_instance_name(
		.wdata_i(wdata_i), //input [31:0] wdata_i
		.wyaddr_i(wyaddr_i), //input [5:0] wyaddr_i
		.wxaddr_i(wxaddr_i), //input [8:0] wxaddr_i
		.erase_en_i(erase_en_i), //input erase_en_i
		.done_flag_o(done_flag_o), //output done_flag_o
		.start_flag_i(start_flag_i), //input start_flag_i
		.clk_i(clk_i), //input clk_i
		.nrst_i(nrst_i), //input nrst_i
		.rdata_o(rdata_o), //output [31:0] rdata_o
		.wr_en_i(wr_en_i) //input wr_en_i
	);

//--------Copy end-------------------
