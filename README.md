# Torrent Downloader

A fast and efficient command-line torrent downloader built with Python and libtorrent.

## Features

- **High-speed downloading** - Optimized for maximum throughput
- **DHT/PEX support** - Connects to peers through multiple protocols
- **Real-time progress** - Shows download speed, ETA, peer count, and progress bar
- **Cross-platform** - Works on Windows, macOS, and Linux
- **Automatic peer discovery** - Uses DHT routers for better peer connectivity
- **Simple CLI** - Easy-to-use command-line interface

## Requirements

- Python 3.7+
- libtorrent library

## Installation

### 1. Install Python
Download from [python.org](https://www.python.org/downloads/)

### 2. Install libtorrent
```bash
pip install libtorrent
```

## Usage

### Basic Usage
```bash
python torrentd.py <path-to-torrent-file>
```

### Specify Output Directory
```bash
python torrentd.py <path-to-torrent-file> -o <output-directory>
```

### Examples
```bash
# Download to default location (./downloads)
python torrentd.py "C:\Users\Admin\Downloads\example.torrent"

# Download to custom location
python torrentd.py "C:\Users\Admin\Downloads\example.torrent" -o "D:\Downloads"
```

## Output

The downloader displays real-time information:
- Progress bar
- Download percentage
- Current/Total size
- Download speed (MB/s)
- Number of connected peers
- Estimated time to completion (ETA)

Example output:
```
  Name   : ubuntu-22.04-desktop-amd64.iso
  Size   : 3.00 GB
  Files  : 1
  Output : ./downloads

  Connecting to peers...

  [########################################] 100.0%  3072.00 / 3072.00 MB  5.50 MB/s  Peers:12  ETA:00:00:00

  +--------------------------------------------------+
  |  DOWNLOAD COMPLETE!                             |
  |  Time: 558s                                      |
  +--------------------------------------------------+
```

## Cancel Download

Press **Ctrl+C** to cancel the download at any time. The torrent will be cleanly removed from the session.

## Troubleshooting

### "libtorrent not found" error
```bash
pip install libtorrent
```

### Slow download speed
- The download speed depends on peer availability
- More peers = faster speeds
- Some torrents may have limited seeders

### Connection issues
- Ensure your firewall allows ports 6881-6891
- Check if UPnP/NAT-PMP is supported by your router
- Try adding more DHT routers in the code

## Batch File (Windows)

A `torrent.bat` file is also available for Windows users who prefer a GUI-like experience:
```cmd
torrent.bat
```

This will prompt you for:
1. Torrent file path (drag & drop supported)
2. Save location
3. Confirmation before starting

## Technical Details

### Protocols Used
- **DHT (Distributed Hash Table)** - Peer discovery
- **PEX (Peer Exchange)** - Peer list sharing
- **LSD (Local Service Discovery)** - Local peer discovery
- **UPnP/NAT-PMP** - Port mapping for better connectivity

### Configuration
Default session settings:
- Active downloads: 10
- Active seeds: 10
- Connection limit: 500
- DHT enabled: Yes
- LSD enabled: Yes
- UPnP enabled: Yes

## License

MIT License - Feel free to use, modify, and distribute.

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

## Author

Developed as a high-performance torrent downloading solution.

## Disclaimer

This tool is for downloading legal content only. Always respect copyright laws and only download torrents that you have permission to download.
