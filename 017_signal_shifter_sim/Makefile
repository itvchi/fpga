BUILDDIR := build

all: signal_shifter_tb

signal_shifter_tb: $(BUILDDIR)/signal_shifter_tb.vvp

$(BUILDDIR)/signal_shifter_tb.vvp: signal_shifter_tb.v signal_shifter.v | build_dir
	@echo "Creating simulation..."
	iverilog -o $@ $<
	cd $(BUILDDIR) && vvp ../$@

build_dir:
	mkdir -p $(BUILDDIR)