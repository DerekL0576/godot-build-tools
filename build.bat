@echo off

SET src=A:\godot-4.3.dev
SET dst=C:\Apps\godot-4.3.dev
SET ver=4.3.dev
SET SCRIPT_AES256_ENCRYPTION_KEY=%GODOT_ENCRYPTION_KEY%
SET threads=6

IF "%SCRIPT_AES256_ENCRYPTION_KEY%"=="" (
	echo GODOT_ENCRYPTION_KEY doesn't exist, run keygen.bat to generate an encryption key
	pause
	exit
)

IF NOT EXIST %src% (
	echo src doesn't exist: %src% 
	pause
	exit
)

SET JAVA_HOME=%USERPROFILE%\.jdks\liberica-17.0.10
SET ANDROID_HOME=%USERPROFILE%\AppData\Local\Android\Sdk
SET ANDROID_NDK_HOME=%USERPROFILE%\AppData\Local\Android\Sdk\ndk\23.2.8568313
SET ANDROID_NDK_ROOT=%USERPROFILE%\AppData\Local\Android\Sdk\ndk\23.2.8568313

SET script_path=%~dp0
IF %script_path:~-1%==\ SET script_path=%script_path:~0,-1%

cd /d %src%

scons -j %threads% platform=windows arch=x86_64
scons -j %threads% platform=windows target=template_release arch=x86_64
scons -j %threads% platform=android target=template_release arch=arm64v8
cd %src%\platform\android\java
call .\gradlew generateGodotTemplates

mkdir %dst%\editor_data
mkdir %dst%\editor_data\export_templates
mkdir %dst%\editor_data\export_templates\%ver%

SET COPYCMD=/Y

copy /Y %src%\bin\godot.windows.editor.x86_64.exe %dst%\godot.exe

rem upx godot.windows.template_release.x86_64.exe
rem addsection godot.windows.template_release.x86_64.exe

copy /Y %src%\bin\godot.windows.template_release.x86_64.exe %dst%\editor_data\export_templates\%ver%\windows_release_x86_64.exe
copy /Y %src%\bin\android_release.apk %dst%\editor_data\export_templates\%ver%\android_release.apk

copy /Y %script_path%\rcedit-x64.exe %dst%\rcedit-x64.exe

del %dst%\editor_data\export_templates\%ver%\version.txt
echo %ver% >> %dst%\editor_data\export_templates\%ver%\version.txt
echo "Godot Portable" >> _sc_

cd /d %src%
rmdir /s /q %src%\bin

pause
