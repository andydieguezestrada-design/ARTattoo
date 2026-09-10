@echo off
setlocal
set GRADLE_VERSION=%GRADLE_VERSION%
if "%GRADLE_VERSION%"=="" set GRADLE_VERSION=8.14

where gradle >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  gradle %*
  exit /b %ERRORLEVEL%
)

echo Gradle %GRADLE_VERSION% is not installed on PATH.
echo This project uses the lightweight Unix launcher for GitHub Actions.
echo For local Windows builds, install Gradle %GRADLE_VERSION% or regenerate
echo a standard Gradle wrapper with the same Gradle version.
exit /b 1
