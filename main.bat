@echo off
setlocal

:: Ask for username
set /p USERNAME=Enter username:
for /f "delims=" %%p in ('powershell -Command "$pwd = Read-Host 'Enter password' -AsSecureString; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd); [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)"') do set PASSWORD=%%p

:: Read Rscript path from config.txt
if not exist "config.txt" (
    echo config.txt not found.
    exit /b 1
)
set /p rscript_path=< config.txt
echo Using Rscript at: %rscript_path%

:: Call R script, passing username and password as arguments
%rscript_path% "Z:\proteinchem\IoloSquires\00-Projects\OwnProjects\bob-mascot\R\main.R" "%USERNAME%" "%PASSWORD%"

endlocal
pause
