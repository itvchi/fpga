create_clock -name xtal -period 20.0 -waveform {0 10} [get_nets {clk}]
create_generated_clock -name pll -source [get_ports {clk}] -multiply_by 5 [get_nets {pll_clk}]
create_generated_clock -name pll_180 -source [get_ports {clk}] -multiply_by 5 -phase 180 [get_nets {pll_clk180}]

set_multicycle_path -setup 2 -from [get_cells {ns_counter_*}] -to [get_cells {ns_top_r_s0}]
set_multicycle_path -hold 1 -from [get_cells {ns_counter_*}] -to [get_cells {ns_top_r_s0}]