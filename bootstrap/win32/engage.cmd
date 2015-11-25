@ECHO off
SETLOCAL EnableExtensions
SETLOCAL EnableDelayedExpansion

:: ### Version History -- X.Y.Z_YYYYMMDD-hhmm Author Description
SET version=1.0.0_20150930-0600 &: Peter Kirschner   downloading,extract,configure and launch eclipse-installer with jre
SET version=%version: =%
SET title=oomphInstaller script %~nx0 - version %version%
TITLE %title%
SET POWERSHELL_TITLE=$Host.UI.RawUI.WindowTitle='%title%'

:: ###########################################################
SET SCRIPTNAME=%~n0
SET SCRIPT_PATH=%~dp0
SET SCRIPT_PATH=%SCRIPT_PATH:~0,-1%

SET OOMPH_NAME=oomphInstaller
SET DOWNLOAD_LOCATION=%SCRIPT_PATH%\download

SET ECLIPSE_INSTALLER_WEB=http://peterkir.github.io/org.eclipse.oomph/peterkir/products
SET ECLIPSE_INSTALLER_ARCHIVE=org.eclipse.oomph.setup.installer.product-win32.win32.x86_64.zip
SET ECLIPSE_INSTALLER=%ECLIPSE_INSTALLER_ARCHIVE:~0,-4%

::SET JAVA_WEB=https://s3-eu-west-1.amazonaws.com/klib.io/www/_archives/java/zipped/1.8
SET JAVA_WEB=http://jazz01.rd.corpintra.net/web/repo/_archives/java/zipped/1.8
SET JAVA_ARCHIVE=win32.x86_64-jre1.8.0_60.zip
SET JAVA=%JAVA_ARCHIVE:~13,-4%

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
ECHO # downloading and preparing %ECLIPSE_INSTALLER%
ECHO.

:: download of a file with powershell - http://superuser.com/a/423789/344922
MKDIR %SCRIPT_PATH%\download 2>&1 > NUL

ECHO downloading archive %ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%
powershell -nologo -noprofile -command "%POWERSHELL_TITLE%;if ( Test-Path %DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_ARCHIVE% ) { Write-Output 'skipping download, cause file exists - %DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_ARCHIVE%' } else {(New-Object System.Net.WebClient).DownloadFile('%ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%','%DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_ARCHIVE%')}"

ECHO extracting ECLIPSE_INSTALLER archive to %ECLIPSE_INSTALLER%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%SCRIPT_PATH%\%OOMPH_NAME%' -PathType Container )  { Write-Output 'skipping extraction, cause folder exists - %SCRIPT_PATH%\%OOMPH_NAME%' } else {Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_ARCHIVE%', '%SCRIPT_PATH%\%OOMPH_NAME%')}"

ECHO.
ECHO # downloading and configuring %JAVA_ARCHIVE%
ECHO.

ECHO downloading archive %JAVA_WEB%/%JAVA_ARCHIVE%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path %DOWNLOAD_LOCATION%\%JAVA_ARCHIVE% ) { Write-Output 'skipping download, cause file exists - %DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%' } else {(New-Object System.Net.WebClient).DownloadFile('%JAVA_WEB%/%JAVA_ARCHIVE%','%DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%')}"

ECHO extracting %ECLIPSE_INSTALLER% archive to %ECLIPSE_INSTALLER%/%JAVA%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%SCRIPT_PATH%\%OOMPH_NAME%\jre' -PathType Container )  { Write-Output 'skipping extraction, cause folder exists - %SCRIPT_PATH%\%OOMPH_NAME%\jre' } else {Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%', '%SCRIPT_PATH%\download');Move-Item %DOWNLOAD_LOCATION%\%JAVA% %SCRIPT_PATH%\%OOMPH_NAME%\jre}"

SET JAVA_HOME=%SCRIPT_PATH%\%OOMPH_NAME%\jre
SET "OOMPH_HOME=%SCRIPT_PATH%\oomph"

MKDIR %OOMPH_HOME% 2>&1 > NUL
SET OOMPH_HOME=%OOMPH_HOME:\=/%
ECHO -Doomph.home=%OOMPH_HOME% >> %SCRIPT_PATH%\%OOMPH_NAME%\eclipse-inst.ini

::SET INSTALL_ROOT=%SCRIPT_PATH%\install
::MKDIR %INSTALL_ROOT% 2>&1 > NUL
::SET INSTALL_ROOT=%INSTALL_ROOT:\=/%
::ECHO -Dinstall.root=%INSTALL_ROOT% >> %SCRIPT_PATH%\%OOMPH_NAME%\eclipse-inst.ini

::SET WRKSPC_ROOT=%SCRIPT_PATH%\wrkspc
::MKDIR %WRKSPC_ROOT% 2>&1 > NUL
::SET WRKSPC_ROOT=%WRKSPC_ROOT:\=/%
::ECHO -Dworkspace.container.root=%WRKSPC_ROOT% >> %SCRIPT_PATH%\%OOMPH_NAME%\eclipse-inst.ini

ECHO adding klib.io Products
ECHO -Doomph.redirection.klibProductCatalog=index:/redirectable.products.setup-^>http://peterkir.github.io/idefix/oomph/products/_productsCatalog.setup >> %SCRIPT_PATH%\%OOMPH_NAME%\eclipse-inst.ini

ECHO adding klib.io Projects
ECHO -Doomph.redirection.klibProjectCatalog=index:/redirectable.projects.setup-^>http://peterkir.github.io/idefix/oomph/projects/_projectsCatalog.setup >> %SCRIPT_PATH%\%OOMPH_NAME%\eclipse-inst.ini

ECHO.
ECHO # launching %OOMPH_NAME%
ECHO.
START /B %SCRIPT_PATH%\%OOMPH_NAME%\eclipse-inst.exe

ECHO.
ECHO # clean-up
ECHO.
RMDIR /Q /S %DOWNLOAD_LOCATION%