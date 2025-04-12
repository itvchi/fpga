KCONFIG_CONFIG := .config
SRCS := $(wildcard src/*.v)
FS := impl/pnr/picoRV.fs

all: fs firmware

menuconfig:
	kconfig-mconf Kconfig

include .config

fs: $(SRCS) $(KCONFIG_CONFIG)
ifeq ($(CONFIG_FS_MINIMAL),y)
	@echo "Building picoRV_minimal bitstream..."
	gw_sh tcl/minimal.tcl
endif
ifeq ($(CONFIG_FS_BASE),y)
	@echo "Building picoRV_base bitstream..."
	gw_sh tcl/base.tcl
endif
ifeq ($(CONFIG_FS_LCD),y)
	@echo "Building picoRV_lcd bitstream..."
	gw_sh tcl/base.tcl
endif

flash: $(FS)
	@echo "Flashing picoRV bitstream..."
	openFPGALoaderGowin -b tangnano9k -f $(FS) --mcufw firmware/build/flash.bin
# @up: Use custom loader which supports user flash for GW1NR-9C

firmware:
	$(MAKE) -C $@

.PHONY: firmware

build_dir:
	mkdir -p $(BUILDDIR)