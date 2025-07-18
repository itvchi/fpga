create_project -name 006_picoRV -pn GW2A-LV18PG256C8/I7 -device_version C -force -dir ../
add_file -type verilog "src/top_base.v"
add_file -type verilog "src/picorv32.v"
add_file -type verilog "src/reset_control.v"
add_file -type verilog "src/sram.v"
add_file -type verilog "src/rom.v"
add_file -type verilog "src/gowin_rpll_20k/gowin_rpll.v"
add_file -type verilog "src/user_flash_custom_mock.v"
add_file -type verilog "src/mm_leds.v"
add_file -type verilog "src/systick.v"
add_file -type verilog "src/uart.v"
add_file -type verilog "src/spi.v"
add_file -type verilog "src/gpio.v"
add_file -type cst "constraints/base_20k.cst"
add_file -type sdc "constraints/common.sdc"
set_option -synthesis_tool gowinsynthesis
set_option -output_base_name picoRV
set_option -top_module top_base
run all