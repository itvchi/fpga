BUILDDIR:=./build

all: sim

sim: | build_dir
	iverilog -o $(BUILDDIR)/systick_tb.vvp systick_tb.v systick.v
	cd $(BUILDDIR) && vvp systick_tb.vvp

wave:
	gtkwave $(BUILDDIR)/systick_tb.vcd &

build_dir:
	mkdir -p $(BUILDDIR)