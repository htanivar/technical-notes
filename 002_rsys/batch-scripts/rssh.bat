@echo off
setlocal

REM =======================================================================
REM === rssh.bat: A simple batch script to connect to various servers ===
REM =======================================================================

REM Check if an argument was provided.
if "%1"=="" (
    goto :show_help
)

REM --- Define your SSH aliases below ---
REM You must have `ssh` available in your system's PATH.
if /i "%1"=="pi" (
    ssh ravi@ravi-pi
    goto :eof
)

if /i "%1"=="prod" (
    ssh ravi@ravinath-prod
    goto :eof
)

if /i "%1"=="prod-adm" (
    ssh ravi_adm@ravinath-prod
    goto :eof
)

REM --- If no alias matches, show an error and help ---
echo.
echo Error: Unknown alias "%1"
echo.
goto :show_help

:show_help
echo Usage: rssh ^<alias^>
echo.
echo Available aliases:
echo   pi        (ravi@ravi-pi)
echo   prod      (ravi@ravinath-prod)
echo   prod-adm  (ravi_adm@ravinath-prod)
echo.

:eof