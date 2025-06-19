@echo off
setlocal enabledelayedexpansion

REM =========================
REM Script to build and package Godot Engine with adjustable build params
REM =========================

REM Define source and destination directories
SET "src=E:\godot\src"
SET "dst=E:\godot\editor"

REM Specify the version of Godot being built
SET "ver=4.5.beta"

REM Retrieve the encryption key from environment variable
SET "GODOT_ENCRYPTION_KEY=%GODOT_ENCRYPTION_KEY%"

REM Number of threads to use for parallel building
SET "threads=6"

SET "JAVA_HOME=C:\Program Files\Java\jdk-17"
SET "ANDROID_HOME=U:\Android\Sdk"
SET "ANDROID_NDK_HOME=U:\Android\Sdk\ndk\28.1.13356709"
SET "ANDROID_NDK_ROOT=U:\Android\Sdk\ndk\28.1.13356709"
SET "python_dir=E:\Godot\Python313"

REM Set whether this is a Mono build (true/false)
SET "mono_build=true"
SET "optimise=false"

REM Configure build parameters and filename based on mono_build
IF "%mono_build%"=="true" (
    set "param1=module_mono_enabled=yes"
    SET "release_exe_name=godot.windows.template_release.x86_64.mono.exe"
) ELSE (
    set "param1=module_mono_enabled=no"
    SET "release_exe_name=godot.windows.template_release.x86_64.exe"
)

set "param2=debug_symbols=no"
set "param3=optimize=size"
set "param4=lto=full"
set "param5=module_text_server_adv_enabled=no"
set "param6=module_text_server_fb_enabled=yes"


REM Check for source folder
if not exist "%src%" (
    echo ERROR: Source folder "%src%" does not exist.
    pause
    exit
)

REM Check for destination folder
if not exist "%dst%" (
    echo ERROR: Destination folder "%dst%" does not exist.
    pause
    exit
)

REM Check for encryption key environment variable
if "%GODOT_ENCRYPTION_KEY%"=="" (
    echo ERROR: GODOT_ENCRYPTION_KEY doesn't exist, run keygen.bat to generate an encryption key
    pause
    exit
)

IF "%optimise%"=="true" (
  set "build_params="
  for %%P in (param1 param2 param3 param4 param5 param6) do (
      for /f "tokens=1* delims=" %%A in ("!%%P!") do (
          if defined build_params (
              set "build_params=!build_params! %%A"
          ) else (
              set "build_params=%%A"
          )
      )
  )
) else (
  set "build_params=%param1%"
)

set "script_dir=%~dp0"
if "%script_dir:~-1%"=="\" set "script_dir=%script_dir:~0,-1%"

REM --- Display configuration ---
echo =========================
echo Starting build process with the following configuration:
echo Script is running from: %script_dir%
echo Source directory: %src%
echo Destination directory: %dst%
echo Godot version: %ver%
echo Encryption key environment variable: %GODOT_ENCRYPTION_KEY%
echo Number of threads: %threads%
echo SDK and environment paths:
echo   Java Home: %JAVA_HOME%
echo   Android SDK: %ANDROID_HOME%
echo   Android NDK Home: %ANDROID_NDK_HOME%
echo   Android NDK Root: %ANDROID_NDK_ROOT%
echo   Python Directory: %python_dir%
echo Mono build: %mono_build% 
echo Optimised: %optimise% 
IF "%optimise%"=="true" (
  echo Template build parameters:
  echo   %param2%
  echo   %param3%
  echo   %param4%
  echo   %param5%
  echo   %param6%
)
echo =========================

REM Wait for user input to proceed
pause

rem goto copy

REM --- Copy swappy-frame-pacing folder ---
echo Copying swappy-frame-pacing to source thirdparty directory...
xcopy /E /I /Y "%~dp0swappy-frame-pacing" "%src%\thirdparty\swappy-frame-pacing"

REM Change to source directory
cd /d "%src%"

REM --- Build the Godot editor with Mono support (if mono_build is true) ---
echo Building Godot editor for Windows x86_64...
scons -j %threads% platform=windows arch=x86_64 target=editor %param1%

