SRCS := $(wildcard src/*.v)
BUILDDIR := build

all: tod_tb tod_nco_tb

tod_tb: $(BUILDDIR)/tod_tb.vvp
tod_nco_tb: $(BUILDDIR)/tod_nco_tb.vvp

$(BUILDDIR)/tod_tb.vvp: $(SRCS) | build_dir
	@echo "Creating simulation..."
	cd src && iverilog -o ../$@ tod_tb.v
	cd $(BUILDDIR) && vvp ../$@

$(BUILDDIR)/tod_nco_tb.vvp: $(SRCS) | build_dir
	@echo "Creating simulation..."
	cd src && iverilog -o ../$@ tod_nco_tb.v
	cd $(BUILDDIR) && vvp ../$@

build_dir:
	mkdir -p $(BUILDDIR)