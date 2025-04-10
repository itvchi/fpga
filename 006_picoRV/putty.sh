#!/bin/bash

# Exec "sudo modprobe ftdi_sio" if BL702 is not binded to /dev/ttyUSB*
GDK_BACKEND=x11 putty -serial /dev/ttyUSB1 -sercfg 115200,8,n,1,n