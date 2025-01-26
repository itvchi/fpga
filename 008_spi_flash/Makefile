BUILDDIR:=./build

all: sim_spiflash sim_spiflash_reader

sim_spiflash: | build_dir
	iverilog -o $(BUILDDIR)/spiflash_tb.vvp spiflash_tb.v spiflash.v
	cd $(BUILDDIR) && vvp spiflash_tb.vvp

sim_spiflash_reader: | build_dir
	iverilog -o $(BUILDDIR)/spiflash_reader_tb.vvp spiflash_reader_tb.v spiflash_reader.v spiflash.v
	cd $(BUILDDIR) && vvp spiflash_reader_tb.vvp

build_dir:
	mkdir -p $(BUILDDIR)