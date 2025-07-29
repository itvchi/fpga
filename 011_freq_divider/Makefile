BUILDDIR := build
SRCS := $(wildcard *.v)

all: tb

tb: $(SRCS) | build_dir
	@echo "Creating simulation..."
	iverilog -o $(BUILDDIR)/top_tb.vvp top_tb.v
	cd $(BUILDDIR) && vvp top_tb.vvp

build_dir:
	mkdir -p $(BUILDDIR)