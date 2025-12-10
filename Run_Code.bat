@echo off
setlocal enabledelayedexpansion

echo ================================================================
echo       Unreal Engine Project Setup Tool (Auto-Detect)
echo ================================================================

:: 1. Look for .uproject in this folder
set "PROJECT_FILE="
for %%f in (*.uproject) do set "PROJECT_FILE=%%f"

if "%PROJECT_FILE%"=="" (
    echo [Error] No .uproject file found in the current directory!
    pause
    exit /b
)

echo [Info] Found project: !PROJECT_FILE!

:: 2. Use powershell to find version from .uproject and look for registration chart
set "ENGINE_PATH="
for /f "usebackq tokens=*" %%a in (`powershell -Command "try { $j = Get-Content '!PROJECT_FILE!' -Raw | ConvertFrom-Json; $ver = $j.EngineAssociation; $regKey = 'HKLM:\SOFTWARE\EpicGames\Unreal Engine\' + $ver; $path = (Get-ItemProperty -Path $regKey -Name 'InstalledDirectory' -ErrorAction Stop).InstalledDirectory; Write-Host $path } catch { Write-Host 'NOT_FOUND' }"`) do (
    set "ENGINE_PATH=%%a"
)

:: 3. Check if found engine path
if "%ENGINE_PATH%"=="NOT_FOUND" (
    echo.
    echo [Error] Could not find Unreal Engine installation in Registry!
    echo [Check] 1. Is the engine version in .uproject installed?
    echo [Check] 2. Did you install it via Epic Launcher?
    echo.
    pause
    exit /b
)

if "%ENGINE_PATH%"=="" (
    echo [Error] Failed to detect engine path.
    pause
    exit /b
)

echo [Info] Engine detected at: %ENGINE_PATH%

:: 4. Make UnrealBuildTool Path
set "UBT_PATH=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"

if not exist "%UBT_PATH%" (
    echo [Error] UnrealBuildTool not found at: "%UBT_PATH%"
    pause
    exit /b
)

:: 5. Generate Project Files
echo [Action] Generating Project Files...
"%UBT_PATH%" -projectfiles -project="%~dp0%PROJECT_FILE%" -game -rocket -progress

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [Error] GenerateProjectFiles failed!
    pause
    exit /b
)

echo.
echo [Success] Project files generated.

:: 6. Open .sln
echo [Action] Opening Visual Studio Solution...
for %%f in (*.sln) do (
    start "" "%%f"
    goto :Done
)

:Done
echo Done.
timeout /t 3 >nul