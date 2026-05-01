create_project -name 006_picoRV -pn GW1NR-LV9QN88PC6/I5 -device_version C -force -dir ../
source tcl/system_minimal.tcl
source tcl/flash_controller.tcl
add_file -type verilog "src/top_minimal.v"
add_file -type verilog "src/gowin_rpll_9k/gowin_rpll.v"
add_file -type cst "constraints/minimal_9k.cst"
add_file -type sdc "constraints/common.sdc"
set_option -synthesis_tool gowinsynthesis
set_option -output_base_name picoRV
set_option -top_module top
run all