#!/usr/bin/env python3

import pyftdi
from pyftdi.i2c import I2cController
import random
import time

def read_reg(i2c_slave, addr):
    rx = i2c_slave.read_from(addr, 1)
    time.sleep(0.001)
    return rx
    

def read_curr_addr(i2c_slave):
    addr = read_reg(slave, 0x01)
    print(f"Curr addr 0x{addr[0]:02X}")


i2c = I2cController()
i2c.configure('ftdi://ftdi:232h:1/1')

slave = i2c.get_port(0x3C)

slave.write_to(0x00, bytearray([4]))
for i in range(5):
    val = random.randint(0, 255)
    tx = bytearray([val])

    read_curr_addr(slave)
    slave.write_to(0x02, tx)
    time.sleep(0.001)
    print(f"Wrote 0x{val:02X}")

print()
slave.write_to(0x00, bytearray([4]))
for i in range(5):
    read_curr_addr(slave)
    rx = slave.read_from(0x03, 1)
    time.sleep(0.001)
    print(f"Read 0x{rx[0]:02X}")