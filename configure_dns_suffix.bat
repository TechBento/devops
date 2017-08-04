@echo off
REM REM Script:	Configure DNS Suffix for Clients Domain / Windows 10
REM Modified:	08/04/2017
REM SETLOCAL EnableDelayedExpansion

:: Replace %USERDNSDOMAIN% if you need a custom suffix
set suffix=%USERDNSDOMAIN%

:START
:: Get existing DNS suffixes from the registry
FOR /F "usebackq tokens=1,2* delims= " %%A in (`reg QUERY HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters /V SearchList ^| findstr REG_SZ`) do ( 
set OLD_DNS=%%C
)

:: Check if the current list starts with our suffix
set OK=NO
FOR /F "tokens=1,2* delims=," %%A in ("%OLD_DNS%") do (
if "%%A" == "%suffix%" set OK=YES
)

:: Add our suffix first if it's not there
if "%OK%" == "NO" (
echo Conf KO: %OLD_DNS%
reg add HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters /V SearchList /D "%suffix%,%OLD_DNS%" /F
) else (
echo Conf OK: %OLD_DNS%
)

::Flush the DNS to allow our suffix to be used
ipconfig /flushdns

:EOF
