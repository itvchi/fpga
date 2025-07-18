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
ifeq ($(CONFIG_TANG_NANO_9K),y)
	gw_sh tcl/minimal_9k.tcl
else ifeq ($(CONFIG_TANG_PRIMER_20K),y)
	gw_sh tcl/minimal_20k.tcl
endif
endif #($(CONFIG_FS_MINIMAL),y)

ifeq ($(CONFIG_FS_BASE),y)
	@echo "Building picoRV_base bitstream..."
ifeq ($(CONFIG_TANG_NANO_9K),y)
	gw_sh tcl/base_9k.tcl
else ifeq ($(CONFIG_TANG_PRIMER_20K),y)
	gw_sh tcl/base_20k.tcl
endif
endif # ($(CONFIG_FS_BASE),y)

ifeq ($(CONFIG_FS_LCD),y)
ifeq ($(CONFIG_TANG_NANO_9K),y)
	@echo "Building picoRV_lcd bitstream..."
	gw_sh tcl/lcd.tcl
else ifeq ($(CONFIG_TANG_PRIMER_20K),y)
	@echo "Invalid configuration"
endif
endif # ($(CONFIG_FS_LCD),y)

flash: $(FS)
ifeq ($(CONFIG_TANG_NANO_9K),y)
	@echo "Flashing picoRV bitstream..."
	openFPGALoaderGowin -b tangnano9k -f $(FS) --mcufw firmware/build/flash.bin
# @up: Use custom loader which supports user flash for GW1NR-9C
else ifeq ($(CONFIG_TANG_PRIMER_20K),y)
	@echo "Flashing picoRV bitstream..."
	openFPGALoaderGowin -b tangprimer20k -m $(FS)
else
	@echo "Flashing failed - device not supported"
endif



firmware:
	$(MAKE) -C $@

bootloader_20k:
	$(MAKE) -C $@

.PHONY: firmware bootloader_20k

build_dir:
	mkdir -p $(BUILDDIR)