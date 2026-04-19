#!/usr/bin/env python3

import pyftdi
from pyftdi.i2c import I2cController
import random
import time

i2c = I2cController()
i2c.configure('ftdi://ftdi:232h:1/1')

slave = i2c.get_port(0x3C)

passed = True

for i in range(10):
    val = random.randint(0, 255)
    tx = bytearray([val])

    slave.write_to(0x00, tx)
    rx = slave.read_from(0x00, 1)
    time.sleep(0.001)

    if rx != tx:
        print(f"Test FAILED at iter {i}: wrote 0x{val:02X}, read {rx}")
        sys.exit(1)

print("Test PASSED")