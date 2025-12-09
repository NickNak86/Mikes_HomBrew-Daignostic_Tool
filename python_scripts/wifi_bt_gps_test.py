#!/usr/bin/env python3
"""
WiFi/BT/GPS Module Testing Script
Tests wireless connectivity and GPS functionality of HomeBrew Gen3 PCB devices
"""

import socket
import subprocess
import json
import sys
import time
import re
from datetime import datetime
import threading
import requests

class WiFiBTGPSTester:
    def __init__(self, host, port=2000):
        """Initialize WiFi/BT/GPS tester"""
        self.host = host
        self.port = port
        self.tn = None
        self.test_results = {}
        
    def connect_telnet(self):
        """Connect to HomeBrew device via telnet"""
        try:
            self.tn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.tn.settimeout(5)
            self.tn.connect((self.host, self.port))
            print(f"✓ Connected to {self.host}:{self.port}")
            return True
        except Exception as e:
            print(f"✗ Connection failed: {e}")
            return False
            
    def send_command(self, command, delay=0.5):
        """Send command via telnet"""
        try:
            self.tn.send(f"{command}\r\n".encode())
            time.sleep(delay)
            response = self.tn.recv(1024).decode().strip()
            return response
        except Exception as e:
            return f"Error: {e}"
            
    def test_wifi_module(self):
        """Test WiFi module functionality"""
        print("\n[WiFi] Testing WiFi module...")
        tests = {}
        
        # Test WiFi status
        print("  Testing WiFi status...")
        status_response = self.send_command("WIFISTATUS")
        tests['wifi_status'] = status_response
        
        # Test WiFi scan for networks
        print("  Testing WiFi network scan...")
        scan_response = self.send_command("WIFISCAN")
        tests['wifi_scan'] = scan_response
        
        # Test WiFi connection to network
        print("  Testing WiFi connection...")
        conn_response = self.send_command("WIFICONNECT")
        tests['wifi_connect'] = conn_response
        
        # Test internet connectivity
        print("  Testing internet connectivity...")
        internet_response = self.send_command("PING 8.8.8.8")
        tests['internet_ping'] = internet_response
        
        # Test local network connectivity
        print("  Testing local network...")
        local_response = self.send_command("PING 192.168.1.1")
        tests['local_ping'] = local_response
        
        return tests
        
    def test_bluetooth_module(self):
        """Test Bluetooth module functionality"""
        print("\n[BT] Testing Bluetooth module...")
        tests = {}
        
        # Test Bluetooth status
        print("  Testing Bluetooth status...")
        status_response = self.send_command("BTSTATUS")
        tests['bt_status'] = status_response
        
        # Test Bluetooth scan for devices
        print("  Testing Bluetooth device scan...")
        scan_response = self.send_command("BTSCAN")
        tests['bt_scan'] = scan_response
        
        # Test Bluetooth pairing
        print("  Testing Bluetooth pairing...")
        pair_response = self.send_command("BTPAIR")
        tests['bt_pair'] = pair_response
        
        return tests
        
    def test_gps_module(self):
        """Test GPS module functionality"""
        print("\n[GPS] Testing GPS module...")
        tests = {}
        
        # Test GPS status
        print("  Testing GPS status...")
        status_response = self.send_command("GPSSTATUS")
        tests['gps_status'] = status_response
        
        # Get GPS coordinates
        print("  Getting GPS coordinates...")
        coords_response = self.send_command("GPSCOORDS")
        tests['gps_coordinates'] = coords_response
        
        # Get satellite info
        print("  Getting satellite information...")
        sat_response = self.send_command("GPSSAT")
        tests['gps_satellites'] = sat_response
        
        # Get time sync info
        print("  Getting time sync information...")
        time_response = self.send_command("GPSTIME")
        tests['gps_time'] = time_response
        
        return tests
        
    def test_usb_relay(self):
        """Test USB relay functionality"""
        print("\n[USB] Testing USB relay...")
        tests = {}
        
        # Test USB status
        print("  Testing USB relay status...")
        status_response = self.send_command("USBSTATUS")
        tests['usb_status'] = status_response
        
        # Test USB relay control
        print("  Testing USB relay control...")
        relay_response = self.send_command("USBRELAY ON")
        tests['usb_relay_on'] = relay_response
        time.sleep(1)
        
        # Test turning relay off
        print("  Testing USB relay off...")
        relay_off_response = self.send_command("USBRELAY OFF")
        tests['usb_relay_off'] = relay_off_response
        
        return tests
        
    def test_device_info(self):
        """Test general device information"""
        print("\n[DEVICE] Testing device information...")
        tests = {}
        
        # Get device version
        print("  Getting device version...")
        version_response = self.send_command("VERSION")
        tests['device_version'] = version_response
        
        # Get uptime
        print("  Getting device uptime...")
        uptime_response = self.send_command("UPTIME")
        tests['device_uptime'] = uptime_response
        
        # Get temperature
        print("  Getting device temperature...")
        temp_response = self.send_command("TEMPERATURE")
        tests['device_temperature'] = temp_response
        
        # Get memory status
        print("  Getting memory status...")
        memory_response = self.send_command("MEMORY")
        tests['memory_status'] = memory_response
        
        return tests
        
    def run_all_tests(self):
        """Run all WiFi/BT/GPS/USB tests"""
        if not self.connect_telnet():
            return None
            
        start_time = datetime.now()
        print(f"Starting comprehensive test at {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Run all test suites
        self.test_results['wifi_tests'] = self.test_wifi_module()
        self.test_results['bluetooth_tests'] = self.test_bluetooth_module()
        self.test_results['gps_tests'] = self.test_gps_module()
        self.test_results['usb_tests'] = self.test_usb_relay()
        self.test_results['device_tests'] = self.test_device_info()
        
        # Calculate test duration
        end_time = datetime.now()
        self.test_results['test_duration'] = str(end_time - start_time)
        self.test_results['test_timestamp'] = start_time.isoformat()
        
        # Close connection
        self.tn.close()
        print(f"\n✓ All tests completed in {self.test_results['test_duration']}")
        
        return self.test_results
        
    def save_results(self, filename=None):
        """Save test results to JSON file"""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"wifi_bt_gps_test_{timestamp}.json"
            
        with open(filename, 'w') as f:
            json.dump(self.test_results, f, indent=2)
        print(f"✓ Results saved to {filename}")
        return filename

def main():
    import argparse
    parser = argparse.ArgumentParser(description='HomeBrew WiFi/BT/GPS Module Tester')
    parser.add_argument('--host', required=True, help='IP address of HomeBrew device')
    parser.add_argument('--port', type=int, default=2000, help='Telnet port (default: 2000)')
    parser.add_argument('--output', help='Output JSON file name')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    tester = WiFiBTGPSTester(args.host, args.port)
    
    print(f"HomeBrew WiFi/BT/GPS Module Tester")
    print(f"===================================")
    print(f"Target: {args.host}:{args.port}")
    
    results = tester.run_all_tests()
    
    if results:
        # Save results
        filename = tester.save_results(args.output)
        
        if args.verbose:
            print("\nDetailed Test Results:")
            print(json.dumps(results, indent=2))
        
        # Generate summary
        print("\n" + "="*50)
        print("TEST SUMMARY")
        print("="*50)
        
        for test_category, tests in results.items():
            if isinstance(tests, dict) and test_category != 'test_duration' and test_category != 'test_timestamp':
                print(f"\n{test_category.upper()}:")
                for test_name, result in tests.items():
                    status = "✓" if result and not str(result).startswith("Error") else "✗"
                    print(f"  {status} {test_name}: {result}")
        
        print(f"\nTotal test duration: {results.get('test_duration', 'Unknown')}")
        print(f"Results saved to: {filename}")
        
        return 0
    else:
        print("Test failed - could not establish connection")
        return 1

if __name__ == '__main__':
    sys.exit(main())