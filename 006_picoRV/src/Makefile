BUILDDIR:=./build

all: sim

sim: | build_dir
	iverilog -o $(BUILDDIR)/systick_tb.vvp systick_tb.v systick.v
	cd $(BUILDDIR) && vvp systick_tb.vvp
	iverilog -o $(BUILDDIR)/uart_tb.vvp uart_tb.v uart.v
	cd $(BUILDDIR) && vvp uart_tb.vvp
	iverilog -o $(BUILDDIR)/spi_tb.vvp spi_tb.v spi.v
	cd $(BUILDDIR) && vvp spi_tb.vvp

build_dir:
	mkdir -p $(BUILDDIR)