@echo off
setlocal enabledelayedexpansion

echo ================================================================
echo       Unreal Editor Launcher (Generate project files & Launch)
echo ================================================================

:: 1. Look for .uproject file
set "PROJECT_FILE="
for %%f in (*.uproject) do set "PROJECT_FILE=%%f"

if "%PROJECT_FILE%"=="" (
    echo [Error] No .uproject file found!
    pause
    exit /b
)

echo [Info] Target Project: !PROJECT_FILE!

:: 2. Read version from .uproject and check registration chart
set "ENGINE_PATH="
for /f "usebackq tokens=*" %%a in (`powershell -Command "try { $j = Get-Content '!PROJECT_FILE!' -Raw | ConvertFrom-Json; $ver = $j.EngineAssociation; $regKey = 'HKLM:\SOFTWARE\EpicGames\Unreal Engine\' + $ver; $path = (Get-ItemProperty -Path $regKey -Name 'InstalledDirectory' -ErrorAction Stop).InstalledDirectory; Write-Host $path } catch { Write-Host 'NOT_FOUND' }"`) do (
    set "ENGINE_PATH=%%a"
)

if "%ENGINE_PATH%"=="NOT_FOUND" (
    echo [Error] Engine version not found in Registry.
    pause
    exit /b
)

:: 3. (Optional) Generate project files
::    Comment if starting editor too slow (by adding :: at first)
set "UBT_PATH=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
echo [Action] Checking project files...
"%UBT_PATH%" -projectfiles -project="%~dp0%PROJECT_FILE%" -game -rocket -progress

:: 4. Look for editor
set "EDITOR_EXE=%ENGINE_PATH%\Engine\Binaries\Win64\UnrealEditor.exe"
if not exist "!EDITOR_EXE!" (
    :: 如果找不到 UnrealEditor.exe，尝试找 UE4 的名字
    set "EDITOR_EXE=%ENGINE_PATH%\Engine\Binaries\Win64\UE4Editor.exe"
)

if not exist "!EDITOR_EXE!" (
    echo [Error] Could not find Editor executable!
    pause
    exit /b
)

:: 5. Launch editor
echo.
echo [Action] Launching Unreal Editor...
echo [Path] !EDITOR_EXE!
echo.

:: start "" followed by exe path and project path
start "" "!EDITOR_EXE!" "%~dp0%PROJECT_FILE%"

echo Done. Closing in 3 seconds...
timeout /t 3 >nul