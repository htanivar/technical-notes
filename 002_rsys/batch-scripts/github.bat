@echo off
setlocal

:: Define site mappings
set "tech=https://github.com/htanivar/technical-notes"
set "smartapi=https://github.com/matrixmoney/ai-smartapi"
set "gomask=https://github.com/matrixmoney/gomask"
set "learn=https://github.com/artyregi/learning"

:: Check for argument
if "%1"=="" (
    echo Usage: brw [site]
    exit /b 1
)

:: Normalize to lowercase
set "site=%1"
call :toLower site site

:: Get URL from variable
call set "url=%%%site%%%"

if "%url%"=="" (
    echo Site "%1" not found.
    exit /b 1
)

start "" "%url%"
exit /b 0

:toLower
:: %1 = input var name, %2 = output var name
setlocal ENABLEDELAYEDEXPANSION
set "str=!%~1!"
for %%A in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    set "str=!str:%%A=%%A!"
)
endlocal & set "%~2=%str%"
exit /b
