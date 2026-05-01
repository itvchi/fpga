KCONFIG_CONFIG := .config
SRCS := $(wildcard src/*.v)
FS := impl/pnr/picoRV.fs

all: fs firmware

-include $(KCONFIG_CONFIG)

fs: $(SRCS) $(KCONFIG_CONFIG)
ifeq ($(CONFIG_FEATURE_FLASH_CACHE),y)
	ln -sf ./flash_controller_custom.tcl tcl/flash_controller.tcl
else
	ln -sf ./flash_controller_gowin.tcl tcl/flash_controller.tcl
endif
ifeq ($(CONFIG_TARGET_TANG_NANO_9K)$(CONFIG_FS_MINIMAL),yy)
	@echo "Building picoRV_minimal bitstream..."
	gw_sh tcl/minimal_9k.tcl
else ifeq ($(CONFIG_TARGET_TANG_NANO_9K)$(CONFIG_FS_BASE),yy)
	@echo "Building picoRV_base bitstream..."
	gw_sh tcl/base_9k.tcl
else ifeq ($(CONFIG_TARGET_TANG_NANO_9K)$(CONFIG_FS_LCD),yy)
	@echo "Building picoRV_lcd bitstream..."
	gw_sh tcl/lcd.tcl
else ifeq ($(CONFIG_TARGET_TANG_PRIMER_20K)$(CONFIG_FS_MINIMAL),yy)
	@echo "Building picoRV_minimal bitstream..."
	gw_sh tcl/minimal_20k.tcl
else ifeq ($(CONFIG_TARGET_TANG_PRIMER_20K)$(CONFIG_FS_BASE),yy)
	@echo "Building picoRV_base bitstream..."
	gw_sh tcl/base_20k.tcl
else
	@echo "Target not supported or invalid system version"
endif


flash: $(FS)
ifeq ($(CONFIG_TARGET_TANG_NANO_9K),y)
	@echo "Flashing picoRV bitstream..."
	openFPGALoaderGowin -b tangnano9k -f $(FS) --mcufw firmware/build/flash.bin
# @up: Use custom loader which supports user flash for GW1NR-9C
else ifeq ($(CONFIG_TARGET_TANG_PRIMER_20K),y)
	@echo "Flashing picoRV bitstream..."
	openFPGALoaderGowin -b tangprimer20k -m $(FS)
else
	@echo "Flashing failed - device not supported"
endif


firmware:
	$(MAKE) -C $@

bootloader_20k:
	$(MAKE) -C $@

bootrom:
	$(MAKE) -C $@

menuconfig:
	kconfig-mconf Kconfig

.PHONY: firmware bootloader_20k bootrom menuconfig