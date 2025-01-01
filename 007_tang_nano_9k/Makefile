all:
	@echo "Specify a project and sub-target, e.g., 'make led_counter'"

PROJECTS := led_counter

led_counter:
	@echo "Building led_counter bitstream..."
	# @echo "open_project ./led_counter/tang_nano_9k.gprj\n run all" | gw_sh 

led_counter_flash: led_counter
	@echo "Flashing led_counter bitstream..."
	openFPGALoader -b tangnano9k -f ./led_counter/impl/pnr/tang_nano_9k.fs


.PHONY: all $(PROJECTS) flash
