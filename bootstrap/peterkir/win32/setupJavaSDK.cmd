@ECHO off
SETLOCAL EnableExtensions
SETLOCAL EnableDelayedExpansion

:: ### Version History -- X.Y.Z_YYYYMMDD-hhmm Author Description
SET version=1.0.0_20150930-0600 &: Peter Kirschner   downloading,extract,configure latest Java SDK
SET version=%version: =%
SET title=Java SDK setup script %~nx0 - version %version%
TITLE %title%
SET POWERSHELL_TITLE=$Host.UI.RawUI.WindowTitle='%title%'

SET JAVA_WEB=http://www.klib.io/_archives/java/1.8

SET JAVA6_ARCHIVE=win32.x86_64-jre1.8.0_74.zip
SET JAVA6=%JAVA_ARCHIVE:~13,-4%

SET JAVA7_ARCHIVE=win32.x86_64-jre1.8.0_74.zip
SET JAVA7=%JAVA_ARCHIVE:~13,-4%

SET JAVA8_ARCHIVE=win32.x86_64-jre1.8.0_74.zip
SET JAVA8=%JAVA_ARCHIVE:~13,-4%

:: ###########################################################
SET SCRIPTNAME=%~n0
SET SCRIPT_PATH=%~dp0
SET SCRIPT_PATH=%SCRIPT_PATH:~0,-1%

::ECHO.
::ECHO # workaroung for NTLMv2 ProxyAuth - starting IE
::ECHO.
::SET IE_CMD="C:\Program Files (x86)\Internet Explorer\iexplore.exe www.google.de"
::SET IE_DIR="%TEMP%"
::FOR /F "tokens=2 delims=;=" %%a IN (
::	'WMIC process call create %IE_CMD%^, %IE_DIR% ^| find "ProcessId"'
::) DO (
::	SET IE_PID=%%a
::)
::ECHO browser launched with PID %IE_PID%
:: TODO search an kill the IE if not previously open WMIC process %IE_PID% delete

ECHO.
ECHO # downloading and configuring Java - %JAVA8%
ECHO.
ECHO downloading archive %JAVA_WEB%/%JAVA_ARCHIVE%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path %DOWNLOAD_LOCATION%\%JAVA_ARCHIVE% ) { Write-Output 'skipping download, cause file exists - %DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%' } else {(New-Object System.Net.WebClient).DownloadFile('%JAVA_WEB%/%JAVA_ARCHIVE%','%DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%')}"
IF "%ERRORLEVEL%"=="" (
	ECHO failing downloading file %JAVA_WEB%/%JAVA_ARCHIVE%
	GOTO END
)

ECHO extracting %ECLIPSE_INSTALLER% archive to %ECLIPSE_INSTALLER%/%JAVA%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%SCRIPT_PATH%\%OOMPH_NAME%\jre' -PathType Container )  { Write-Output 'skipping extraction, cause folder exists - %SCRIPT_PATH%\%OOMPH_NAME%\jre' } else {Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%', '%SCRIPT_PATH%\download');Move-Item %DOWNLOAD_LOCATION%\%JAVA% %SCRIPT_PATH%\%OOMPH_NAME%\jre}"

ECHO.
ECHO # clean-up
ECHO.
RMDIR /Q /S %DOWNLOAD_LOCATION%

:END