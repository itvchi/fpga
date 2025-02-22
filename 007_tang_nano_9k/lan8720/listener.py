import socket

ETH_P_ALL=3
s=socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(ETH_P_ALL))
s.bind(("enp4s0", 0))

while True:
    received = s.recv(2000)
    if (received):
        dest_mac = received[0:6]
        src_mac = received[6:12]        
        length = int.from_bytes(received[12:14])
        payload = received[14:14+length]
        print("Received {0} bytes from {1} ->".format(length, (":".join(f"{byte:02X}" for byte in src_mac))), end=" ")
        print(" ".join(f"0x{byte:02X}" for byte in payload))
