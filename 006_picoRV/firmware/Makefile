BUILDDIR:=./build
SRCS:=main.c leds.c systick.c irq.c perf.c uart.c
OBJS:=$(BUILDDIR)/startup.o
OBJS+=$(BUILDDIR)/_irq.o
OBJS+=$(patsubst %.c, $(BUILDDIR)/%.o, $(SRCS))
LIBS:=/usr/lib/gcc/riscv64-unknown-elf/13.2.0/rv32i/ilp32/libgcc.a

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
	-std=gnu11 -O0

LDFLAGS:=\
	$(TARGET_FLAGS)\
	-Tlinker_script.ld

CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy

all: flash.bin

$(BUILDDIR)/%.o: %.S | build_dir
	$(CC) $(CFLAGS) -o $@ $<

$(BUILDDIR)/%.o: %.c | build_dir
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