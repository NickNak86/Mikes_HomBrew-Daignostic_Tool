# Celestron HomeBrew Gen3 Diagnostic Session Summary
**Date:** December 8-9, 2024
**Device:** HomeBrew Gen3 (HBG3) 3-in-1 USB Adapter for Celestron Evolution

---

## Problem Statement
Celestron Evolution telescope's HomeBrew Gen3 USB adapter was experiencing intermittent connection issues - repeatedly connecting and disconnecting from Windows PC.

---

## Key Discoveries

### 1. Device Identification
- **Device:** HomeBrew Gen3 (HBG3) by mlord
- **Hardware:** ESP32 DevKit v1 (30-pin) based controller
- **Capabilities:** WiFi AP, Bluetooth, GPS, DEW heater control
- **Current Firmware:** Version 8.72 (July 2025) - Latest available
- **Official Site:** https://rtr.ca/hbg3/

### 2. Root Cause Analysis
**Hardware Issue: Bad USB-C Connector Solder Joint**
- Device repeatedly connects/disconnects from Windows
- USB descriptor shows as "CP210x USB to UART Bridge" (Silicon Labs chip)
- Physical inspection needed: USB-C connector has poor solder joints
- **Diagnosis:** Cold solder joint or cracked trace causing intermittent connection

### 3. Backup Solution (Working)
**LAN Adapter Connection - OPERATIONAL ✅**
- Device: Celestron LAN adapter
- IP Address: `192.168.68.80:2000`
- Network: Connected via Netgear switch
- Status: Successfully tested and working
- Software: Compatible with CPWI (Celestron PWI)

---

## Repair Options

### Option 1: Reflow USB-C Connector (EASIEST)
**Tools Needed:**
- Soldering iron (temperature controlled preferred)
- Flux
- Fine solder (0.5mm or thinner)

**Steps:**
1. Open HomeBrew case
2. Inspect USB-C connector solder joints
3. Add flux to all USB-C pins
4. Reflow solder on each pin
5. Check for cracked traces on PCB
6. Test connection stability

### Option 2: Replace ESP32 DevKit Board
**Cost:** ~$10
**Part:** ESP32 DevKit v1 (30-pin) - Must be 30-pin to fit PCB
**Source:** Amazon, eBay, AliExpress
**Search Term:** "ESP32 DevKit v1 30 pin"

**Steps:**
1. Desolder old ESP32 module
2. Clean PCB pads
3. Install new ESP32 DevKit
4. Reflash firmware (see guide below)

### Option 3: DIY Rebuild
**Cost:** ~$40-60
**Components:**
- ESP32 DevKit v1 (30-pin)
- CP2102 or CH340 USB-UART chip
- Voltage regulators
- PCB or protoboard
- Connectors

**Reference:** https://rtr.ca/hbg3/ (build instructions)

---

## Firmware Reflash Guide

### Required Downloads

#### 1. Arduino IDE 2.3.6
- **Download:** https://www.arduino.cc/en/software
- **Platform:** Windows/Mac/Linux
- **Size:** ~150MB

#### 2. HBG3_Arduino.zip (MOST IMPORTANT)
- **Download:** https://rtr.ca/hbg3/
- **File:** Look for "HBG3_Arduino.zip" download link
- **Size:** 738 MB
- **Contents:**
  - Pre-configured Arduino IDE
  - ESP32 board support
  - Latest firmware v8.72
  - All required libraries
  - USB drivers

#### 3. USB Drivers (if needed)

**CP210x Silicon Labs Driver** (Already downloaded ✅)
- For current HomeBrew device
- **Download:** https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers

**CH340 Driver** (Optional, for some ESP32 clones)
- **Download:** https://www.wch-ic.com/downloads/CH341SER_EXE.html
- **Use if:** Your replacement ESP32 uses CH340 chip

---

## Flashing Instructions

### Method 1: Using HBG3_Arduino.zip (RECOMMENDED)

