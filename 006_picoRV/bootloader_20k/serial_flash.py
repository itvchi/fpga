import serial
import time
import struct
from functools import reduce

# === Configuration ===
PORT = "/dev/ttyUSB1"
BAUDRATE = 115200
TIMEOUT_PER_TRANSACTION = 5.0
CMD_ADDR = 0xAA
CMD_DATA = 0xDD
CHUNK_SIZE = 255
FILENAME = "flash.bin"
LOAD_ADDRESS = 0x08001234  # MSB first

# === Load binary ===
with open(FILENAME, "rb") as f:
    binary_data = f.read()

chunks = [binary_data[i:i + CHUNK_SIZE] for i in range(0, len(binary_data), CHUNK_SIZE)]
if len(binary_data) % CHUNK_SIZE == 0:
    chunks.append(b"")

def wait_for_bytes(ser, expected_list, timeout=TIMEOUT_PER_TRANSACTION):
    """Waits sequentially for a list of expected byte values, while sending 0x00."""
    start = time.time()
    index = 0

    while time.time() - start < timeout:
        ser.write(b'\x00')  # Send a dummy byte to stimulate response
        r = ser.read(1)
        if r:
            received = r[0]
            expected = expected_list[index]
            if received == expected:
                index += 1
                if index == len(expected_list):
                    return True, received
            else:
                print(f"❌ Unexpected byte: got 0x{received:02X}, expected 0x{expected:02X}")
                return False, received
    return False, None

def calc_expected_response(data: bytes):
    return reduce(lambda a, b: a ^ b, data, 0x00)

def send_command(ser, cmd, data: bytes, label=""):
    packet = bytearray([cmd, len(data)]) + data
    print(f"→ {label} CMD 0x{cmd:02X}, {len(data)} bytes")

    ser.write(packet)
    expected_xor = calc_expected_response(data)

    # Wait for [XOR, 0xFF]
    ok, received = wait_for_bytes(ser, [expected_xor, 0xFF])

    if not ok:
        if received is None:
            print(f"❌ Timeout waiting for response ({label})")
        else:
            print(f"❌ Invalid response byte 0x{received:02X} ({label})")
        return False
    else:
        print(f"✅ Response OK + Ready (XOR=0x{expected_xor:02X}, 0xFF) → {label}")
        return True

# === Main Transfer ===
with serial.Serial(PORT, BAUDRATE, timeout=0.1) as ser:
    # Send LOAD ADDRESS
    addr_bytes = struct.pack(">I", LOAD_ADDRESS)
    if not send_command(ser, CMD_ADDR, addr_bytes, "Load Address"):
        exit(1)

    # Send DATA chunks
    for i, chunk in enumerate(chunks):
        label = f"Chunk {i+1}/{len(chunks)}"
        if not send_command(ser, CMD_DATA, chunk, label):
            break
    else:
        print("✅ All data sent and acknowledged")
