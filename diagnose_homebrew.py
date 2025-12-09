#!/usr/bin/env python3
"""
HomeBrew 3-in-1 USB Diagnostic Tool
Detects COM port and attempts serial communication
"""

import serial
import serial.tools.list_ports
import time
import sys

def list_com_ports():
    """List all available COM ports"""
    ports = serial.tools.list_ports.comports()
    print("\n=== Available COM Ports ===")
    if not ports:
        print("No COM ports found!")
        return None

    for i, port in enumerate(ports):
        print(f"{i+1}. {port.device}")
        print(f"   Description: {port.description}")
        print(f"   Hardware ID: {port.hwid}")
        print(f"   Manufacturer: {port.manufacturer}")
        print()

    return ports

def detect_homebrew_port(ports):
    """Try to identify HomeBrew device"""
    print("=== Looking for HomeBrew Device ===")

    # Common USB-to-serial chips
    keywords = ['CH340', 'CP210', 'FTDI', 'USB-SERIAL', 'ESP32', 'Arduino']

    for port in ports:
        for keyword in keywords:
            if keyword.lower() in port.description.lower() or keyword.lower() in str(port.hwid).lower():
                print(f"POSSIBLE HOMEBREW: {port.device} ({keyword} detected)")
                return port.device

    print("No obvious HomeBrew device found")
    return None

def test_serial_connection(port, baudrates=[9600, 115200, 57600, 38400]):
    """Test serial connection at various baud rates"""
    print(f"\n=== Testing {port} ===")

    for baud in baudrates:
        print(f"\nTrying {baud} baud...")
        try:
            ser = serial.Serial(port, baud, timeout=2)
            print(f"✓ Port opened at {baud} baud")

            # Try to read any data
            time.sleep(0.5)
            if ser.in_waiting > 0:
                data = ser.read(ser.in_waiting)
                print(f"  Received data: {data}")

            # Try common test commands
            test_commands = [
                b"VERSION\r\n",
                b"AT\r\n",
                b"?\r\n",
                b"HELP\r\n",
                b"\r\n"
            ]

            for cmd in test_commands:
                ser.write(cmd)
                time.sleep(0.3)
                if ser.in_waiting > 0:
                    response = ser.read(ser.in_waiting)
                    print(f"  Command {cmd.strip()}: {response}")
                    if len(response) > 0:
                        print(f"  ✓ DEVICE RESPONDING!")
                        break

            ser.close()

        except serial.SerialException as e:
            print(f"  ✗ Failed: {e}")
        except Exception as e:
            print(f"  ✗ Error: {e}")

def main():
    print("=" * 50)
    print("HomeBrew 3-in-1 USB Diagnostic Tool")
    print("=" * 50)

    # List all ports
    ports = list_com_ports()
    if not ports:
        print("\n⚠️  No COM ports detected!")
        print("   Make sure the HomeBrew device is plugged in")
        print("   You may need to install USB drivers (CH340, CP2102, etc.)")
        input("\nPress Enter to exit...")
        return

    # Try to auto-detect
    homebrew_port = detect_homebrew_port(ports)

    # Ask user which port to test
    print("\n=== Select Port to Test ===")
    if homebrew_port:
        print(f"Auto-detected: {homebrew_port}")
        choice = input(f"Test {homebrew_port}? (y/n or enter port#): ").strip().lower()

        if choice == 'y' or choice == '':
            test_port = homebrew_port
        elif choice.isdigit() and 1 <= int(choice) <= len(ports):
            test_port = ports[int(choice)-1].device
        else:
            test_port = choice.upper()
    else:
        choice = input("Enter port number to test (or full port name like COM3): ").strip()
        if choice.isdigit():
            test_port = ports[int(choice)-1].device
        else:
            test_port = choice.upper()

    # Test the selected port
    test_serial_connection(test_port)

    print("\n" + "=" * 50)
    print("Diagnostic Complete!")
    print("=" * 50)

    input("\nPress Enter to exit...")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nDiagnostic cancelled by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n\n⚠️  Unexpected error: {e}")
        input("\nPress Enter to exit...")
        sys.exit(1)