REM --- Generate Mono glue files ---
if "%mono_build%"=="true" (
    echo Generating Mono glue files at: %src%\modules\mono\glue
    "%src%\bin\godot.windows.editor.x86_64.mono.exe" --headless --generate-mono-glue "%src%\modules\mono\glue"
)

REM --- Build Mono assemblies ---
echo Building Mono assemblies using Python script...
echo Python script path: %python_dir%\python.exe
"%python_dir%\python.exe" "%src%\modules\mono\build_scripts\build_assemblies.py" --godot-output-dir="%src%\bin" --godot-platform=windows

rem "%python_dir%\python.exe" "%src%\modules\mono\build_scripts\build_assemblies.py" --godot-output-dir="%dst%" --godot-platform=windows

REM --- Build release templates ---
echo Building release templates for Windows and Android...
scons -j %threads% platform=windows arch=x86_64 target=template_release %build_params%
scons -j %threads% platform=android target=template_release arch=arm64v8 %build_params%

REM --- Generate Android templates ---
echo Generating Android templates in: %src%\platform\android\java
cd "%src%\platform\android\java"
call .\gradlew generateGodotTemplates

:copy

REM --- Create output directories ---
echo Creating output directories...
mkdir "%dst%\editor_data"
mkdir "%dst%\editor_data\export_templates"
mkdir "%dst%\editor_data\export_templates\%ver%"

REM --- Copy main editor executable ---
set "src_editor_exe=%src%\bin\godot.windows.editor.x86_64.mono.exe"
set "dst_editor_exe=%dst%\godot.exe"
echo From: %src_editor_exe%
echo To:   %dst_editor_exe%
echo Executing: copy /Y "%src_editor_exe%" "%dst_editor_exe%"
copy /Y "%src_editor_exe%" "%dst_editor_exe%"

REM --- Copy GodotSharp folder ---
xcopy /E /I /Y "%src%\bin\GodotSharp" "%dst%\GodotSharp"

echo.

REM --- Copy release build files ---
set "src_release_exe=%src%\bin\godot.windows.template_release.x86_64.mono.exe"
set "dst_release_exe=%dst%\editor_data\export_templates\%ver%\windows_release_x86_64.exe"
echo From: %src_release_exe%
echo To:   %dst_release_exe%
echo Executing: copy /Y "%src_release_exe%" "%dst_release_exe%"
copy /Y "%src_release_exe%" "%dst_release_exe%"

set "src_android_apk=%src%\bin\android_release.apk"
set "dst_android_apk=%dst%\editor_data\export_templates\%ver%\android_release.apk"
echo From: %src_android_apk%
echo To:   %dst_android_apk%
echo Executing: copy /Y "%src_android_apk%" "%dst_android_apk%"
copy /Y "%src_android_apk%" "%dst_android_apk%"

echo.

echo Copying auxiliary tool...
set "src_rcedit=%script_path%\rcedit-x64.exe"
set "dst_rcedit=%dst%\rcedit-x64.exe"
echo From: %src_rcedit%
echo To:   %dst_rcedit%
echo Executing: copy /Y "%src_rcedit%" "%dst_rcedit%"
copy /Y "%src_rcedit%" "%dst_rcedit%"

echo.

echo Writing version info...
del "%dst%\editor_data\export_templates\%ver%\version.txt" 2>nul
echo %ver% > "%dst%\editor_data\export_templates\%ver%\version.txt"
echo "Godot Portable" >> "%dst%\editor_data\export_templates\%ver%\version.txt"

echo.
REM --- Ask user if they want to clean up build folders ---
set /p delete_folders="Do you want to clean up build folders? (Y/N): "

if /i "%delete_folders%"=="Y" (
    echo Deleting 'bin' and 'obj' folders...
    for /d /r "%src%" %%d in (bin obj) do (
        if exist "%%d" (
            echo Deleting folder: %%d
            rmdir /s /q "%%d"
        )
    )
)

pause