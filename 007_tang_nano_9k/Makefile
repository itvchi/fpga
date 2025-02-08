all:
	@echo "Specify a project and sub-target, e.g., 'make led_counter'"

PROJECTS := led_counter uart uart_led_driver
BUILDDIR := build

led_counter:
	@echo "Building led_counter bitstream..."
	@echo "open_project ./led_counter/tang_nano_9k.gprj\n run all" | gw_sh

led_counter_tb:
	@echo "Creating led_counter simulation..."
	mkdir -p led_counter/$(BUILDDIR)
	cd led_counter/src && iverilog -o ../$(BUILDDIR)/$@.vvp $@.v
	cd led_counter/$(BUILDDIR) && vvp $@.vvp

led_counter_flash: led_counter
	@echo "Flashing led_counter bitstream..."
	openFPGALoader -b tangnano9k -f ./led_counter/impl/pnr/tang_nano_9k.fs

uart:
	@echo "Building uart bitstream..."
	@echo "open_project ./uart/tang_nano_9k.gprj\n run all" | gw_sh

uart_tb:
	@echo "Creating uart_tb simulation..."
	mkdir -p uart/$(BUILDDIR)
	cd uart/src && iverilog -o ../$(BUILDDIR)/$@.vvp $@.v
	cd uart/$(BUILDDIR) && vvp $@.vvp

uart_tx_tb:
	@echo "Creating uart_tx_tb simulation..."
	mkdir -p uart/$(BUILDDIR)
	cd uart/src && iverilog -o ../$(BUILDDIR)/$@.vvp $@.v
	cd uart/$(BUILDDIR) && vvp $@.vvp

uart_flash: uart
	@echo "Flashing uart bitstream..."
	openFPGALoader -b tangnano9k -f ./uart/impl/pnr/tang_nano_9k.fs

uart_led_driver:
	@echo "Building uart_led_driver bitstream..."
	@echo "open_project ./uart_led_driver/tang_nano_9k.gprj\n run all" | gw_sh

uart_led_driver_flash: uart_led_driver
	@echo "Flashing uart_led_driver bitstream..."
	openFPGALoader -b tangnano9k -f ./uart_led_driver/impl/pnr/tang_nano_9k.fs

.PHONY: all $(PROJECTS) flash
