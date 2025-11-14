@echo off
pushd "%~dp0python-embed"
start "" /B python.bat "..\serve_S_drive.py"
for /f "tokens=2 delims==; " %%A in ('tasklist /FI "IMAGENAME eq python.exe" /FO LIST ^| findstr PID') do (
    echo %%A > "..\server.pid"
    goto done
)
:done
popd
pause

