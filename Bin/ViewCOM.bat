@echo off
cls
rem delay while Prog Assistant refreshes data to avoid confliction
title Viewing Output of %~1
echo | set /p "=Connecting to %~1"
timeout /t 1 /nobreak >nul
echo | set /p "= ."
timeout /t 1 /nobreak >nul
echo | set /p "= ."
timeout /t 1 /nobreak >nul
echo | set /p "= ."
timeout /t 1 /nobreak >nul
cls
type %~1
exit