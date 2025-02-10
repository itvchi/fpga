SRCS := $(wildcard src/*.v)
FS := impl/pnr/tang_nano_9k.fs

lan8720: $(FS)

$(FS): $(SRCS)
	@echo "Building lan8720 bitstream..."
	@echo "open_project ./tang_nano_9k.gprj\n run all" | gw_sh

lan8720_flash: $(FS)
	@echo "Flashing lan8720 bitstream..."
	openFPGALoader -b tangnano9k -f $(FS)