BUILDDIR:=./build
SRCS:=main.c leds.c systick.c irq.c
OBJS:=$(BUILDDIR)/startup.o
OBJS+=$(patsubst %.c, $(BUILDDIR)/%.o, $(SRCS))

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

all: mem.hex

$(BUILDDIR)/startup.o: startup.S | build_dir
	$(CC) $(CFLAGS) -o $@ $<

$(BUILDDIR)/%.o: %.c | build_dir
	$(CC) $(CFLAGS) -o $@ $<

final.elf: $(OBJS) | build_dir 
	$(CC) $(LDFLAGS) -o $(BUILDDIR)/$@ $^

final.bin: final.elf
	$(OBJCOPY) -O binary $(BUILDDIR)/$^ $(BUILDDIR)/$@

mem.hex: final.bin
	od -v -An -t x4 -w4 $(BUILDDIR)/final.bin > ../src/mem.hex	

build_dir:
	mkdir -p $(BUILDDIR)

clean:
	rm -r $(BUILDDIR)

flash:
	openFPGALoader -b tangnano9k -f ../impl/pnr/picoRV.fs