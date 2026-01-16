@echo off
REM Security Now! Archive Builder - Launcher
REM Runs sn-full-run.ps1 with PowerShell execution policy bypass

cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -File ".\sn-full-run.ps1" %*
