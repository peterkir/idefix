@ECHO off
SETLOCAL EnableExtensions
SETLOCAL EnableDelayedExpansion

:: ### Version History -- X.Y.Z_YYYYMMDD-hhmm Author Description
SET version=1.0.0_20150930-0600 &: Peter Kirschner   downloading,extract,configure and launch eclipse-installer with jre
SET version=%version: =%
SET title=oomphInstaller script %~nx0 - version %version%
TITLE %title%
SET POWERSHELL_TITLE=$Host.UI.RawUI.WindowTitle='%title%'

IF "%1"=="" (
	SET BRANCH=peterkir
) ELSE (
	SET BRANCH=%1
)

IF "%2"=="" (
	SET JAVA_WEB=http://www.klib.io/_archives/java/1.8
) ELSE (
	::SET JAVA_WEB=https://s3-eu-west-1.amazonaws.com/klib.io/www/_archives/java/zipped/1.8
	SET JAVA_WEB=http://jazz01.rd.corpintra.net/web/repo/_archives/java/zipped/1.8
)
SET JAVA_ARCHIVE=win32.x86_64-jre1.8.0_74.zip
SET JAVA=%JAVA_ARCHIVE:~13,-4%

:: ###########################################################
SET SCRIPTNAME=%~n0
SET SCRIPT_PATH=%~dp0
SET SCRIPT_PATH=%SCRIPT_PATH:~0,-1%

SET OOMPH_NAME=oomphInstaller
SET DOWNLOAD_LOCATION=%SCRIPT_PATH%\download

SET ECLIPSE_FILEDOWNLOAD_URL=http://www.eclipse.org/downloads/download.php
SET ECLIPSE_INSTALLER_EXE=eclipse-inst-win64.exe
SET FILEPATH=/oomph/products/%ECLIPSE_INSTALLER_EXE%
:: download from best mirror [ &r=1 ]
SET "DOWNLOADURL=%ECLIPSE_FILEDOWNLOAD_URL%?file=%FILEPATH%&r=1"

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

MKDIR %SCRIPT_PATH%\download 2>&1 > NUL

:: download of a file with powershell - http://superuser.com/a/423789/344922
ECHO "downloading archive %DOWNLOADURL%"
powershell -nologo -noprofile -command "%POWERSHELL_TITLE%;if ( Test-Path %DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_EXE% ) { Write-Output 'skipping download, cause file exists - %DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_EXE%' } else {$wc=(New-Object System.Net.WebClient);$wc.Headers['User-Agent']='Safari';$wc.DownloadFile('%DOWNLOADURL%','%DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_EXE%')}"
IF "%ERRORLEVEL%"=="" (
	ECHO failing downloading file %ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%
	GOTO END
)

ECHO.
ECHO # downloading and configuring Java - %JAVA%
ECHO.
ECHO downloading archive %JAVA_WEB%/%JAVA_ARCHIVE%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path %DOWNLOAD_LOCATION%\%JAVA_ARCHIVE% ) { Write-Output 'skipping download, cause file exists - %DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%' } else {(New-Object System.Net.WebClient).DownloadFile('%JAVA_WEB%/%JAVA_ARCHIVE%','%DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%')}"
IF "%ERRORLEVEL%"=="" (
	ECHO failing downloading file %JAVA_WEB%/%JAVA_ARCHIVE%
	GOTO END
)

ECHO extracting %JAVA_ARCHIVE% archive to %SCRIPT_PATH%/%JAVA%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%SCRIPT_PATH%\%JAVA%' -PathType Container )  { Write-Output 'skipping extraction, cause folder exists - %SCRIPT_PATH%\%JAVA%' } else {Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%', '%SCRIPT_PATH%')}"

SET JAVA_HOME=%SCRIPT_PATH%\%JAVA%

:: allow installation of unsigned bundles
SET "VMARGS=-Declipse.p2.unsignedPolicy=allow -Declipse.p2.max.threads=4 -Declipse.p2.force.threading=true -Declipse.p2.mirrors=true -Doomph.setup.installer.mode=ADVANCED -Doomph.setup.jre.choice=false -Doomph.installer.update.url=http://download.eclipse.org/oomph/products/latest/repository -Doomph.update.url=http://download.eclipse.org/oomph/updates/latest -Doomph.redirection.klibProductCatalog=index:/redirectable.products.setup-^>http://peterkir.github.io/idefix/oomph/peterkir/products/productsCatalog.setup -Doomph.redirection.klibProjectCatalog=index:/redirectable.projects.setup-^>http://peterkir.github.io/idefix/oomph/peterkir/projects/projectsCatalog.setup"

:: filtering user displayed catalogs/products/versions
::ECHO -Doomph.setup.product.catalog.filter=io.klib.products ^
::ECHO -Doomph.setup.product.filter=idefix.cec.161 ^
::ECHO -Doomph.setup.product.version.filter=none ^


ECHO.
ECHO # launching %OOMPH_NAME%
ECHO.

ECHO %DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_EXE% ^^
ECHO -vm %SCRIPT_PATH%\%JAVA% ^^
ECHO -vmargs %VMARGS%

%DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_EXE% ^
-vm %SCRIPT_PATH%\%JAVA% ^
-vmargs %VMARGS%


:END