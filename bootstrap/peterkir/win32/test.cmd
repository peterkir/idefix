@ECHO OFF
:: ###########################################################################
:: -- Prepare the Command Processor --
SETLOCAL EnableExtensions
SETLOCAL EnableDelayedExpansion

:: ###########################################################
:: -- Version History -- X.Y.Z_YYYYMMDD-hhmm Author Description
SET version=1.0.0_2050917-0900 &: Peter Kirschner   initial version of the script
:: !! For a new version entry, copy the last entry down and modify Date, Author and Description
SET version=%version: =%

:: ###########################################################
SET title=oomphInstaller script %~nx0 - version %version%
TITLE %title%
SET SCRIPTNAME=%~n0
SET SCRIPT_PATH=%~dp0
SET SCRIPT_PATH=%SCRIPT_PATH:~0,-1%

SET DOWNLOAD_LOCATION=C:/TMP
MKDIR %DOWNLOAD_LOCATION% 2>&1 NUL

# builds need to store this
SET BUILD_WEB=http://jazz01.rd.corpintra.net/web/buildresults/dev_16.1/N20150928-100224/CEC-SDK_161.0.0_N20150928-100224.zip
SET BUILD_ARCHIVE=%BUILD_WEB:~74,0%
SET BUILD=%BUILD_WEB:~74,-4%

SET TESTSCRIPT_WEB=http://jazz01.rd.corpintra.net/web/release/testbed/DEMO_ECLauncher_MAPPED.bat
SET TESTSCRIPT=%BUILD_WEB:~51,0%


:: ###########################################################
ECHO.
ECHO # downloading and preparing %BUILD%
ECHO.

ECHO # workaroung for NTLMv2 ProxyAuth issues within powershell - starting IE with Internet website and killing it afterwards
SET "IE_CMD=%ProgramFiles(x86)%\Internet Explorer\iexplore.exe http://daimler.com"
ECHO WMIC process call create %IE_CMD% ^| find "ProcessId"
FOR /F "tokens=2 delims=;=" %%a IN ('WMIC process call create "%IE_CMD%" ^| find "ProcessId"') DO SET IE_PID=%%a
PAUSE
WMIC process IE_PID delete

ECHO downloading archive %BUILD_WEB%
powershell -nologo -noprofile -command "%POWERSHELL_TITLE%;(New-Object System.Net.WebClient).DownloadFile(\"%BUILD_WEB%/%BUILD_ARCHIVE%\",\"%DOWNLOAD_LOCATION%")"
ECHO extracting BUILD archive to %BUILD%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DOWNLOAD_LOCATION%\%BUILD_ARCHIVE%', '%DOWNLOAD_LOCATION%\%BUILD%')"

ECHO preparing automated test execution
powershell -nologo -noprofile -command "%POWERSHELL_TITLE%;(New-Object System.Net.WebClient).DownloadFile(\"%TESTSCRIPT_WEB%",\"%DOWNLOAD_LOCATION%\%BUILD%\%TESTSCRIPT%")"

START /B %DOWNLOAD_LOCATION%\%BUILD%\%TESTSCRIPT%
