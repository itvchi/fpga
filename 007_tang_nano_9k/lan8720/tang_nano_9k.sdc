//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.03 Education 
//Created Time: 2025-02-23 11:11:58
create_clock -name clk -period 20 -waveform {0 10} [get_ports {clk}]
