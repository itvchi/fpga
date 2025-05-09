CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy

BUILDDIR:=./build

MACH:=rv32i2p0
ABI:=ilp32
TARGET_FLAGS:=\
	-mno-save-restore\
	-march=$(MACH)\
	-mabi=$(ABI)\
	-nostartfiles\
	-nostdlib\
	-static\

CFLAGS:=\
	-c -Wall -Wextra\
	$(TARGET_FLAGS)\
	-std=gnu11 -O0\
	-Iinc

LDFLAGS:=\
	$(TARGET_FLAGS)\
	-Tlinker_script.ld

include ../.config

SRCS := src/main.c src/irq.c src/leds.c
ifeq ($(CONFIG_FS_BASE),y)
	SRCS += src/app_base.c
endif
ifeq ($(CONFIG_FS_LCD),y)
	SRCS += src/app_lcd.c
endif
ifeq ($(CONFIG_WITH_SYSTICK),y)
	SRCS += src/systick.c
	CFLAGS += -DCONFIG_WITH_SYSTICK
endif
ifeq ($(CONFIG_WITH_UART),y)
	SRCS += src/uart.c
	CFLAGS += -DCONFIG_WITH_UART
endif
ifeq ($(CONFIG_WITH_LCD),y)
	SRCS += src/lcd.c
	CFLAGS += -DCONFIG_WITH_LCDs
endif

OBJS:=$(BUILDDIR)/startup.o
OBJS+=$(BUILDDIR)/_irq.o
OBJS+=$(patsubst src/%.c, $(BUILDDIR)/%.o, $(SRCS))
LIBS:=/usr/lib/gcc/riscv64-unknown-elf/13.2.0/rv32i/ilp32/libgcc.a


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

flash: # Changed to custom openFPGALoader which supports user flash for GW1NR-9C
	openFPGALoaderGowin -b tangnano9k -f ../impl/pnr/picoRV.fs --mcufw $(BUILDDIR)/flash.bin