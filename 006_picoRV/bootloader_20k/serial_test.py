import serial
import time

# === Configuration ===
PORT = "/dev/ttyUSB1"     # Adjust as needed
BAUDRATE = 115200
COMMAND = 0xA5
TIMEOUT = 1.0  # Overall timeout in seconds

# === Manually set payload ===
data_payload = bytearray([0x12, 0x34, 0x56, 0x78, 0x9A])
LENGTH = len(data_payload)
tx_bytes = bytearray([COMMAND, LENGTH]) + data_payload

# === Calculate expected response (XOR of data_payload) ===
expected_response = 0x00
for byte in data_payload:
    expected_response ^= byte

# === Open and use serial port ===
with serial.Serial(PORT, BAUDRATE, timeout=0.1) as ser:
    print(f"Sending: {[hex(b) for b in tx_bytes]}")
    ser.write(tx_bytes)

    # Wait and clock the slave with 0x00 until it replies
    start_time = time.time()
    received = None

    while (time.time() - start_time) < TIMEOUT:
        ser.write(b'\x00')  # Send one 0x00 byte
        response = ser.read(1)

        if response:
            received = response[0]
            break

    if received is not None:
        print(f"Received: 0x{received:02X}")
        if received == expected_response:
            print("✅ Valid response")
        else:
            print("❌ Invalid response")
    else:
        print("❌ No response received (timeout)")
