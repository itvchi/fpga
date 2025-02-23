import socket

ETH_P_ALL=3
s=socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(ETH_P_ALL))
s.bind(("enp4s0", 0))

def send_raw_packet(dest_mac: bytes, src_mac: bytes, length: bytes, payload: bytes):
    packet = dest_mac + src_mac + length + payload
    s.send(packet)

while True:
    received = s.recv(2000)
    if received:
        dest_mac = received[0:6]
        src_mac = received[6:12]
        length = received[12:14]
        payload_length = int.from_bytes(received[12:14], 'big')
        payload = received[14:14+payload_length]
        
        print("Received {} bytes from {} ->".format(payload_length, ":".join(f"{byte:02X}" for byte in src_mac)), end=" ")
        print(" ".join(f"0x{byte:02X}" for byte in payload))
        
        # Payload word was send in little endian format
        if (int.from_bytes(payload[0:payload_length+1], 'little') > 0x20):
            print("Sending response")
            payload = bytes(0x00) + payload[1:]
            send_raw_packet(src_mac, dest_mac, length, payload)