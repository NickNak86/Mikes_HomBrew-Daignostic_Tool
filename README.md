# HomeBrew Gen3 PCB WiFi/BT/GPS/MUSBA Relay Diagnostic Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/NickNak86/HomeBrew-Telescope-Diagnostic-Tool/blob/main/LICENSE) [![Platform: Windows](https://img.shields.io/badge/platform-Windows-blue?logo=windows)](https://github.com/NickNak86/HomeBrew-Telescope-Diagnostic-Tool) [![Language: PowerShell](https://img.shields.io/badge/language-PowerShell-179CF0?logo=powershell&logoColor=FFFFFF)](https://github.com/NickNak86/HomeBrew-Telescope-Diagnostic-Tool) [![Python](https://img.shields.io/badge/language-Python-3776AB?logo=python&logoColor=FFFFFF)](https://github.com/NickNak86/HomeBrew-Telescope-Diagnostic-Tool)

A comprehensive diagnostic and troubleshooting tool for **HomeBrew Gen3 PCB WiFi/BT/GPS/MUSBA relay devices** used with **Celestron Evolution mounts**.

## 🌟 Features

- **Telescope Communication** - Test telnet and serial protocols with Celestron Evolution mounts
- **WiFi/BT/GPS Testing** - Comprehensive testing of wireless modules
- **Network Diagnostics** - Verify connectivity to HomeBrew devices
- **System Requirements** - Check Python installation and system compatibility
- **Automated Reporting** - Generate detailed HTML reports with troubleshooting guides
- **Multi-Module Support** - Run individual diagnostic modules or full suites

## 🚀 Quick Start

```powershell
# Clone the repository
git clone https://github.com/NickNak86/HomeBrew-Telescope-Diagnostic-Tool.git
cd HomeBrew-Telescope-Diagnostic-Tool

# Run full telescope diagnostics
.\Run-Diagnostics.ps1

# Test specific device
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100

# Test with serial connection
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -SerialPort COM3
```

## 📋 Project Structure

```
HomeBrew-Telescope-Diagnostic-Tool/
├── src/diagnostics/         # PowerShell diagnostic modules
│   ├── Telescope-Diagnostics.ps1    # Main telescope communication tests
│   ├── Network-Diagnostics.ps1      # Network connectivity tests
│   ├── Communication-Diagnostics.ps1 # Protocol testing
│   └── System-Diagnostics.ps1       # System requirements
├── python_scripts/          # Python scripts for telescope communication
│   ├── telescope_comm.py            # Celestron mount communication
│   └── wifi_bt_gps_test.py          # WiFi/BT/GPS module testing
├── config/                  # Configuration files
├── docs/                    # Documentation
└── output/                  # Diagnostic reports and logs
```

## 🔧 Requirements

