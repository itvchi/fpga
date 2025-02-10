BUILDDIR := build
SRCS := $(wildcard src/*.v)
FS := impl/pnr/tang_nano_9k.fs
TB := $(BUILDDIR)/led_counter_tb.vvp

led_counter: $(FS)
led_counter_tb: $(TB)

$(FS): $(SRCS)
	@echo "Building led_counter bitstream..."
	@echo "open_project ./tang_nano_9k.gprj\n run all" | gw_sh

$(TB): $(SRCS) | build_dir
	@echo "Creating led_counter simulation..."
	cd src && iverilog -o ../$@ led_counter_tb.v
	cd $(BUILDDIR) && vvp led_counter_tb.vvp

led_counter_flash: $(FS)
	@echo "Flashing led_counter bitstream..."
	openFPGALoader -b tangnano9k -f $(FS)

build_dir:
	mkdir -p $(BUILDDIR)