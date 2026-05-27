SRCS := $(wildcard src/*.v)
BUILDDIR := build

all: tb

tb: $(BUILDDIR)/top_tb.vvp

$(BUILDDIR)/top_tb.vvp: $(SRCS) | build_dir
	@echo "Creating simulation..."
	cd src && iverilog -o ../$@ top_tb.v
	cd $(BUILDDIR) && vvp ../$@

build_dir:
	mkdir -p $(BUILDDIR)