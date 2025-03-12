BUILDDIR:=./build
FS := impl/pnr/tang_nano_9k.fs
SRCS := $(wildcard src/*.v)

all: spi_master

spi_master_tb: $(SRCS) | build_dir
	iverilog -o $(BUILDDIR)/spi_master_tb.vvp src/spi_master_tb.v src/spi_master.v
	cd $(BUILDDIR) && vvp spi_master_tb.vvp 

spi_master: $(SRCS)
	@echo "Building spi_master bitstream..."
	@echo "open_project ./tang_nano_9k.gprj\n run all" | gw_sh

flash: $(FS)
	@echo "Flashing spi_master bitstream..."
	openFPGALoader -b tangnano9k -f $(FS)

build_dir:
	mkdir -p $(BUILDDIR)