import serial
import random
import time

# Define number of frames and bytes per frame
num_frames = 256
bytes_per_frame = 1

# Open serial port for data transmission
ComPort = serial.Serial('/dev/ttyUSB0')
ComPort.baudrate = 921600
ComPort.parity = serial.PARITY_EVEN
ComPort.stopbits = serial.STOPBITS_TWO

tx_count = 0
rx_count = 0

# Open files for recording transmitted and received data
file_rx = open("rx_data.txt", "w")
file_tx = open("tx_data.txt", "w")

while tx_count < num_frames:
    if ComPort.in_waiting >= bytes_per_frame:
        # Receive data
        x = ComPort.read(size=bytes_per_frame)
        data_hex = x.hex()
        print("rx frame number:", rx_count)
        print("rx data:", data_hex)
        file_rx.write(data_hex + "\n")
        rx_count += 1
    else:
        # Transmit data
        data = bytearray(random.getrandbits(8) for _ in range(bytes_per_frame))
        ComPort.write(data)
        print("tx frame number:", tx_count)
        print("tx data:", data.hex())
        file_tx.write(data.hex() + "\n")
        tx_count += 1
        
        # Wait for reception of data
        start_time = time.time()
        while time.time() - start_time < 1.0:
            if ComPort.in_waiting >= bytes_per_frame:
                break
            time.sleep(0.01)
        
        if ComPort.in_waiting < bytes_per_frame:
            print("Error: data not received within timeout")

# Check for any remaining data in the buffer after transmission is complete
while ComPort.in_waiting >= bytes_per_frame:
    x = ComPort.read(size=bytes_per_frame)
    data_hex = x.hex()
    print("rx frame number:", rx_count)
    print("rx data:", data_hex)
    file_rx.write(data_hex + "\n")
    rx_count += 1

file_rx.close()
file_tx.close()
ComPort.close()

# Paths to files for comparison
file_tx_path = "tx_data.txt"
file_rx_path = "rx_data.txt"

# Read data from files
with open(file_tx_path, "r") as file_tx, open(file_rx_path, "r") as file_rx:
    tx_lines = file_tx.readlines()
    rx_lines = file_rx.readlines()

# Compare the number of lines in the files
if len(tx_lines) != len(rx_lines):
    print("Error: line count differs between files")
    print(f"Line count in tx_data.txt: {len(tx_lines)}")
    print(f"Line count in rx_data.txt: {len(rx_lines)}")
else:
    # Compare the content of the lines
    errors_count = 0
    for i in range(len(tx_lines)):
        if tx_lines[i].strip() != rx_lines[i].strip():
            errors_count += 1
            print(f"Error: line {i+1} does not match:")
            print(f"  tx Data: {tx_lines[i].strip()}")
            print(f"  rx Data: {rx_lines[i].strip()}")

    if errors_count == 0:
        print("Comparison completed: files are identical")
    else:
        print(f"Found {errors_count} discrepancies between files")