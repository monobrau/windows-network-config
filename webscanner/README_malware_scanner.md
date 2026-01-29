# Polyfill.io Scanner

A specialized Python tool for scanning websites specifically for polyfill.io references. Detects compromised polyfill.io CDN usage that could expose websites to malware.

## Features

- **Polyfill.io Detection**: Specifically scans for references to the compromised polyfill.io CDN
- **Comprehensive Link Crawling**: Automatically discovers and scans all links, scripts, and resources
- **Focused Detection**: Only looks for polyfill.io references - no false positives from other content
- **Configurable Scanning**: Adjustable crawl depth, worker threads, and request delays
- **Detailed Reporting**: Generates comprehensive reports in text and JSON formats
- **Respectful Crawling**: Follows robots.txt and includes rate limiting

## Installation

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

## Usage

### Basic Usage
```bash
python malware_scanner.py https://example.com
```

### Advanced Usage
```bash
# Scan with custom depth and workers
python malware_scanner.py https://example.com --depth 3 --workers 10

# Bypass robots.txt restrictions (use with caution)
python malware_scanner.py https://example.com --bypass-robots

# Generate report files
python malware_scanner.py https://example.com --output scan_report.txt --json results.json

# Verbose output
python malware_scanner.py https://example.com --verbose
```

### Command Line Options

- `url`: URL to scan (required)
- `--depth`: Maximum crawl depth (default: 2)
- `--workers`: Number of worker threads (default: 5)
- `--delay`: Delay between requests in seconds (default: 1.0)
- `--bypass-robots`: Bypass robots.txt restrictions (use with caution)
- `--output`: Output file for text report
- `--json`: Export results to JSON file
- `--verbose`: Enable verbose logging

## Detection

The scanner detects polyfill.io references:

### High Severity
- **Polyfill.io References**: Detects any references to the compromised polyfill.io CDN
  - `polyfill.io` (main compromised domain)
  - `polyfill.com`
  - `polyfill.net` 
  - `polyfill.org`

The scanner is focused solely on polyfill.io detection to avoid false positives and provide accurate results.

## Output

The scanner generates detailed reports including:

- Summary of polyfill.io references found
- Detailed information for each detected reference
- URLs where polyfill.io was found
- Timestamps and additional context
- JSON export for integration with other tools

## Example Output

```
================================================================================
POLYFILL.IO SCAN REPORT
================================================================================
Scan Date: 2024-01-15 10:30:45
Total URLs Scanned: 15
Total Polyfill.io References Found: 2

POLYFILL.IO REFERENCES BY SEVERITY:
----------------------------------------
HIGH: 2 references

HIGH SEVERITY POLYFILL.IO REFERENCES:
----------------------------------------
URL: https://example.com/index.html
Type: polyfill.io
Description: Polyfill.io CDN - potentially compromised
Details: Found at position 1234: https://polyfill.io/v3/polyfill.min.js
Timestamp: 2024-01-15T10:30:45.123456
```

## Security Considerations

- The scanner respects robots.txt files by default (use `--bypass-robots` to override)
- Includes rate limiting to avoid overwhelming target servers
- Uses appropriate User-Agent headers
- Handles errors gracefully without exposing sensitive information
- **Warning**: Bypassing robots.txt may violate website terms of service and should be used responsibly

## Logging

All scan activities are logged to both console and `polyfill_scan.log` file for audit purposes.

## Exit Codes

- `0`: Scan completed successfully with no polyfill.io references found
- `1`: Polyfill.io references detected or scan failed
- `130`: Scan interrupted by user (Ctrl+C)

## Contributing

To modify polyfill.io detection patterns, modify the `threat_patterns` dictionary in the `PolyfillScanner` class initialization.
