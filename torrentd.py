try:
    import libtorrent as lt
except ImportError:
    print("[ERROR] libtorrent not found. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "libtorrent"])
    import libtorrent as lt

import time
import os
import sys
import argparse


def format_size(size_bytes):
    """Convert bytes to human-readable format."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.2f} PB"


def format_speed(bytes_per_sec):
    """Convert bytes/sec to human-readable speed."""
    if bytes_per_sec == 0:
        return "0.00 KB/s"
    for unit in ['B/s', 'KB/s', 'MB/s', 'GB/s']:
        if bytes_per_sec < 1024.0:
            return f"{bytes_per_sec:.2f} {unit}"
        bytes_per_sec /= 1024.0
    return f"{bytes_per_sec:.2f} TB/s"


def format_eta(seconds):
    """Format seconds as HH:MM:SS."""
    if seconds < 0 or seconds == float('inf'):
        return "--:--:--"
    return time.strftime("%H:%M:%S", time.gmtime(int(seconds)))


def draw_progress_bar(progress, bar_length=40):
    """Create ASCII progress bar."""
    filled = int(bar_length * progress)
    return '#' * filled + '-' * (bar_length - filled)


def download_torrent(torrent_path, save_path):
    """Main download function."""
    
    # Validate torrent file
    if not os.path.exists(torrent_path):
        print(f"[ERROR] Torrent file not found: {torrent_path}")
        sys.exit(1)
    
    # Create output directory
    try:
        os.makedirs(save_path, exist_ok=True)
    except OSError as e:
        print(f"[ERROR] Cannot create directory: {e}")
        sys.exit(1)
    
    # Load torrent info
    try:
        info = lt.torrent_info(torrent_path)
    except Exception as e:
        print(f"[ERROR] Invalid torrent file: {e}")
        sys.exit(1)
    
    total_size = info.total_size()
    
    print(f"  Name   : {info.name()}")
    print(f"  Size   : {format_size(total_size)}")
    print(f"  Files  : {info.num_files()}")
    print(f"  Output : {save_path}")
    print()
    
    # Session settings
    settings = {
        'active_downloads': 10,
        'active_seeds': 10,
        'connections_limit': 500,
        'download_rate_limit': 0,
        'upload_rate_limit': 0,
        'enable_dht': True,
        'enable_lsd': True,
        'enable_upnp': True,
        'enable_natpmp': True,
    }
    
    ses = lt.session(settings)
    ses.listen_on(6881, 6891)
    
    # DHT bootstrap nodes
    ses.add_dht_router('router.bittorrent.com', 6881)
    ses.add_dht_router('dht.transmissionbt.com', 6881)
    ses.add_dht_router('dht.libtorrent.org', 25401)
    ses.start_dht()
    
    # Add torrent
    params = {
        'ti': info,
        'save_path': save_path,
    }
    
    handle = ses.add_torrent(params)
    handle.resume()
    
    print("  Connecting to peers...")
    print()
    
    start_time = time.time()
    last_print = 0
    
    try:
        while not handle.is_seed():
            status = handle.status()
            now = time.time()
            
            # Update display every 0.5 seconds
            if now - last_print >= 0.5:
                done = status.total_done
                progress = status.progress
                pct = progress * 100
                
                bar = draw_progress_bar(progress)
                
                dl_speed = status.download_rate
                peers = status.num_peers
                
                # Calculate ETA
                if dl_speed > 0:
                    eta_seconds = (total_size - done) / dl_speed
                else:
                    eta_seconds = float('inf')
                
                # Build status line
                line = (
                    f"\r  [{bar}] {pct:5.1f}%  "
                    f"{format_size(done):>10} / {format_size(total_size):>10}  "
                    f"{format_speed(dl_speed):>12}  "
                    f"Peers:{peers:4d}  "
                    f"ETA:{format_eta(eta_seconds)}"
                )
                
                sys.stdout.write(line)
                sys.stdout.flush()
                last_print = now
            
            time.sleep(0.1)
        
        # Download complete
        print()
        elapsed = int(time.time() - start_time)
        
        print()
        print("  +" + "-" * 56 + "+")
        print("  |  DOWNLOAD COMPLETE!" + " " * 37 + "|")
        print(f"  |  Time: {elapsed}s" + " " * 43 + "|")
        print("  +" + "-" * 56 + "+")
        
    except KeyboardInterrupt:
        print()
        print()
        print("  [CANCELLED] Stopping...")
        ses.remove_torrent(handle)
        time.sleep(0.5)
        print("  [OK] Torrent removed from session")
        sys.exit(0)


def main():
    parser = argparse.ArgumentParser(description="Torrent Downloader")
    parser.add_argument("torrent", help="Path to .torrent file")
    parser.add_argument(
        "-o", "--output",
        default=os.path.join(os.getcwd(), "downloads"),
        help="Output directory (default: ./downloads)"
    )
    
    args = parser.parse_args()
    
    # Resolve to absolute path
    torrent_path = os.path.abspath(args.torrent)
    save_path = os.path.abspath(args.output)
    
    download_torrent(torrent_path, save_path)


if __name__ == "__main__":
    main()