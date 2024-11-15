import pyftdi
from pyftdi.i2c import I2cController

# Instantiate an I2C controller
i2c = I2cController()

# Configure the first interface (IF/1) of the FTDI device as an I2C master
i2c.configure('ftdi://ftdi:232h:1/1')

# Get a port to an I2C slave device
slave = i2c.get_port(0x3C)

# Write a register to the I2C slave
slave.write_to(0x00, b'\x7F')
slave.write_to(0x01, b'\x3F')
slave.write_to(0x02, b'\x1F')
slave.write_to(0x03, b'\x0F')
slave.write_to(0x04, b'\x07')
slave.write_to(0x05, b'\x03')