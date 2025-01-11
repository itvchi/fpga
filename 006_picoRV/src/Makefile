BUILDDIR:=./build

all: sim

sim: | build_dir
	iverilog -o $(BUILDDIR)/systick_tb.vvp systick_tb.v systick.v
	cd $(BUILDDIR) && vvp systick_tb.vvp
	iverilog -o $(BUILDDIR)/uart_tb.vvp uart_tb.v uart.v
	cd $(BUILDDIR) && vvp uart_tb.vvp

build_dir:
	mkdir -p $(BUILDDIR)