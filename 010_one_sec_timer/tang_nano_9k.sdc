create_clock -name xtal -period 20 -waveform {0 10} [get_nets {clk}]
create_clock -name pll -period 4 -waveform {0 2} [get_nets {pll_clk}]