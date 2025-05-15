@echo off

SETLOCAL ENABLEDELAYEDEXPANSION
:: put your desired field delimiter here.
:: for example, setting DELIMITER to a hyphen will separate fields like so:
:: yyyy-MM-dd_hh-mm-ss
::
:: setting DELIMITER to nothing will output like so:
:: yyyyMMdd_hhmmss
::
SET DELIMITER=%1

SET DATESTRING=%date:~-4,4%%DELIMITER%%date:~-7,2%%DELIMITER%%date:~-10,2%
SET TIMESTRING=%TIME%
::TRIM OFF the LAST 3 characters of TIMESTRING, which is the decimal point and hundredths of a second
set TIMESTRING=%TIMESTRING:~0,-3%

:: Replace colons from TIMESTRING with DELIMITER
SET TIMESTRING=%TIMESTRING::=!DELIMITER!%

@ECHO OFF
setlocal enabledelayedexpansion
::xcopy "C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\*.bak" C:\Backups\DBs /i

CD C:\Gabriel\Repo\Ags\Site\_autoPublish\agsweb

for %%f in (*) do (
  set /p val=<%%f
  echo "fullname: %%f"
  echo "name: %%~nf"

  "C:\Program Files\WinRAR\rar.exe" a -ep1 -df -r %%~nf_%DATESTRING%Bkp %%f
)

::del "C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\*.bak" 

 