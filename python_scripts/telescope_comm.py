#!/usr/bin/env python3
"""
Celestron Evolution Mount Communication Script
Handles telnet and serial communication with HomeBrew Gen3 PCB devices
"""

import telnetlib
import serial
import serial.tools.list_ports
import time
import sys
import json
import argparse
from datetime import datetime

class CelestronMount:
    def __init__(self, host=None, port=2000, timeout=5):
        """Initialize Celestron mount communication"""
        self.host = host
        self.port = port
        self.timeout = timeout
        self.tn = None
        self.serial = None
        self.connected = False
        
    def connect_telnet(self):
        """Connect via telnet to HomeBrew device"""
        try:
            print(f"Connecting to {self.host}:{self.port} via telnet...")
            self.tn = telnetlib.Telnet(self.host, self.port, self.timeout)
            self.connected = True
            print("✓ Telnet connection successful")
            return True
        except Exception as e:
            print(f"✗ Telnet connection failed: {e}")
            return False
            
    def connect_serial(self, port=None, baudrate=9600):
        """Connect via serial port"""
        try:
            if port is None:
                # Auto-detect serial ports
                ports = serial.tools.list_ports.comports()
                print("Available serial ports:")
                for p in ports:
                    print(f"  {p.device}: {p.description}")
                port = ports[0].device if ports else None
                
            if port:
                print(f"Connecting to {port} at {baudrate} baud...")
                self.serial = serial.Serial(port, baudrate, timeout=self.timeout)
                self.connected = True
                print("✓ Serial connection successful")
                return True
            else:
                print("✗ No serial port found")
                return False
        except Exception as e:
            print(f"✗ Serial connection failed: {e}")
            return False
            
    def send_command(self, command):
        """Send command to mount and get response"""
        if not self.connected:
            return None
            
        try:
            if self.tn:
                # Send telnet command
                self.tn.write(f"{command}\r\n".encode('ascii'))
                time.sleep(0.5)
                response = self.tn.read_some().decode('ascii').strip()
                return response
            elif self.serial:
                # Send serial command
                self.serial.write(f"{command}\r\n".encode('ascii'))
                time.sleep(0.5)
                response = self.serial.readline().decode('ascii').strip()
                return response
        except Exception as e:
            print(f"Command failed: {e}")
            return None
            
    def get_mount_info(self):
        """Get basic mount information"""
        commands = [
            "MS",  # Mount Status
            "GV",  # Get Version
            "GA",  # Get Altitude
            "GZ"   # Get Azimuth
        ]
        
        results = {}
        for cmd in commands:
            response = self.send_command(cmd)
            if response:
                results[cmd] = response
            time.sleep(0.2)
            
        return results
        
    def test_connection(self):
        """Test basic connection with echo"""
        response = self.send_command("echo test")
        return response is not None
        
    def disconnect(self):
        """Disconnect from mount"""
        if self.tn:
            self.tn.close()
        if self.serial:
            self.serial.close()
        self.connected = False
        print("✓ Disconnected")

def main():
    parser = argparse.ArgumentParser(description='Celestron Evolution Mount Communication')
    parser.add_argument('--host', help='IP address of HomeBrew device')
    parser.add_argument('--port', type=int, default=2000, help='Telnet port (default: 2000)')
    parser.add_argument('--serial', help='Serial port (auto-detect if not specified)')
    parser.add_argument('--baudrate', type=int, default=9600, help='Serial baudrate (default: 9600)')
    parser.add_argument('--test', action='store_true', help='Run connection tests only')
    parser.add_argument('--json', action='store_true', help='Output in JSON format')
    
    args = parser.parse_args()
    
    mount = CelestronMount(args.host, args.port)
    
    # Try connection methods
    connected = False
    
    if args.host:
        connected = mount.connect_telnet()
    elif args.serial:
        connected = mount.connect_serial(args.serial, args.baudrate)
    else:
        # Try serial auto-detect first, then telnet default
        print("No specific connection method specified. Trying serial auto-detect...")
        connected = mount.connect_serial()
        if not connected and not args.serial:
            # Try default telnet connection
            print("Trying default telnet connection...")
            connected = mount.connect_telnet()
    
    if connected:
        if args.test:
            # Run basic tests
            print("\nRunning connection tests...")
            test_results = {
                'connection_test': mount.test_connection(),
                'mount_info': mount.get_mount_info(),
                'timestamp': datetime.now().isoformat()
            }
        else:
            # Get full mount information
            test_results = {
                'connection_test': mount.test_connection(),
                'mount_info': mount.get_mount_info(),
                'timestamp': datetime.now().isoformat()
            }
            
        if args.json:
            print(json.dumps(test_results, indent=2))
        else:
            print("\nMount Information:")
            for cmd, response in test_results.get('mount_info', {}).items():
                print(f"  {cmd}: {response}")
                
        mount.disconnect()
        return 0
    else:
        print("Failed to establish connection")
        return 1

if __name__ == '__main__':
    sys.exit(main())