
@echo off

if not "%GODOT_ENCRYPTION_KEY%"=="" (
	echo GODOT_ENCRYPTION_KEY environment variable is already set, please delete before generating a new key
	pause
	exit
)

cd /d "C:\Program Files\Git\usr\bin"

for /f %%i in ('openssl rand -hex 32') do set key=%%i

setx GODOT_ENCRYPTION_KEY %key%

SET script_path=%~dp0
IF %script_path:~-1%==\ SET script_path=%script_path:~0,-1%

echo %key%>%script_path%\godot_encryption.key
echo GODOT_ENCRYPTION_KEY = %key%
echo A backup was created at %script_path%\godot_encryption.key

pause