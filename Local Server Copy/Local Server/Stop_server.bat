@echo off
set PIDFILE=server.pid

if not exist %PIDFILE% (
    echo Geen server.pid bestand gevonden. Server draait waarschijnlijk niet.
    pause
    exit /b
)

set /p PID=<%PIDFILE%

echo Poging om proces met PID %PID% te stoppen...
taskkill /PID %PID% /F >nul 2>&1

if %errorlevel%==0 (
    echo Server is gestopt.
    del %PIDFILE%
) else (
    echo Mislukt: mogelijk draait het proces niet meer of heb je geen rechten.
)

pause
