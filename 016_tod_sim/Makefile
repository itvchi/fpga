SRCS := $(wildcard src/*.v)
BUILDDIR := build

all: tb

tb: $(BUILDDIR)/tod_tb.vvp

$(BUILDDIR)/tod_tb.vvp: $(SRCS) | build_dir
	@echo "Creating simulation..."
	cd src && iverilog -o ../$@ tod_tb.v
	cd $(BUILDDIR) && vvp ../$@

build_dir:
	mkdir -p $(BUILDDIR)