SRCS := $(wildcard src/*.v)
FS := impl/pnr/picoRV.fs

all:
	@echo "No target selected. Available targets:\
	\nfs_minimal, fs_base, fs_lcd"

fs_minimal: $(FS) 
fs_base: $(FS)
fs_lcd: $(FS)

fs_minimal: $(SRCS)
	@echo "Building picoRV_minimal bitstream..."
	gw_sh tcl/minimal.tcl

fs_base: $(SRCS)
	@echo "Building picoRV_base bitstream..."
	gw_sh tcl/base.tcl

fs_lcd: $(SRCS)
	@echo "Building picoRV_lcd bitstream..."
	gw_sh tcl/base.tcl

flash: $(FS)
	@echo "Flashing picoRV bitstream..."
	openFPGALoaderGowin -b tangnano9k -f $(FS) --mcufw firmware/build/flash.bin
# @up: Use custom loader which supports user flash for GW1NR-9C

firmware:
	$(MAKE) -C $@

.PHONY: firmware

build_dir:
	mkdir -p $(BUILDDIR)