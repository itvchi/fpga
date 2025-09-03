#!/bin/python3

import serial
import time
import struct
import os
import sys

# === CRC-32/BZIP2 (no reflection) ===
def crc32_bzip2_noref(data: bytes) -> int:
    poly = 0x04C11DB7
    crc = 0xFFFFFFFF
    for byte in data:
        crc ^= byte << 24
        for _ in range(8):
            if crc & 0x80000000:
                crc = (crc << 1) ^ poly
            else:
                crc <<= 1
            crc &= 0xFFFFFFFF
    return crc ^ 0xFFFFFFFF

# === Configuration ===
PORT = "/dev/ttyUSB1"
BAUDRATE = 115200
TIMEOUT_PER_TRANSACTION = 5.0
CMD_ADDR = 0xAA
CMD_DATA = 0xDD
CMD_START = 0xCC
CHUNK_SIZE = 200
LOAD_ADDRESS = 0x00001000

# === CLI argument for filename ===
if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
    print(f"Usage: {sys.argv[0]} <path/to/flash.bin>")
    sys.exit(1)

FILENAME = os.path.abspath(sys.argv[1])

# === Read binary ===
with open(FILENAME, "rb") as f:
    binary_data = f.read()

chunks = [binary_data[i:i + CHUNK_SIZE] for i in range(0, len(binary_data), CHUNK_SIZE)]
if len(binary_data) % CHUNK_SIZE == 0:
    chunks.append(b"")

# === Serial I/O helpers ===
def wait_for_ack(ser, timeout=TIMEOUT_PER_TRANSACTION):
    start = time.time()
    while time.time() - start < timeout:
        r = ser.read(1)
        if r:
            b = r[0]
            if b == 0xFF:
                return True
            elif b == 0x00:
                print("❌ NACK received")
                return False
            else:
                print(f"❌ Unexpected response byte: 0x{b:02X}")
                return False
    print("❌ Timeout waiting for response")
    return False

def send_command(ser, cmd, data: bytes, label=""):
    if len(data) > 0:
        crc = crc32_bzip2_noref(data)
        crc_bytes = crc.to_bytes(4, byteorder="big")
        packet = bytearray([cmd, len(data)]) + crc_bytes + data
        print(f"→ Sending {label}: CMD=0x{cmd:02X}, LEN={len(data)}, CRC=0x{crc:08X}")
    else:
        packet = bytearray([cmd, 0x00])
        print(f"→ Sending {label}: CMD=0x{cmd:02X}, LEN=0, no CRC")

    ser.write(packet)

    # All commands expect ACK = 0xFF
    if wait_for_ack(ser):
        print(f"✅ {label} acknowledged (0xFF)")
        return True
    else:
        print(f"❌ {label} failed or timed out")
        return False

# === Main Transfer ===
with serial.Serial(PORT, BAUDRATE, timeout=0.1) as ser:
    # Send LOAD ADDRESS
    addr_bytes = struct.pack(">I", LOAD_ADDRESS)
    if not send_command(ser, CMD_ADDR, addr_bytes, "Load Address"):
        exit(1)

    # Send CHUNKS
    for i, chunk in enumerate(chunks):
        label = f"Chunk {i+1}/{len(chunks)}"
        if not send_command(ser, CMD_DATA, chunk, label):
            exit(1)

    # Send START command
    if not send_command(ser, CMD_START, b"", "Start Execution"):
        exit(1)
    print("✅ Boot complete – execution started")
