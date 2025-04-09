create_project -name 006_picoRV -pn GW1NR-LV9QN88PC6/I5 -device_version C -force -dir ../
add_file -type verilog "src/top_base.v"
add_file -type verilog "src/picorv32.v"
add_file -type verilog "src/reset_control.v"
add_file -type verilog "src/sram.v"
add_file -type verilog "src/gowin_user_flash/gowin_user_flash.v"
add_file -type verilog "src/user_flash_custom.v"
add_file -type verilog "src/mm_leds.v"
add_file -type verilog "src/systick.v"
add_file -type verilog "src/uart.v"
add_file -type verilog "src/lcd_rgb.v"
add_file -type cst "constraints/lcd.cst"
add_file -type sdc "constraints/common.sdc"
set_option -synthesis_tool gowinsynthesis
set_option -output_base_name picoRV
set_option -top_module top
run all