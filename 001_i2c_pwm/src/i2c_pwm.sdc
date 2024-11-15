//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.9.03  Education
//Created Time: 2024-07-13 16:20:17
create_clock -name fpga_input_clock -period 37.037 -waveform {0 18.518} [get_ports {clk}]
