rem @echo off

SET src=..\godot-4.3.dev
SET dst=C:\Apps\godot-4.3.dev
SET ver=4.3.dev
SET SCRIPT_AES256_ENCRYPTION_KEY=%GODOT_ENCRYPTION_KEY%
SET threads=6

SET JAVA_HOME=%USERPROFILE%\.jdks\liberica-17.0.10
SET ANDROID_HOME=%USERPROFILE%\AppData\Local\Android\Sdk
SET ANDROID_NDK_HOME=%USERPROFILE%\AppData\Local\Android\Sdk\ndk\23.2.8568313
SET ANDROID_NDK_ROOT=%USERPROFILE%\AppData\Local\Android\Sdk\ndk\23.2.8568313

SET script_path=%~dp0
IF %script_path:~-1%==\ SET script_path=%script_path:~0,-1%

IF EXIST %src% (
	SET root=%src%
) ELSE (
	SET root=%script_path%\%src%
)

cd /d %root%

IF NOT EXIST %src% (
	echo src doesn't exist: %src% 
	pause
	exit
)

scons -j %threads% platform=windows arch=x86_64
scons -j %threads% platform=windows target=template_release arch=x86_64
scons -j %threads% platform=android target=template_release arch=arm64v8
cd %root%\platform\android\java
call .\gradlew generateGodotTemplates

cd /d %root%\bin

mkdir %dst%\editor_data
mkdir %dst%\editor_data\export_templates
mkdir %dst%\editor_data\export_templates\%ver%

SET COPYCMD=/Y

move /Y godot.windows.editor.x86_64.exe %dst%\godot.exe

rem upx godot.windows.template_release.x86_64.exe
rem addsection godot.windows.template_release.x86_64.exe

move /Y godot.windows.template_release.x86_64.exe %dst%\editor_data\export_templates\%ver%\windows_release_x86_64.exe
move /Y android_release.apk %dst%\editor_data\export_templates\%ver%\android_release.apk

copy /Y %script_path%\rcedit-x64.exe %dst%\rcedit-x64.exe

echo %ver% >> %dst%\editor_data\export_templates\%ver%\version.txt
echo "Godot Portable" >> _sc_

cd /d %root%
rmdir /s /q %root%\bin
