#!/usr/bin/env python3
"""Quick Celestron device scanner"""
import socket
import sys

def scan_port(ip, port=2000, timeout=0.5):
    """Test if port is open"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        result = s.connect_ex((ip, port))
        s.close()
        return result == 0
    except:
        return False

# Scan your network range
print("Scanning for Celestron devices on port 2000...")
print("Network: 192.168.68.x\n")

found = []
for i in range(1, 255):
    ip = f"192.168.68.{i}"
    if scan_port(ip, 2000):
        print(f"✓ FOUND: {ip}:2000")
        found.append(ip)
    elif i % 20 == 0:
        sys.stdout.write('.')
        sys.stdout.flush()

print("\n\nResults:")
if found:
    print(f"Found {len(found)} device(s) with port 2000 open:")
    for ip in found:
        print(f"  - {ip}:2000")
else:
    print("No devices found with port 2000 open.")
    print("\nTroubleshooting:")
    print("1. Check if Celestron LAN adapter is powered on")
    print("2. Verify LAN cable is connected to Netgear switch")
    print("3. Check if device has link lights")
    print("4. Try connecting via CPWI to see if it auto-detects")
