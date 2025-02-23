BUILDDIR := build
SRCS := $(wildcard src/*.v)
FS := impl/pnr/tang_nano_9k.fs
TB := $(BUILDDIR)/top_tb.vvp

lan8720: $(FS)
lan8720_tb: $(TB)

$(FS): $(SRCS)
	@echo "Building lan8720 bitstream..."
	@echo "open_project ./tang_nano_9k.gprj\n set_option -top_module top\n run all" | gw_sh

$(TB): $(SRCS) | build_dir
	@echo "Creating lan8720 simulation..."
	cd src && iverilog -o ../$@ top_tb.v -DSIM
	cd $(BUILDDIR) && vvp top_tb.vvp

lan8720_flash: $(FS)
	@echo "Flashing lan8720 bitstream..."
	openFPGALoader -b tangnano9k -f $(FS)

build_dir:
	mkdir -p $(BUILDDIR)