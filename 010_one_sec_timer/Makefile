FS := impl/pnr/tang_nano_9k.fs
SRCS := $(wildcard src/*.v)

all: one_sec_timer

one_sec_timer: $(SRCS)
	@echo "Building one_sec_timer bitstream..."
	@echo "open_project ./tang_nano_9k.gprj\n set_option -top_module top\n run all" | gw_sh

flash: $(FS)
	@echo "Flashing one_sec_timer bitstream..."
	openFPGALoader -b tangnano9k -f $(FS)

build_dir:
	mkdir -p $(BUILDDIR)