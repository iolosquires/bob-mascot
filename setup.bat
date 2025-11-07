@echo off
setlocal

:: Read Rscript path from config.txt
if not exist "config.txt" (
    echo config.txt not found.
    exit /b 1
)
set /p rscript_path=< config.txt
echo Using Rscript at: %rscript_path%

::Run setup script
%rscript_path% "R/setup.R"

endlocal
pause
