#!/usr/bin/env python3
"""
UART Test Script
Tests UART communication with loopback functionality.
Sends random data and compares received data for integrity.
"""

import serial
import random
import time
import sys

# Configuration constants
SERIAL_PORT = '/dev/ttyACM0'
BAUD_RATE = 115200
NUM_FRAMES = 256
BYTES_PER_FRAME = 1
TIMEOUT = 1.0
SLEEP_INTERVAL = 0.01

def open_serial_port():
    """Open and configure serial port"""
    try:
        port = serial.Serial(
            port=SERIAL_PORT,
            baudrate=BAUD_RATE,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=TIMEOUT
        )
        print(f"Serial port {SERIAL_PORT} opened successfully")
        return port
    except serial.SerialException as e:
        print(f"Error opening serial port {SERIAL_PORT}: {e}")
        print("Please check if the device is connected and the port is correct")
        sys.exit(1)

def send_data(port, data):
    """Send data through serial port"""
    try:
        port.write(data)
        return True
    except serial.SerialException as e:
        print(f"Error sending data: {e}")
        return False

def receive_data(port, size):
    """Receive data from serial port"""
    try:
        if port.in_waiting >= size:
            return port.read(size=size)
        return None
    except serial.SerialException as e:
        print(f"Error receiving data: {e}")
        return None

def wait_for_data(port, size, timeout):
    """Wait for data to be available"""
    start_time = time.time()
    while time.time() - start_time < timeout:
        if port.in_waiting >= size:
            return True
        time.sleep(SLEEP_INTERVAL)
    return False

def main():
    """Main test function"""
    print("Starting UART Loopback Test")
    print(f"Port: {SERIAL_PORT}")
    print(f"Baud rate: {BAUD_RATE}")
    print(f"Number of frames: {NUM_FRAMES}")
    print("-" * 50)
    
    # Open serial port
    com_port = open_serial_port()
    
    # Initialize counters
    tx_count = 0
    rx_count = 0
    
    # Open files for recording data
    try:
        file_rx = open("rx_data.txt", "w")
        file_tx = open("tx_data.txt", "w")
    except IOError as e:
        print(f"Error opening files: {e}")
        com_port.close()
        sys.exit(1)
    
    print("Starting data transmission...")
    
    # Main test loop
    while tx_count < NUM_FRAMES:
        # Check if data is available for reception
        received_data = receive_data(com_port, BYTES_PER_FRAME)
        if received_data:
            data_hex = received_data.hex()
            print(f"rx frame number: {rx_count}")
            print(f"rx data: {data_hex}")
            file_rx.write(data_hex + "\n")
            rx_count += 1
        else:
            # Generate and send random data
            data = bytearray(random.getrandbits(8) for _ in range(BYTES_PER_FRAME))
            
            if send_data(com_port, data):
                print(f"tx frame number: {tx_count}")
                print(f"tx data: {data.hex()}")
                file_tx.write(data.hex() + "\n")
                tx_count += 1
                
                # Wait for data to be received (loopback)
                if not wait_for_data(com_port, BYTES_PER_FRAME, TIMEOUT):
                    print("Warning: data not received within timeout")
    
    # Check for any remaining data in the buffer
    print("Checking for remaining data...")
    while com_port.in_waiting >= BYTES_PER_FRAME:
        received_data = receive_data(com_port, BYTES_PER_FRAME)
        if received_data:
            data_hex = received_data.hex()
            print(f"rx frame number: {rx_count}")
            print(f"rx data: {data_hex}")
            file_rx.write(data_hex + "\n")
            rx_count += 1
    
    # Close files and port
    file_rx.close()
    file_tx.close()
    com_port.close()
    
    print("-" * 50)
    print(f"Transmission completed: {tx_count} frames sent, {rx_count} frames received")
    
    # Compare transmitted and received data
    compare_data_files()

def compare_data_files():
    """Compare transmitted and received data files"""
    print("\nComparing data files...")
    
    file_tx_path = "tx_data.txt"
    file_rx_path = "rx_data.txt"
    
    try:
        # Read data from files
        with open(file_tx_path, "r") as file_tx, open(file_rx_path, "r") as file_rx:
            tx_lines = file_tx.readlines()
            rx_lines = file_rx.readlines()
    except IOError as e:
        print(f"Error reading data files: {e}")
        return
    
    # Compare the number of lines
    if len(tx_lines) != len(rx_lines):
        print("Error: line count differs between files")
        print(f"Line count in tx_data.txt: {len(tx_lines)}")
        print(f"Line count in rx_data.txt: {len(rx_lines)}")
        return
    
    # Compare the content of the lines
    errors_count = 0
    for i in range(len(tx_lines)):
        tx_data = tx_lines[i].strip()
        rx_data = rx_lines[i].strip()
        
        if tx_data != rx_data:
            errors_count += 1
            print(f"Error: line {i+1} does not match:")
            print(f"  tx Data: {tx_data}")
            print(f"  rx Data: {rx_data}")
    
    # Print results
    print("-" * 50)
    if errors_count == 0:
        print("✅ Comparison completed: files are identical")
        print(f"✅ Successfully transmitted and received {len(tx_lines)} frames")
    else:
        print(f"❌ Found {errors_count} discrepancies between files")
        print(f"📊 Success rate: {((len(tx_lines) - errors_count) / len(tx_lines)) * 100:.1f}%")

if __name__ == "__main__":
    main()