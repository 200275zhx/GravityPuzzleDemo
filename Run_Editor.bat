@echo off
setlocal enabledelayedexpansion

echo ================================================================
echo       FULL CYCLE: Generate -^> Build -^> Run
echo ================================================================

:: 0. 定义共享配置文件名
set "CONFIG_FILE=LocalEnginePath.cfg"

:: 1. 寻找 .uproject
set "PROJECT_FILE="
for %%f in (*.uproject) do set "PROJECT_FILE=%%f"
if "%PROJECT_FILE%"=="" (
    echo [Error] No .uproject found!
    pause
    exit /b
)
set "PROJECT_NAME=%PROJECT_FILE:.uproject=%"

:: 2. 寻找引擎路径 (读取配置或查注册表)
if exist "%CONFIG_FILE%" (
    set /p USER_ENGINE_PATH=<"%CONFIG_FILE%"
    set "USER_ENGINE_PATH=!USER_ENGINE_PATH: =!"
    if exist "!USER_ENGINE_PATH!\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" (
        set "ENGINE_PATH=!USER_ENGINE_PATH!"
        goto :FoundEngine
    )
)

echo [Auto-Detect] Scanning Registry...
for /f "usebackq tokens=*" %%a in (`powershell -Command "try { $j = Get-Content '!PROJECT_FILE!' -Raw | ConvertFrom-Json; $ver = $j.EngineAssociation; $regKey = 'HKLM:\SOFTWARE\EpicGames\Unreal Engine\' + $ver; $path = (Get-ItemProperty -Path $regKey -Name 'InstalledDirectory' -ErrorAction Stop).InstalledDirectory; Write-Host $path } catch { Write-Host 'NOT_FOUND' }"`) do (
    set "DETECTED_PATH=%%a"
)

if not "%DETECTED_PATH%"=="NOT_FOUND" (
    if not "%DETECTED_PATH%"=="" (
        set "ENGINE_PATH=%DETECTED_PATH%"
        goto :FoundEngine
    )
)

echo.
echo [!] Could not find Unreal Engine.
set /p "ENGINE_PATH=Enter Path > "
set "ENGINE_PATH=!ENGINE_PATH:"=!"
if not exist "!ENGINE_PATH!\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" (
    echo [Error] Invalid path!
    pause
    exit /b
)
echo !ENGINE_PATH!> "%CONFIG_FILE%"

:FoundEngine
set "UBT_PATH=!ENGINE_PATH!\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"

:: =========================================================
:: 第一步：画图纸 (Generate Project Files)
:: =========================================================
echo.
echo [Step 1/3] Generating Project Files...
"%UBT_PATH%" -projectfiles -project="%~dp0%PROJECT_FILE%" -game -rocket -progress

if %ERRORLEVEL% NEQ 0 (
    echo [Error] Generate failed!
    pause
    exit /b
)

:: =========================================================
:: 第二步：盖房子 (Build C++ Code)
:: =========================================================
echo.
echo [Step 2/3] Compiling C++ Code (Development Editor)...
echo ----------------------------------------------------------------
"%UBT_PATH%" !PROJECT_NAME!Editor Win64 Development -Project="%~dp0%PROJECT_FILE%" -WaitMutex

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] COMPILATION FAILED! 
    echo ----------------------------------------------------------------
    pause
    exit /b
)

:: =========================================================
:: 第三步：交房 (Launch Editor)
:: =========================================================
echo.
echo [Step 3/3] Launching Editor...
set "EDITOR_EXE=!ENGINE_PATH!\Engine\Binaries\Win64\UnrealEditor.exe"
if not exist "!EDITOR_EXE!" set "EDITOR_EXE=!ENGINE_PATH!\Engine\Binaries\Win64\UE4Editor.exe"

start "" "!EDITOR_EXE!" "%~dp0%PROJECT_FILE%"

echo Done.
timeout /t 3 >nul