@echo off
setlocal

:: Ask for username
set /p USERNAME=Enter username: 

:: Ask for password (not truly hidden, but here we'll use PowerShell to hide input)
for /f "delims=" %%p in ('powershell -Command "$pwd = Read-Host 'Enter password' -AsSecureString; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd); [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)"') do set PASSWORD=%%p

:: Call R script, passing username and password as arguments
Rscript "get-mascot.R" "%USERNAME%" "%PASSWORD%"

endlocal
pause
