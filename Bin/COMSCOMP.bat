@echo off
title Prog Assistant COM Companion
echo COM Companion is running...
echo Close this window to stop.
powershell -ExecutionPolicy Bypass -File "Bin\COMCOMP.ps1">nul
timeout /t 3
exit