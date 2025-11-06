@echo off
setlocal

:: Ask for username
set /p USERNAME=Enter username:
:: Read Rscript path from config.txt
if not exist "config.txt" (
    echo config.txt not found.
    exit /b 1
)
for /f "usebackq delims=" %%A in ("config.txt") do (
    set "rscript_path=%%~A"
    goto :_got_rscript
)
:_got_rscript
if "%rscript_path%"=="" (
    echo No Rscript path found in config.txt
    exit /b 1
)

:: Ask for password (not truly hidden, but here we'll use PowerShell to hide input)
for /f "delims=" %%p in ('powershell -Command "$pwd = Read-Host 'Enter password' -AsSecureString; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd); [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)"') do set PASSWORD=%%p

:: Call R script, passing username and password as arguments
%rscript_path% "main.R" "%USERNAME%" "%PASSWORD%"

endlocal
pause
