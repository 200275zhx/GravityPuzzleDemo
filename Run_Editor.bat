@echo off
setlocal enabledelayedexpansion

echo =======================================================================
echo       Unreal Engine Editor Launcher (Generate Project Files and Launch)
echo =======================================================================

:: Define local path config for user to save path manually
set "CONFIG_FILE=LocalEnginePath.cfg"

:: 1. Find .uproject
set "PROJECT_FILE="
for %%f in (*.uproject) do set "PROJECT_FILE=%%f"
if "%PROJECT_FILE%"=="" (
    echo [Error] No .uproject found!
    pause
    exit /b
)

:: 2. Check if local path config exists
if exist "%CONFIG_FILE%" (
    set /p USER_ENGINE_PATH=<"%CONFIG_FILE%"
    echo [Info] Found user-defined engine path: !USER_ENGINE_PATH!
    
    if exist "!USER_ENGINE_PATH!\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" (
        set "ENGINE_PATH=!USER_ENGINE_PATH!"
        goto :FoundEngine
    ) else (
        echo [Warning] Saved path is invalid. Retrying auto-detection...
        del "%CONFIG_FILE%"
    )
)

:: 3. Auto-detect (Registry)
echo [Auto-Detect] Scanning Registry...
for /f "usebackq tokens=*" %%a in (`powershell -Command "try { $j = Get-Content '!PROJECT_FILE!' -Raw | ConvertFrom-Json; $ver = $j.EngineAssociation; $regKey = 'HKLM:\SOFTWARE\EpicGames\Unreal Engine\' + $ver; $path = (Get-ItemProperty -Path $regKey -Name 'InstalledDirectory' -ErrorAction Stop).InstalledDirectory; Write-Host $path } catch { Write-Host 'NOT_FOUND' }"`) do (
    set "DETECTED_PATH=%%a"
)

if not "%DETECTED_PATH%"=="NOT_FOUND" (
    if not "%DETECTED_PATH%"=="" (
        set "ENGINE_PATH=%DETECTED_PATH%"
        echo [Success] Engine found in Registry.
        goto :FoundEngine
    )
)

:: 4. Failed auto-detect, turn into manually save path
echo.
echo [!] Could not find Unreal Engine automatically.
echo [!] This usually happens if the Registry is missing or you used a Source Build.
echo.
echo Please copy-paste your Unreal Engine root folder path below.
echo (Example: D:\Epic Games\UE_5.3)
echo.
set /p "ENGINE_PATH=Enter Path > "

:: Delete possible ""
set "ENGINE_PATH=!ENGINE_PATH:"=!"

:: Test if path is valid
if not exist "!ENGINE_PATH!\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" (
    echo.
    echo [Error] That path doesn't look like a valid Unreal Engine installation.
    echo Cannot find UnrealBuildTool.exe.
    pause
    exit /b
)

:: 5. Save valid path to local path config
echo !ENGINE_PATH!> "%CONFIG_FILE%"
echo [Info] Path saved to %CONFIG_FILE%.

:FoundEngine
:: =========================================================
:: Generate project files and launch editor
:: =========================================================

set "UBT_PATH=!ENGINE_PATH!\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"

echo [Action] Generating Project Files...
"%UBT_PATH%" -projectfiles -project="%~dp0%PROJECT_FILE%" -game -rocket -progress

:: Look for editor ue5 or ue4
set "EDITOR_EXE=!ENGINE_PATH!\Engine\Binaries\Win64\UnrealEditor.exe"
if not exist "!EDITOR_EXE!" set "EDITOR_EXE=!ENGINE_PATH!\Engine\Binaries\Win64\UE4Editor.exe"

echo [Action] Launching Editor...
start "" "!EDITOR_EXE!" "%~dp0%PROJECT_FILE%"

echo Done.
timeout /t 3 >nul