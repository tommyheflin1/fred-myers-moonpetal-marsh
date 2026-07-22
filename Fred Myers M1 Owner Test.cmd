@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\launch_m1_owner_test.ps1"
if errorlevel 1 pause
