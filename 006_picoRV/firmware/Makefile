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
	--specs=nano.specs\
	-Tlinker_script.ld

include ../.config

SRCS := src/main.c src/irq.c src/leds.c
ifeq ($(CONFIG_FS_MINIMAL),y)
	CFLAGS += -DCONFIG_FS_MINIMAL
endif
ifeq ($(CONFIG_FS_BASE),y)
	SRCS += src/app_base.c
	CFLAGS += -DCONFIG_FS_BASE
endif
ifeq ($(CONFIG_FS_LCD),y)
	SRCS += src/lcd.c src/app_lcd.c
	CFLAGS += -DCONFIG_FS_LCD
endif
ifeq ($(CONFIG_WITH_GPIO),y)
	SRCS += src/gpio.c
	CFLAGS += -DCONFIG_WITH_GPIO
endif
ifeq ($(CONFIG_WITH_SYSTICK),y)
	SRCS += src/systick.c
	CFLAGS += -DCONFIG_WITH_SYSTICK
endif
ifeq ($(CONFIG_WITH_UART),y)
	SRCS += src/uart.c
	CFLAGS += -DCONFIG_WITH_UART
endif
ifeq ($(CONFIG_WITH_SPI),y)
	SRCS += src/spi.c
	CFLAGS += -DCONFIG_WITH_SPI
endif
SRCS += src/app_st7789.c src/st7789_lcd/fonts.c src/st7789_lcd/lcd.c src/st7789_lcd/st7789.c

OBJS:=$(BUILDDIR)/startup.o
OBJS+=$(BUILDDIR)/_irq.o
OBJS+=$(patsubst src/%.c, $(BUILDDIR)/%.o, $(SRCS))
LIBS:=${HOME}/opt/riscv-rv32i/lib/gcc/riscv32-unknown-elf/15.1.0/libgcc.a

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
	@riscv32-unknown-elf-nm -S --size-sort $(BUILDDIR)/final.elf | \
	awk '{ \
	  size = strtonum("0x"$$2); \
	  hum = (size >= 1024) ? sprintf("%.1fK", size/1024) : size "B"; \
	  print size "\t(" hum ")\t" $$3 "\t" $$4 \
	}'

flash: # Changed to custom openFPGALoader which supports user flash for GW1NR-9C
	openFPGALoaderGowin -b tangnano9k -f ../impl/pnr/picoRV.fs --mcufw $(BUILDDIR)/flash.bin