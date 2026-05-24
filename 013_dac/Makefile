FS := impl/pnr/dac.fs
SRCS := $(wildcard src/*.v)
BUILDDIR := build

all: dac

dac: $(SRCS)
	@echo "Building dac bitstream..."
	@echo "open_project ./dac.gprj\n set_option -top_module top\n run all" | gw_sh

flash: $(FS)
	@echo "Flashing dac bitstream..."
	openFPGALoader -b tangnano9k -f $(FS)

tb: $(BUILDDIR)/top_tb.vvp

$(BUILDDIR)/top_tb.vvp: $(SRCS) | build_dir
	@echo "Creating dac simulation..."
	cd src && iverilog -o ../$@ top_tb.v
	cd $(BUILDDIR) && vvp ../$@

build_dir:
	mkdir -p $(BUILDDIR)