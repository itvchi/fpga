BUILDDIR := build
SRCS := $(wildcard src/*.v)
I2C_RW_FS := impl/pnr/i2c_rw.fs
I2C_FIFO_FS := impl/pnr/i2c_fifo.fs

i2c_rw: $(I2C_RW_FS)
i2c_fifo: $(I2C_FIFO_FS)

i2c_rw: $(SRCS)
	@echo "Building i2c_rw bitstream..."
	@echo "open_project ./i2c_rw.gprj\n run all" | gw_sh

i2c_fifo: $(SRCS)
	@echo "Building i2c_fifo bitstream..."
	@echo "open_project ./i2c_fifo.gprj\n run all" | gw_sh

i2c_rw_flash:
	@echo "Flashing i2c_rw bitstream..."
	openFPGALoader -b tangnano20k -f $(I2C_RW_FS)

i2c_fifo_flash:
	@echo "Flashing i2c_fifo bitstream..."
	openFPGALoader -b tangnano20k -f $(I2C_FIFO_FS)