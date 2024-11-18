BUILDDIR:=./build
SRCS:=main.c gpio.c uart.c
OBJS:=$(patsubst %.c, $(BUILDDIR)/%.o, $(SRCS))
OBJS+=$(BUILDDIR)/startup.o

MACH:=cortex-m3
TARGET_FLAGS:=\
	-mcpu=$(MACH)\
	-mthumb\
	-mlittle-endian\
	-mfloat-abi=soft\
	-nostartfiles -nostdlib -static

CFLAGS:=\
	-c -g -Wall -Wextra\
	$(TARGET_FLAGS)\
	-std=gnu11 -O0

LDFLAGS:=\
	$(TARGET_FLAGS)\
	--specs=nosys.specs\
	-Tlinker_script.ld

CC = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy

all: final.elf final.bin

$(BUILDDIR)/startup.o: startup.s | build_dir
	$(CC) $(CFLAGS) -o $@ $<

$(BUILDDIR)/%.o: %.c | build_dir
	$(CC) $(CFLAGS) -o $@ $<

final.elf: $(OBJS) | build_dir 
	$(CC) $(LDFLAGS) -o $(BUILDDIR)/$@ $^

final.bin: final.elf
	$(OBJCOPY) -O binary $(BUILDDIR)/$^ $(BUILDDIR)/$@


build_dir:
	mkdir -p $(BUILDDIR)

clean:
	rm -r $(BUILDDIR)

flash:
	openFPGALoader -b tangnano4k -f ../impl/pnr/cortex_m3_uart.fs --mcufw build/final.bin

.PHONY: build_dir clean flash

















%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

%.d: %.c
	$(CC) -MM $(CPPFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

default: prog.bin

include $(ALL_CSRCS:.c=.d)