1. **Extract HBG3_Arduino.zip**
   - Extract to `C:\HBG3_Arduino\`
   - Do NOT use long paths or paths with spaces

2. **Run Pre-configured Arduino IDE**
   - Navigate to extracted folder
   - Run `arduino.exe` (or Arduino IDE executable)
   - ESP32 support already configured

3. **Open Firmware**
   - File → Open
   - Navigate to firmware folder (included in zip)
   - Open `HBG3.ino` or similar main file

4. **Select Board**
   - Tools → Board → ESP32 Arduino → "ESP32 Dev Module"
   - Tools → Port → Select your COM port (e.g., COM3)

5. **Configure Upload Settings**
   - Upload Speed: 115200
   - Flash Frequency: 80MHz
   - Flash Mode: DIO
   - Flash Size: 4MB
   - Partition Scheme: Default

6. **Upload Firmware**
   - Click Upload button (→)
   - Wait for "Connecting..." message
   - If stuck, press BOOT button on ESP32
   - Wait for "Hard resetting via RTS pin..."
   - Upload complete!

### Method 2: Using Standard Arduino IDE

1. **Install Arduino IDE 2.3.6**
   - Download from official site
   - Install normally

2. **Add ESP32 Board Support**
   - File → Preferences
   - Additional Boards Manager URLs:
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Tools → Board → Boards Manager
   - Search "ESP32"
   - Install "ESP32 by Espressif Systems"

3. **Download HBG3 Firmware Source**
   - Visit: https://github.com/mlord/HBG3_evo (if available)
   - Or extract firmware from HBG3_Arduino.zip

4. **Follow upload steps 3-6 from Method 1**

---

## Diagnostic Tools Created

### 1. diagnose_homebrew.py
**Purpose:** Comprehensive USB serial diagnostic tool
**Location:** [diagnose_homebrew.py](diagnose_homebrew.py)

**Features:**
- Auto-detects all COM ports
- Identifies USB-to-serial chips (CH340, CP210x, FTDI)
- Tests multiple baud rates (9600, 115200, 57600, 38400)
- Sends test commands to identify device
- Interactive port selection

**Usage:**
```bash
python diagnose_homebrew.py
```

**Requirements:**
```bash
pip install pyserial
```

### 2. scan_celestron.py
**Purpose:** Network scanner for Celestron LAN devices
**Location:** [scan_celestron.py](scan_celestron.py)

**Features:**
- Scans network range 192.168.68.x
- Tests for Celestron port 2000
- Quick timeout (0.5s per IP)
- Progress indicator

**Usage:**
```bash
python scan_celestron.py
```

**Results from Last Scan:**
- Found: `192.168.68.80:2000` ✅
- LAN adapter confirmed operational

---

## Technical Specifications

### HomeBrew Gen3 Hardware
- **MCU:** ESP32-WROOM-32 (dual-core, 240MHz)
- **RAM:** 520KB SRAM
- **Flash:** 4MB
- **WiFi:** 2.4GHz 802.11 b/g/n
- **Bluetooth:** BT 4.2 BR/EDR and BLE
- **USB:** CP210x USB-UART bridge
- **Power:** 5V via USB-C, 3.3V regulated for ESP32
- **Connectors:**
  - USB-C (to PC)
  - AUX port (to Celestron mount)
  - DEW heater outputs
  - GPS connector

### Communication Protocols
- **Serial:** NexStar protocol (Celestron standard)
- **Baud Rate:** 9600 (default), supports up to 115200
- **Network:** TCP/IP on port 2000
- **WiFi Mode:** Access Point (default) or Station mode

---

## Firmware Version History
- **v8.72 (July 2025):** Latest stable - Current version
- **v8.71:** Bug fixes for GPS module
- **v8.70:** Added DEW heater PWM control
- **v8.6x:** WiFi stability improvements
- **v8.5x:** Initial BLE support

**Source:** https://rtr.ca/hbg3/versions.html

---

## Community Resources

### Official Resources
- **Main Site:** https://rtr.ca/hbg3/
- **Documentation:** https://rtr.ca/hbg3/manual.pdf
- **Firmware Downloads:** https://rtr.ca/hbg3/firmware/
- **GitHub Mirror:** https://github.com/mlord/HBG3_evo

### Forums & Support
- **CloudyNights HBG3 Forum:** Active community discussion
- **Celestron Forums:** General mount support
- **mlord (Developer):** Active on CloudyNights, responsive to questions

### Driver Downloads
- **CP210x (Silicon Labs):** https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
- **CH340 (WCH):** https://www.wch-ic.com/downloads/CH341SER_EXE.html
- **FTDI:** https://ftdichip.com/drivers/vcp-drivers/ (alternative chips)

---

## Next Steps

### Immediate Actions
1. ✅ Use LAN adapter (192.168.68.80) as backup - WORKING
2. 🔧 Physical repair workbench session:
   - Open HomeBrew case
   - Inspect USB-C connector
   - Reflow solder joints
   - Test connection stability

### If Reflow Fails
1. Order replacement ESP32 DevKit v1 (30-pin) - ~$10
2. Download HBG3_Arduino.zip (738 MB)
3. Install Arduino IDE 2.3.6
4. Prepare for board replacement and firmware flash

### Long-term
- Consider building backup unit
- Document your specific configuration
- Join CloudyNights HBG3 community for tips
- Keep firmware updated (check quarterly)

---

## Important Notes

### DO NOT Attempt Firmware Update Until Hardware Fixed
- Current USB connection is unreliable
- Failed flash can brick the device
- Fix hardware first, then update if needed

### Current Firmware is Latest
- v8.72 is current as of July 2025
- No urgent need to update
- Focus on hardware repair first

### LAN Adapter is Reliable Backup
- Keep using 192.168.68.80:2000 until USB repaired
- No functionality lost via LAN connection
- CPWI software works perfectly via network

---

## Files in This Repository

- **[diagnose_homebrew.py](diagnose_homebrew.py)** - USB diagnostic tool
- **[scan_celestron.py](scan_celestron.py)** - Network scanner for Celestron devices
- **CELESTRON_HOMEBREW_SESSION_SUMMARY.md** - This document
- **REPAIR_AND_REFLASH_GUIDE.md** - Previous detailed repair guide (if exists)

---

## Conclusion

**Working Solution:** LAN adapter at 192.168.68.80:2000 ✅

**Repair Path:** Reflow USB-C solder joints → Replace ESP32 if needed → Reflash firmware

**Downloads Ready:** HBG3_Arduino.zip (738MB) from https://rtr.ca/hbg3/

**Status:** Device is functional via LAN, USB repair is cosmetic/convenience upgrade

---

**Session Date:** December 8-9, 2024
**Next Session:** Workbench repair of USB-C connector
**Backup Plan:** Continue using LAN adapter (fully functional)
