SRCS := $(wildcard src/*.v)
FS := impl/pnr/picoRV.fs

all: fs flash

fs: $(FS)
flash: $(FS)

$(FS): $(SRCS)
	@echo "Building picoRV bitstream..."
	@echo "open_project ./picoRV.gprj\n set_option -top_module top -use_sspi_as_gpio 1\n run all" | gw_sh

flash: $(FS)
	@echo "Flashing picoRV bitstream..."
	openFPGALoaderGowin -b tangnano9k -f $(FS) --mcufw firmware/build/flash.bin
# @up: Use custom loader which supports user flash for GW1NR-9C

build_dir:
	mkdir -p $(BUILDDIR)