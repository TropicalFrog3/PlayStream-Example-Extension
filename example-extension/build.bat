@echo off
echo Building Example Extension...
call gradlew.bat assembleDebug
if %ERRORLEVEL% EQU 0 (
    echo Build successful!
) else (
    echo Build failed!
)
pause
