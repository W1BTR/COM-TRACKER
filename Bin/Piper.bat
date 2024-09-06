@echo off
cls
call "%temp%\PASCD.cmd
del /f /q "%temp%\PASCD.cmd
COMpipe -b %baudrate% -c \\.\%port% -p %name%
echo Quitting in 5 seconds . . .
timeout /t 5 >nul
exit /b