- **Windows 10/11** with PowerShell 5.1 or later
- **Python 3.6+** ([Install from python.org](https://python.org))
- **Network access** to HomeBrew devices
- **Administrator privileges** (recommended for network diagnostics)

## 🛠️ Installation

### 1. Install Python
```powershell
# Download and install Python from https://python.org
# Make sure to check "Add Python to PATH" during installation
```

### 2. Verify Installation
```powershell
# Test Python installation
python --version

# Test PowerShell
$PSVersionTable.PSVersion
```

### 3. Run Initial Diagnostics
```powershell
# Run with default settings (device at 192.168.1.100:2000)
.\Run-Diagnostics.ps1

# Or specify your device IP
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.150
```

## 📡 Usage

### Basic Diagnostics

```powershell
# Run all diagnostic modules
.\Run-Diagnostics.ps1

# Test telescope communication only
.\Run-Diagnostics.ps1 -Module Telescope -DeviceIP 192.168.1.100

# Test network connectivity only
.\Run-Diagnostics.ps1 -Module Network -DeviceIP 192.168.1.100

# Test with both telnet and serial connection
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -SerialPort COM3

# Generate report from existing data
.\Run-Diagnostics.ps1 -ReportOnly
```

### Available Modules

- **Telescope** - Telescope communication, WiFi/BT/GPS testing, Python scripts
- **Network** - Device connectivity, port testing, WiFi analysis  
- **Communication** - Telnet protocols, serial communication, Celestron commands
- **System** - Python installation, system requirements, compatibility checks

### Output Formats

```powershell
# HTML report (default)
.\Run-Diagnostics.ps1 -OutputFormat HTML

# JSON report for automation
.\Run-Diagnostics.ps1 -OutputFormat JSON

# All formats
.\Run-Diagnostics.ps1 -OutputFormat All
```

## 📊 Output

Diagnostic reports are saved to the `output/` directory:

```
output/
├── reports/
│   ├── telescope_diagnostic_2025-12-09_143022.html  # Main report
│   ├── telescope_diagnostic_2025-12-09_143022.json  # Detailed data
│   └── telescope_diagnostic_2025-12-09_143022.txt   # Text summary
└── logs/
    ├── telescope_diagnostics.log
    ├── network_diagnostics.log
    └── communication_diagnostics.log
```

## 🔌 Device Configuration

### HomeBrew Device Setup
1. **Network Connection**: Connect HomeBrew device to same network as your computer
2. **IP Address**: Default is 192.168.1.100 (configurable)
3. **Telnet Port**: Default is 2000 (configurable)
4. **Serial Port**: Optional direct connection to Celestron mount

### Celestron Mount Connection
- **Serial Cable**: USB-to-serial or direct serial connection
- **Baud Rate**: 9600 (standard for Celestron Evolution)
- **Protocol**: Celestron NexStar-compatible commands

## 🛠️ Configuration

Edit `config/diagnostics.yaml` to customize:

```yaml
diagnostics:
  device:
    ip: "192.168.1.100"        # Your device IP
    telnet_port: 2000          # Telnet port
    serial_port: "COM3"        # Serial port (optional)

modules:
  telescope:
    python_path: "python"      # Python executable path
```

## 🔍 Troubleshooting

### Common Issues

**Device Not Found**
```powershell
# Test network connectivity
ping 192.168.1.100

# Test telnet port
telnet 192.168.1.100 2000
```

**Python Scripts Not Working**
```powershell
# Install Python packages
pip install serial telnetlib

# Or run in Python 3
py telescope_comm.py --help
```

**Serial Communication Fails**
```powershell
# List available ports
python -c "import serial; print([p.device for p in serial.tools.list_ports.comports()])"
```

### Diagnostic Steps

1. **System Check**: Verify Python and network tools
2. **Network Check**: Test connectivity to HomeBrew device
3. **Communication Check**: Test telnet and serial protocols
4. **Telescope Check**: Test mount communication and WiFi/BT/GPS modules

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-diagnostic`)
3. Commit your changes (`git commit -m 'Add telescope diagnostic feature'`)
4. Push to the branch (`git push origin feature/new-diagnostic`)
5. Create a Pull Request

## 📚 Documentation

- **[Getting Started Guide](docs/GETTING_STARTED.md)** - Detailed setup instructions
- **[Configuration Guide](docs/CONFIGURATION.md)** - Advanced configuration options
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 📷 Hardware Support

### Supported Devices
- **HomeBrew Gen3 PCB** WiFi/BT/GPS/MUSBA relay devices
- **Celestron Evolution** telescope mounts
- **Celestron NexStar** compatible mounts

### Tested Configurations
- HomeBrew devices with firmware v2.x+
- Windows 10/11 with PowerShell 5.1+
- Python 3.6+ with serial/telnet libraries

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Authors

**NickNak86** - Initial development for HomeBrew telescope integration

## 🙏 Acknowledgments

- **Mike Monson** - Original HomeBrew device design
- **Cloudy Nights Community** - Telescope community support
- **Celestron** - NexStar protocol documentation

## 🌌 Support

For issues, questions, or telescope setup help:

- **[GitHub Issues](https://github.com/NickNak86/HomeBrew-Telescope-Diagnostic-Tool/issues)** - Report bugs and feature requests
- **[Cloudy Nights Forum](https://www.cloudynights.com/forums/)** - Community support and discussion

---

**🌟 Ready to explore the cosmos with your HomeBrew telescope setup! 🌟**
