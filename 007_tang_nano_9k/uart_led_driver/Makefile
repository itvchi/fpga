SRCS := $(wildcard src/*.v)
FS := impl/pnr/tang_nano_9k.fs

uart_led_driver: $(FS)

$(FS): $(SRCS)
	@echo "Building uart_led_driver bitstream..."
	@echo "open_project ./tang_nano_9k.gprj\n run all" | gw_sh

uart_led_driver_flash: $(FS)
	@echo "Flashing uart_led_driver bitstream..."
	openFPGALoader -b tangnano9k -f $(FS)