BUILDDIR := build
SRCS := $(wildcard src/*.v)
FS := impl/pnr/tang_nano_9k.fs

uart: $(FS)
uart_tb: $(BUILDDIR)/uart_tb.vvp
uart_tx_tb: $(BUILDDIR)/uart_tx_tb.vvp

$(FS): $(SRCS)
	@echo "Building uart bitstream..."
	@echo "open_project ./tang_nano_9k.gprj\n run all" | gw_sh

$(BUILDDIR)/uart_tb.vvp: $(SRCS) | build_dir
	@echo "Creating uart_tb simulation..."
	cd src && iverilog -o ../$@.vvp uart_tb.v
	cd $(BUILDDIR) && vvp uart_tb.vvp

$(BUILDDIR)/uart_tx_tb.vvp: $(SRCS) | build_dir
	@echo "Creating uart_tx_tb simulation..."
	cd src && iverilog -o ../$@.vvp uart_tx_tb.v
	cd $(BUILDDIR) && vvp uart_tx_tb.vvp

uart_flash: $(FS)
	@echo "Flashing uart bitstream..."
	openFPGALoader -b tangnano9k -f $(FS)

build_dir:
	mkdir -p $(BUILDDIR)