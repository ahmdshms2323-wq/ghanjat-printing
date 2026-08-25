@echo off
setlocal
set GRADLE_VERSION=8.6
set CACHE_DIR=%USERPROFILE%\.gradle\ghanjat-gradle-%GRADLE_VERSION%
set GRADLE_BIN=%CACHE_DIR%\gradle-%GRADLE_VERSION%\bin\gradle.bat
if exist "%GRADLE_BIN%" goto run
if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"
echo Downloading Gradle %GRADLE_VERSION%...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://services.gradle.org/distributions/gradle-%GRADLE_VERSION%-bin.zip' -OutFile '%CACHE_DIR%\gradle.zip'; Expand-Archive -Path '%CACHE_DIR%\gradle.zip' -DestinationPath '%CACHE_DIR%' -Force"
if errorlevel 1 exit /b 1
:run
call "%GRADLE_BIN%" %*
endlocal
