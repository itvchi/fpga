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
	-nostdlib\
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
	-Tlinker_script.ld

SRCS := src/main.c src/leds.c src/uart.c src/gpio.c

OBJS:=$(BUILDDIR)/startup.o
OBJS+=$(patsubst src/%.c, $(BUILDDIR)/%.o, $(SRCS))
LIBS:=${HOME}/opt/riscv-rv32i/lib/gcc/riscv32-unknown-elf/15.1.0/libgcc.a

all: flash.bin mem.hex

$(BUILDDIR)/%.o: %.S | build_dir
	$(CC) $(CFLAGS) -o $@ $<

$(BUILDDIR)/%.o: src/%.c | build_dir
	$(CC) $(CFLAGS) -o $@ $<

final.elf: $(OBJS) | build_dir
	$(CC) $(LDFLAGS) -o $(BUILDDIR)/$@ $^ $(LIBS)

flash.bin: final.elf
	$(OBJCOPY) -O binary $(BUILDDIR)/$^ $(BUILDDIR)/$@

mem.hex: flash.bin
	od -v -An -t x4 -w4 $(BUILDDIR)/flash.bin > $(BUILDDIR)/mem.hex
	cp $(BUILDDIR)/mem.hex ../src

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