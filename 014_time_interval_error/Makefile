FS := impl/pnr/time_interval_error.fs
SRCS := $(wildcard src/*.v)

all: time_interval_error

time_interval_error: $(SRCS)
	@echo "Building time_interval_error bitstream..."
	@echo "open_project ./time_interval_error.gprj\n set_option -top_module top\n run all" | gw_sh

flash: $(FS)
	@echo "Flashing time_interval_error bitstream..."
	openFPGALoader -b tangnano9k -f $(FS)