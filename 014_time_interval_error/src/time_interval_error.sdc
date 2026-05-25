create_clock -name xtal -period 37.037 [get_nets {clk}]
create_generated_clock -name pll -source [get_ports {clk}] -multiply_by 3 [get_nets {pll_clk_fast}]