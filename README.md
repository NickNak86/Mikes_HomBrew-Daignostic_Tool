# Mike's HomeBrew Diagnostic Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/NickNak86/Mikes_HomBrew-Daignostic_Tool/blob/main/LICENSE) [![Platform: Windows](https://img.shields.io/badge/platform-Windows-blue?logo=windows)](https://github.com/NickNak86/Mikes_HomBrew-Daignostic_Tool) [![Language: PowerShell](https://img.shields.io/badge/language-PowerShell-179CF0?logo=powershell&logoColor=FFFFFF)](https://github.com/NickNak86/Mikes_HomBrew-Daignostic_Tool)

A comprehensive diagnostic tool for Windows system analysis, troubleshooting, and health monitoring.

## Features

- System health diagnostics
- Hardware monitoring
- Network diagnostics
- Performance analysis
- Automated reporting
- PowerShell-based for maximum compatibility

## Quick Start

```powershell
# Clone the repository
git clone https://github.com/NickNak86/Mikes_HomBrew-Daignostic_Tool.git
cd Mikes_HomBrew-Daignostic_Tool

# Run diagnostics
.\Run-Diagnostics.ps1
```

## Project Structure

```
Mikes_HomBrew-Daignostic_Tool/
├── src/                    # Source code
│   ├── diagnostics/        # Diagnostic modules
│   ├── collectors/         # Data collectors
│   └── reporters/          # Report generators
├── config/                 # Configuration files
├── docs/                   # Documentation
├── tests/                  # Test files
└── output/                 # Diagnostic reports
```

## Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges (for some diagnostics)

## Usage

### Basic Diagnostics

```powershell
# Run full system diagnostic
.\Run-Diagnostics.ps1

# Run specific diagnostic module
.\Run-Diagnostics.ps1 -Module Hardware

# Generate report only
.\Run-Diagnostics.ps1 -ReportOnly
```

### Available Modules

- **System** - OS info, uptime, updates
- **Hardware** - CPU, RAM, disk, GPU
- **Network** - Connectivity, adapters, DNS
- **Performance** - CPU/RAM usage, processes
- **Services** - Windows services status
- **Security** - Firewall, antivirus, updates

## Configuration

Edit `config/diagnostics.yaml` to customize:

```yaml
diagnostics:
  enabled_modules:
    - system
    - hardware
    - network
  output_format: html  # or json, text
  report_path: output/reports
```

## Output

Diagnostic reports are saved to the `output/` directory with timestamps:

```
output/
├── reports/
│   ├── diagnostic_2025-12-08_182045.html
│   └── diagnostic_2025-12-08_182045.json
└── logs/
    └── diagnostic_2025-12-08.log
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-diagnostic`)
3. Commit your changes (`git commit -m 'Add new diagnostic module'`)
4. Push to the branch (`git push origin feature/new-diagnostic`)
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**NickNak86**

## Support

For issues, questions, or suggestions, please [open an issue](https://github.com/NickNak86/Mikes_HomBrew-Daignostic_Tool/issues).

---

**Built with PowerShell for the Windows ecosystem**
