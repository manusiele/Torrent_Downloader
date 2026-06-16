@echo off
setlocal EnableDelayedExpansion
cls

echo.
echo =====================================================
echo   TORRENT DOWNLOADER v3.2
echo =====================================================
echo.

REM Check Python
echo [*] Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found! Install from https://www.python.org/downloads/
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo [OK] %%v
echo.

REM Check libtorrent
echo [*] Checking libtorrent...
python -c "import libtorrent" >nul 2>&1
if errorlevel 1 (
    echo [~] Installing libtorrent (this may take a moment)...
    pip install -q libtorrent >nul 2>&1
    python -c "import libtorrent" >nul 2>&1
    if errorlevel 1 (
        echo [X] Failed to install libtorrent
        echo [TIP] Try: pip install libtorrent
        pause
        exit /b 1
    )
    echo [OK] Installed!
) else (
    echo [OK] libtorrent found
)
echo.

REM Get torrent file from argument or prompt
if not "%~1"=="" (
    set "TORRENT=%~f1"
    goto got_torrent
)

echo =====================================
echo STEP 1 - TORRENT FILE
echo =====================================
echo.
echo Drag .torrent file here or type full path:
set /p "TORRENT=>> "

REM Remove quotes if present
set "TORRENT=!TORRENT:"=!"

if "!TORRENT!"=="" (
    echo [ERROR] No file specified
    pause
    exit /b 1
)

REM Convert to absolute path
for %%F in ("!TORRENT!") do set "TORRENT=%%~fF"

if not exist "!TORRENT!" (
    echo [ERROR] File not found: !TORRENT!
    pause
    exit /b 1
)

:got_torrent
echo [OK] Torrent: !TORRENT!
echo.

REM Get output directory
echo =====================================
echo STEP 2 - SAVE LOCATION
echo =====================================
echo.
echo Default location: %USERPROFILE%\Downloads
set /p "OUTPUT=Enter save directory (or press Enter): "

REM Remove quotes if present
set "OUTPUT=!OUTPUT:"=!"

if "!OUTPUT!"=="" set "OUTPUT=%USERPROFILE%\Downloads"

REM Convert to absolute path
for %%F in ("!OUTPUT!") do set "OUTPUT=%%~fF"

echo [OK] Saving to: !OUTPUT!
echo.

REM Confirm
set /p "CONFIRM=Start download? [Y/n]: "
if /i "!CONFIRM!"=="n" (
    echo Cancelled.
    pause
    exit /b 0
)

cls
echo.
echo =====================================================
echo   DOWNLOADING - Press Ctrl+C to cancel
echo =====================================================
echo.

REM Create temporary Python script
set "PYFILE=%TEMP%\torrent_dl_%RANDOM%.py"

(
echo import libtorrent as lt
echo import time, os, sys
echo.
echo torrent_path = r"!TORRENT!"
echo save_path = r"!OUTPUT!"
echo.
echo try:
echo     os.makedirs(save_path, exist_ok=True^)
echo     info = lt.torrent_info(torrent_path^)
echo     total_size = info.total_size(^)
echo     print('  Name   : ' + info.name(^)^)
echo     print('  Size   : %%.2f GB' %% (total_size / (1024**3^)^)^)
echo     print('  Files  : %%d' %% info.num_files(^)^)
echo     print('  Output : ' + save_path^)
echo     print(^)
echo except Exception as e:
echo     print('[ERROR] Invalid torrent: ' + str(e^)^)
echo     sys.exit(1^)
echo.
echo settings = {
echo     'active_downloads': 10,
echo     'active_seeds': 10,
echo     'connections_limit': 500,
echo     'download_rate_limit': 0,
echo     'upload_rate_limit': 0,
echo     'enable_dht': True,
echo     'enable_lsd': True,
echo     'enable_upnp': True,
echo     'enable_natpmp': True,
echo }
echo.
echo ses = lt.session(settings^)
echo ses.listen_on(6881, 6891^)
echo.
echo ses.add_dht_router('router.bittorrent.com', 6881^)
echo ses.add_dht_router('dht.transmissionbt.com', 6881^)
echo ses.add_dht_router('dht.libtorrent.org', 25401^)
echo ses.start_dht(^)
echo.
echo h = ses.add_torrent({'ti': info, 'save_path': save_path}^)
echo h.resume(^)
echo.
echo print('  Connecting to peers...'^)
echo print(^)
echo.
echo start_time = time.time(^)
echo last_print = 0
echo.
echo try:
echo     while not h.is_seed(^):
echo         s = h.status(^)
echo         now = time.time(^)
echo.
echo         if now - last_print ^>= 0.5:
echo             done = s.total_done
echo             pct = s.progress * 100
echo             bar_len = 40
echo             filled = int(bar_len * s.progress^)
echo             bar = '#' * filled + '-' * (bar_len - filled^)
echo.
echo             dl_speed = s.download_rate / (1024**2^)
echo             peers = s.num_peers
echo.
echo             if s.download_rate ^> 0:
echo                 eta_sec = int((total_size - done^) / s.download_rate^)
echo                 eta = time.strftime('%%H:%%M:%%S', time.gmtime(eta_sec^)^)
echo             else:
echo                 eta = '--:--:--'
echo.
echo             mb_done = done / (1024**2^)
echo             mb_total = total_size / (1024**2^)
echo.
echo             sys.stdout.write('\r  [%%s] %%5.1f%%%%  %%8.0f/%%8.0f MB  %%6.2f MB/s  Peers:%%d  ETA:%%s' %% (bar, pct, mb_done, mb_total, dl_speed, peers, eta^)^)
echo             sys.stdout.flush(^)
echo             last_print = now
echo.
echo         time.sleep(0.1^)
echo.
echo     print(^)
echo     elapsed = int(time.time(^) - start_time^)
echo     print(^)
echo     print('  +' + '-' * 50 + '+'^)
echo     print('  ^|  DOWNLOAD COMPLETE!' + ' ' * 31 + '^|'^)
echo     print('  ^|  Time: %%ds' %% elapsed + ' ' * 37 + '^|'^)
echo     print('  +' + '-' * 50 + '+'^)
echo.
echo except KeyboardInterrupt:
echo     print(^)
echo     print(^)
echo     print('  [CANCELLED] Stopping...'^)
echo     ses.remove_torrent(h^)
echo     time.sleep(0.5^)
echo     print('  [OK] Torrent removed from session'^)
echo     sys.exit(0^)
) > "%PYFILE%"

REM Run the Python script
python "%PYFILE%"
set "EXITCODE=%ERRORLEVEL%"

REM Cleanup
if exist "%PYFILE%" del "%PYFILE%" >nul 2>&1

echo.
if %EXITCODE% neq 0 (
    echo [ERROR] Process exited with code %EXITCODE%
) else (
    echo [SUCCESS] Download completed!
)
pause
exit /b %EXITCODE%
