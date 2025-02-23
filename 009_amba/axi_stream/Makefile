BUILDDIR := build
SRCS := $(wildcard *.v)
TB := $(BUILDDIR)/top_tb.vvp

sll: $(TB)

$(TB): $(SRCS) | build_dir
	@echo "Creating simulation..."
	iverilog -o $@ top_tb.v
	cd $(BUILDDIR) && vvp top_tb.vvp

build_dir:
	mkdir -p $(BUILDDIR)