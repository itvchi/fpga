CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy

BUILDDIR:=./build

MACH:=rv32i2p0
ABI:=ilp32
TARGET_FLAGS:=\
	-mno-save-restore\
	-march=$(MACH)\
	-mabi=$(ABI)\
	-nostartfiles\
	-static\
	-ffunction-sections\
	-fdata-sections

CFLAGS:=\
	-c -Wall -Wextra\
	$(TARGET_FLAGS)\
	-std=gnu11 -O0\
	-Iinc

LDFLAGS:=\
	$(TARGET_FLAGS)\
	-Wl,--gc-sections\
	--specs=nano.specs

include ../.config

SRCS := src/main.c src/leds.c
OBJS := $(BUILDDIR)/startup.o


ifeq ($(CONFIG_WITH_IRQ),y)
	SRCS += src/irq.c
	OBJS += $(BUILDDIR)/_irq.o
	CFLAGS += -DCONFIG_WITH_IRQ
endif
ifeq ($(CONFIG_WITH_GPIO),y)
	SRCS += src/gpio.c
	CFLAGS += -DCONFIG_WITH_GPIO
endif
ifeq ($(CONFIG_WITH_UART),y)
	SRCS += src/uart.c
	CFLAGS += -DCONFIG_WITH_UART
endif
ifeq ($(CONFIG_WITH_SYSTICK),y)
	SRCS += src/systick.c
	CFLAGS += -DCONFIG_WITH_SYSTICK
endif


ifeq ($(CONFIG_FS_LCD),y)
	SRCS += src/lcd.c src/app_lcd.c
	CFLAGS += -DCONFIG_FS_LCD
endif
ifeq ($(CONFIG_WITH_SPI),y)
	SRCS += src/spi.c
	CFLAGS += -DCONFIG_WITH_SPI
endif
ifeq ($(CONFIG_WITH_ST7789),y)
	SRCS += src/app_st7789.c src/st7789_lcd/fonts.c src/st7789_lcd/lcd.c src/st7789_lcd/st7789.c
	CFLAGS += -DCONFIG_WITH_ST7789
endif

# Example configuration
ifeq ($(CONFIG_EXAMPLE_PER_FLASH),y)
	CFLAGS += -DEXAMPLE_PERF_FLASH
else ifeq ($(CONFIG_EXAMPLE_PER_RAM),y)
	CFLAGS += -DEXAMPLE_PERF_RAM
else ifeq ($(CONFIG_EXAMPLE_SYSTICK),y)
	CFLAGS += -DEXAMPLE_SYSTICK
else ifeq ($(CONFIG_EXAMPLE_UART),y)
	CFLAGS += -DEXAMPLE_UART
	LIBS := ${HOME}/opt/riscv-rv32i/lib/gcc/riscv32-unknown-elf/15.1.0/libgcc.a
endif

# Target configuration
ifeq ($(CONFIG_TARGET_TANG_NANO_9K),y)
CFLAGS += -DTARGET_TANG_NANO_9K
LDFLAGS+=-Tlinker_script_9k.ld
else ifeq ($(CONFIG_TARGET_TANG_PRIMER_20K),y)
CFLAGS += -DTARGET_TANG_PRIMER_20K
LDFLAGS+=-Tlinker_script_20k.ld
endif

OBJS+=$(patsubst src/%.c, $(BUILDDIR)/%.o, $(SRCS))

all: flash.bin

$(BUILDDIR)/%.o: %.S | build_dir
	$(CC) $(CFLAGS) -o $@ $<

$(BUILDDIR)/%.o: src/%.c | build_dir
	$(CC) $(CFLAGS) -o $@ $<

final.elf: $(OBJS) | build_dir
	$(CC) $(LDFLAGS) -o $(BUILDDIR)/$@ $^ $(LIBS)

flash.bin: final.elf
	$(OBJCOPY) -O binary $(BUILDDIR)/$^ $(BUILDDIR)/$@

build_dir:
	mkdir -p $(BUILDDIR)

clean:
	rm -r $(BUILDDIR)

size:
	@riscv32-unknown-elf-size $(BUILDDIR)/final.elf
	@echo "\nDetailes:"
	@riscv32-unknown-elf-nm -S --size-sort $(BUILDDIR)/final.elf | \
	awk '{ \
	  size = strtonum("0x"$$2); \
	  hum = (size >= 1024) ? sprintf("%.1fK", size/1024) : size "B"; \
	  print size "\t(" hum ")\t" $$3 "\t" $$4 \
	}'

flash: # Changed to custom openFPGALoader which supports user flash for GW1NR-9C
	openFPGALoaderGowin -b tangnano9k -f ../impl/pnr/picoRV.fs --mcufw $(BUILDDIR)/flash.bin