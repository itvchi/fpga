BUILDDIR:=./build

all: sim

sim: | build_dir
	iverilog -o $(BUILDDIR)/spiflash_tb.vvp spiflash_tb.v spiflash.v
	cd $(BUILDDIR) && vvp spiflash_tb.vvp

build_dir:
	mkdir -p $(BUILDDIR)