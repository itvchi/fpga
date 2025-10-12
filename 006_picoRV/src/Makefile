BUILDDIR:=./build
TESTBENCHDIR:=./testbench

all: sim

sim: | build_dir
	iverilog -o $(BUILDDIR)/systick_tb.vvp $(TESTBENCHDIR)/systick_tb.v systick.v
	cd $(BUILDDIR) && vvp systick_tb.vvp
	iverilog -o $(BUILDDIR)/uart_tb.vvp $(TESTBENCHDIR)/uart_tb.v uart.v
	cd $(BUILDDIR) && vvp uart_tb.vvp
	iverilog -o $(BUILDDIR)/spi_tb.vvp $(TESTBENCHDIR)/spi_tb.v spi.v
	cd $(BUILDDIR) && vvp spi_tb.vvp
	iverilog -o $(BUILDDIR)/new_spi_tb.vvp $(TESTBENCHDIR)/new_spi_tb.v new_spi.v
	cd $(BUILDDIR) && vvp new_spi_tb.vvp

build_dir:
	mkdir -p $(BUILDDIR)