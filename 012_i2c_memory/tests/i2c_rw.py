#!/usr/bin/env python3

import pyftdi
from pyftdi.i2c import I2cController
import random
import time

i2c = I2cController()
i2c.configure('ftdi://ftdi:232h:1/1')

slave = i2c.get_port(0x3C)

counter = slave.read_from(0x01, 1)

for i in range(10):
    val = random.randint(0, 255)
    tx = bytearray([val])

    slave.write_to(0x00, tx)
    rx = slave.read_from(0x00, 1)
    time.sleep(0.001)

    if rx != tx:
        print(f"Test FAILED at iter {i}: wrote 0x{val:02X}, read 0x{rx[0]:02X}")
        sys.exit(1)

counter_end = slave.read_from(0x01, 1)
counter[0] += 10

if (counter_end != counter):
    print(f"Test FAILED: counter is 0x{counter_end[0]:02X} and should be 0x{counter[0]:02X}")
else:
    print("Test PASSED")