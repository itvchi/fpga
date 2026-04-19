BUILDDIR := build
SRCS := $(wildcard src/*.v)
FS := impl/pnr/i2c_rw.fs

i2c_rw: $(FS)

$(FS): $(SRCS)
	@echo "Building i2c_rw bitstream..."
	@echo "open_project ./i2c_rw.gprj\n run all" | gw_sh

flash: $(FS)
	@echo "Flashing i2c_rw bitstream..."
	openFPGALoader -b tangnano20k -f $(FS)