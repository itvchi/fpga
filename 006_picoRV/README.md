For maintain purpose (much longer synthesis time for all modules included), 
the top module was splitted into versions which contains picoRV cpu with base modules
like sram, flash or reset controller, then other additional modules depending on version.

Versions:
- MINIMAL (picoRV core with memory mapped leds module)
- BASE (as minimal + sytick and uart)
- LCD (as base + rgb interface lcd driver)

If serial_flash.py does not working with Sipeed RV-debugger Plus exec "sudo modprobe ftdi_sio"