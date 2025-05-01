@echo off
setlocal

:: Define site mappings
set "chatgpt=https://chatgpt.com"
set "gemini=https://gemini.google.com"
set "aistudio=https://aistudio.google.com"
set "google=https://google.com"
set "github=https://github.com"
set "gitlab=https://gitlab.com"
set "vikatan=https://vikatan.com"
set "learn=https://learn.jaganathan.co.uk"
set "hdfc=https://www.hdfcbank.com"

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
