@echo on
if exist "%~n0.ini" goto :use_settings_file


if "%1"=="" (echo missing path)
if "%2"=="" (echo missing how many days to keep) & (echo Usage %0 ^<full path^> ^<days^>) & (echo example: "%0 D:\logfiles 30" will cleanup all files older than 30 days in the d:\logfiles directory) & goto :EOF
set logdir=%1
set days=%2
forfiles -p %logdir% -s -m *.* -d -%days% -c "cmd /C del /q @FILE"
::echo Give the full path where the logfiles reside



goto :EOF

:use_settings_file
echo settings file found. Parsing...

::get days from ini file and set to variable.
for /f "tokens=1,2 delims==" %%a IN ('findstr "^days" "%~n0.ini"') do set days=%%b

:: get all location entries from ini file and cleanup those directories recursively. 
for /F "tokens=1,2 delims==" %%a IN ('findstr "^location" "%~n0.ini"') DO forfiles -p "%%b" -s -m *.* -d -%days% -c "cmd /C del /f /q @FILE"

:EOF
::unset used variables
set days=
set logdir=
