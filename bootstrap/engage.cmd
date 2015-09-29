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

SET OOMPH_NAME=oomphInstaller
SET DOWNLOAD_LOCATION=%SCRIPT_PATH%\download

SET PRODUCT_WEB=http://peterkir.github.io/org.eclipse.oomph/products
SET PRODUCT_ARCHIVE=org.eclipse.oomph.setup.installer.product-win32.win32.x86_64.zip
SET PRODUCT=%PRODUCT_ARCHIVE:~0,-4%

::SET JAVA_WEB=https://s3-eu-west-1.amazonaws.com/klib.io/www/_archives/java/zipped/1.8
SET JAVA_WEB=http://jazz01.rd.corpintra.net/web/repo/_archives/java/zipped/1.8
SET JAVA_ARCHIVE=win32.x86_64-jre1.8.0_60.zip
SET JAVA=%JAVA_ARCHIVE:~13,-4%

%POWERSHELL_TITLE%=$Host.UI.RawUI.WindowTitle='%title%'

:: ###########################################################
MKDIR %SCRIPT_PATH%\download 2>&1 NUL

ECHO.
ECHO # downloading and preparing %PRODUCT%
ECHO.

::ECHO # workaroung for NTLMv2 ProxyAuth issues within powershell - starting IE with Internet website and killing it afterwards
::FOR /F "usebackq tokens=1,2 delims=;=%tab% " %%i IN (
::    `WMIC process call create "%ProgramFiles(x86)%\Internet Explorer\iexplore.exe http://daimler.com"`
::) DO (
::    IF /I %%i EQU ProcessId (
::        SET IE_PID=%%j
::    )
::)
::WMIC process IE_PID delete

ECHO downloading archive %PRODUCT_WEB%/%PRODUCT_ARCHIVE%
:: download of a file with powershell - http://superuser.com/a/423789/344922
powershell -nologo -noprofile -command "%POWERSHELL_TITLE%;(New-Object System.Net.WebClient).DownloadFile(\"%PRODUCT_WEB%/%PRODUCT_ARCHIVE%\",\"%DOWNLOAD_LOCATION%\%PRODUCT_ARCHIVE%\")"
ECHO extracting product archive to %PRODUCT%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DOWNLOAD_LOCATION%\%PRODUCT_ARCHIVE%', '%SCRIPT_PATH%\%OOMPH_NAME%')"

ECHO.
ECHO # downloading and configuring %JAVA_ARCHIVE%
ECHO.
ECHO downloading archive %JAVA_WEB%/%JAVA_ARCHIVE%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;(New-Object System.Net.WebClient).DownloadFile(\"%JAVA_WEB%/%JAVA_ARCHIVE%\",\"%DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%\")"
ECHO extracting product archive to %PRODUCT%/%JAVA%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%', '%SCRIPT_PATH%\download')"
MOVE %DOWNLOAD_LOCATION%\%JAVA% %SCRIPT_PATH%\%OOMPH_NAME%\jre
SET JAVA_HOME=%SCRIPT_PATH%\%OOMPH_NAME%\jre

ECHO.
ECHO # launching %OOMPH_NAME%
ECHO.
START /B %SCRIPT_PATH%\%OOMPH_NAME%\eclipse-inst.exe -vmargs -Doomph.home=%SCRIPT_PATH%

ECHO.
ECHO # clean-up
ECHO.
RMDIR /Q /S %DOWNLOAD_LOCATION%