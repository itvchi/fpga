BUILDDIR := build
SRCS := $(wildcard src/*.v)
FS := impl/pnr/tang_nano_9k.fs
TB := $(BUILDDIR)/lcd_rgb_tb.vvp

lcd_rgb: $(FS)
lcd_rgb_tb: $(TB)

$(FS): $(SRCS)
	@echo "Building lcd_rgb bitstream..."
	@echo "open_project ./tang_nano_9k.gprj\n set_option -top_module top\n run all" | gw_sh

$(TB): $(SRCS) | build_dir
	@echo "Creating lcd_rgb simulation..."
	cd src && iverilog -o ../$@ lcd_rgb_tb.v -DSIM
	cd $(BUILDDIR) && vvp lcd_rgb_tb.vvp

lcd_rgb_flash: $(FS)
	@echo "Flashing lcd_rgb bitstream..."
	openFPGALoader -b tangnano9k -f $(FS)

build_dir:
	mkdir -p $(BUILDDIR)