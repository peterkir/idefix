@ECHO off
SETLOCAL EnableExtensions
SETLOCAL EnableDelayedExpansion

:: ### Version History -- X.Y.Z_YYYYMMDD-hhmm Author Description
SET version=1.0.0_20150930-0600 &: Peter Kirschner   downloading,extract,configure and launch eclipse-installer with jre
SET version=%version: =%
SET title=idefixInstaller script %~nx0 - version %version%
TITLE %title%
SET POWERSHELL_TITLE=$Host.UI.RawUI.WindowTitle='%title%'

IF "%1"=="" (
	SET BRANCH=peterkir
) ELSE (
	SET BRANCH=%1
)

:: ###########################################################
SET SCRIPTNAME=%~n0
SET SCRIPT_PATH=%~dp0
SET SCRIPT_PATH=%SCRIPT_PATH:~0,-1%

SET IDEFIX_NAME=idefixInstaller
SET DOWNLOAD_LOCATION=%SCRIPT_PATH%\download

SET BRANCH=master
SET GITHUB_IO=http://peterkir.github.io/org.eclipse.oomph/
SET GITHUB_IO_LATEST=latest

SET GITHUB_IO_BOOT=http://peterkir.github.io/idefix/bootstrap/peterkir/win32

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
ECHO # downloading and configuring Java via %GITHUB_IO_BOOT%/%JAVA_CMD%
ECHO.

SET JAVA_CMD=setupJavaSDK.cmd
ECHO downloading and execute %GITHUB_IO_BOOT%/%JAVA_CMD%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path %DOWNLOAD_LOCATION%\%JAVA_CMD% ) { Write-Output 'skipping download, cause file exists - %DOWNLOAD_LOCATION%\%JAVA_CMD%' } else {(New-Object System.Net.WebClient).DownloadFile('%GITHUB_IO_BOOT%/%JAVA_CMD%','%DOWNLOAD_LOCATION%\%JAVA_CMD%')}"
IF "%ERRORLEVEL%"=="" (
	ECHO failing downloading file %GITHUB_IO_BOOT%/%JAVA_CMD%
	GOTO END
)

CALL %DOWNLOAD_LOCATION%\%JAVA_CMD% %SCRIPT_PATH%

PAUSE

ECHO.
ECHO # downloading and preparing %ECLIPSE_INSTALLER%
ECHO.

MKDIR %SCRIPT_PATH%\download 2>&1 > NUL

:: download of a file with powershell - http://superuser.com/a/423789/344922
ECHO retrieving latest build 
powershell -nologo -noprofile -command "%POWERSHELL_TITLE%; (New-Object System.Net.WebClient).DownloadFile('%GITHUB_IO%/%BRANCH%/%GITHUB_IO_LATEST%','%DOWNLOAD_LOCATION%\%BRANCH%_%GITHUB_IO_LATEST%')"
SET /P LATEST=<%DOWNLOAD_LOCATION%\%BRANCH%_%GITHUB_IO_LATEST%

SET BINTRAY_BUILD_ROOT=https://dl.bintray.com/peterkir/generic/org.eclipse.oomph/1.3.0/%BRANCH%/%LATEST%

SET ECLIPSE_INSTALLER_WEB=%BINTRAY_BUILD_ROOT%/products
SET ECLIPSE_INSTALLER_ARCHIVE=org.eclipse.oomph.setup.installer.product-win32.win32.x86_64.zip
SET ECLIPSE_INSTALLER=%ECLIPSE_INSTALLER_ARCHIVE:~0,-4%

ECHO downloading archive %ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%
powershell -nologo -noprofile -command "%POWERSHELL_TITLE%;if ( Test-Path %DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_ARCHIVE% ) { Write-Output 'skipping download, cause file exists - %DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_ARCHIVE%' } else {(New-Object System.Net.WebClient).DownloadFile('%ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%','%DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_ARCHIVE%')}"
IF "%ERRORLEVEL%"=="" (
	ECHO failing downloading file %ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%
	GOTO END
)

ECHO extracting ECLIPSE_INSTALLER archive to %ECLIPSE_INSTALLER%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%SCRIPT_PATH%\%IDEFIX_NAME%' -PathType Container )  { Write-Output 'skipping extraction, cause folder exists - %SCRIPT_PATH%\%IDEFIX_NAME%' } else {Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DOWNLOAD_LOCATION%\%ECLIPSE_INSTALLER_ARCHIVE%', '%SCRIPT_PATH%\%IDEFIX_NAME%')}"

:: do here something


ECHO extracting %ECLIPSE_INSTALLER% archive to %ECLIPSE_INSTALLER%/%JAVA%
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%SCRIPT_PATH%\%IDEFIX_NAME%\jre' -PathType Container )  { Write-Output 'skipping extraction, cause folder exists - %SCRIPT_PATH%\%IDEFIX_NAME%\jre' } else {Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DOWNLOAD_LOCATION%\%JAVA_ARCHIVE%', '%SCRIPT_PATH%\download');Move-Item %DOWNLOAD_LOCATION%\%JAVA% %SCRIPT_PATH%\%IDEFIX_NAME%\jre}"

SET JAVA_HOME=%SCRIPT_PATH%\%IDEFIX_NAME%\jre
SET "IDEFIX_HOME=%SCRIPT_PATH%"
MKDIR %IDEFIX_HOME% 2>&1 > NUL

SET IDEFIX_HOME=%IDEFIX_HOME:\=/%
SET IDEFIX_INI=%SCRIPT_PATH%\%IDEFIX_NAME%\eclipse-inst.ini

ECHO adding vmArgs to ini file
:: allow installation of unsigned bundles
ECHO -Declipse.p2.unsignedPolicy=allow >> %IDEFIX_INI%

:: hidden p2 options (configured to default)
ECHO -Declipse.p2.max.threads=4  >> %IDEFIX_INI%
ECHO -Declipse.p2.force.threading=true >> %IDEFIX_INI%
ECHO -Declipse.p2.mirrors=true >> %IDEFIX_INI%

:: filtering user displayed catalogs/products/versions
ECHO -Doomph.setup.product.catalog.filter=io.klib.products >> %IDEFIX_INI%
::ECHO -Doomph.setup.product.filter=idefix.cec.161 >> %IDEFIX_INI%
::ECHO -Doomph.setup.product.version.filter=none >> %IDEFIX_INI%

ECHO -Doomph.setup.jre.choice=false >> %IDEFIX_INI%
::ECHO -Doomph.installer.update.url=%BINTRAY_BUILD_ROOT%/p2/installer >> %IDEFIX_INI%
::ECHO -Doomph.update.url=%BINTRAY_BUILD_ROOT%/p2/oomph >> %IDEFIX_INI%
ECHO -Doomph.setup.installer.mode=advanced >> %IDEFIX_INI%
ECHO -Doomph.redirection.klibProductCatalog=index:/redirectable.products.setup-^>http://peterkir.github.io/idefix/oomph/peterkir/productsCatalog.setup >> %IDEFIX_INI%
ECHO -Doomph.redirection.klibProjectCatalog=index:/redirectable.projects.setup-^>http://peterkir.github.io/idefix/oomph/peterkir/projectsCatalog.setup >> %IDEFIX_INI%

ECHO.
ECHO # launching %IDEFIX_NAME%
ECHO.
START /B %SCRIPT_PATH%\%IDEFIX_NAME%\eclipse-inst.exe

::ECHO.
::ECHO # clean-up
::ECHO.
::RMDIR /Q /S %DOWNLOAD_LOCATION%

:END
