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
SET DL=%SCRIPT_PATH%\.download
:: folder must exists for powershell download requests
MKDIR %DL% 2>&1 > NUL

SET BRANCH=master
SET VERSION=1.4.0
SET GITHUB_IO=http://peterkir.github.io/org.eclipse.oomph/
SET GITHUB_IO_LATEST=latest

SET GITHUB_IO_BOOT=http://peterkir.github.io/idefix/bootstrap/peterkir/win32

::ECHO.
::ECHO # workaroung for NTLMv2 ProxyAuth - starting IE
::ECHO.
::SET IE_CMD="C:\Program Files (x86)\Internet Explorer\iexplore.exe www.google.de"
::SET IE_DIR="%TEMP%"
::FOR /F "tokens=2 delims=;=" %%a IN (
::  'WMIC process call create %IE_CMD%^, %IE_DIR% ^| find "ProcessId"'
::) DO (
::  SET IE_PID=%%a
::)
::ECHO browser launched with PID %IE_PID%
:: TODO search an kill the IE if not previously open WMIC process %IE_PID% delete

SET JAVA=%SCRIPT_PATH%\java

:: source archives location
SET JAVA_WEB=http://www.klib.io/_archives/java

:: concrete version names for the Java Archives
SET JAVA_ARCHIVE=win32.x86_64-jre1.8.0_74.zip

:: Java Name (includes version)
SET JAVA_VERSION=%JAVA_ARCHIVE:~16,-9%
SET JAVA_NAME=%JAVA_ARCHIVE:~13,-4%
SET JAVA_WEB_DL=%JAVA_WEB%/%JAVA_VERSION%/%JAVA_ARCHIVE%
SET JAVA_DL=%DL%\%JAVA_ARCHIVE%

:: extract locations
SET JAVA_EXTRACT=%JAVA%\%JAVA_VERSION%

ECHO.
ECHO # setup local JDK %JAVA_VERSION% in version %JAVA_NAME%
ECHO.
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%JAVA_DL%' ) { Write-Output '   - skipping download,   cause file exists   - %JAVA_DL%' } else { Write-Output '   - downloading archive %JAVA_ARCHIVE%';(New-Object System.Net.WebClient).DownloadFile('%JAVA_WEB_DL%','%JAVA_DL%')}"
IF "%ERRORLEVEL%"=="" (
    ECHO failing downloading file %JAVA_WEB%/%JAVA_ARCHIVE%
    GOTO END
)

powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%JAVA_EXTRACT%\%JAVA_NAME%' -PathType Container )  { Write-Output '   - skipping extraction, cause folder exists - %JAVA_EXTRACT%\%JAVA_NAME%' } else { Write-Output '   - extracting %JAVA_DL% archive to %JAVA_EXTRACT%'; Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%JAVA_DL%', '%JAVA_EXTRACT%')}"

FOR /F %%a IN ('DIR /B %SCRIPT_PATH%\java\1.8') DO SET JAVA=%SCRIPT_PATH%\java\1.8\%%a

ECHO.
ECHO # setup local %IDEFIX_NAME%
ECHO.

:: download of a file with powershell - http://superuser.com/a/423789/344922
powershell -nologo -noprofile -command "%POWERSHELL_TITLE%; (New-Object System.Net.WebClient).DownloadFile('%GITHUB_IO%/%BRANCH%/%GITHUB_IO_LATEST%','%DL%\%BRANCH%_%GITHUB_IO_LATEST%')"
SET /P LATEST=<%DL%\%BRANCH%_%GITHUB_IO_LATEST%
ECHO found latest build ^<%LATEST%^> from %GITHUB_IO%/%BRANCH%/%GITHUB_IO_LATEST%
ECHO.

::SET BINTRAY_BUILD_ROOT=https://dl.bintray.com/peterkir/generic/org.eclipse.oomph/%VERSION%/%BRANCH%/%LATEST%
SET BINTRAY_BUILD_ROOT=http://klib.io/org.eclipse.oomph/%VERSION%/%BRANCH%/%LATEST%

SET ECLIPSE_INSTALLER_WEB=%BINTRAY_BUILD_ROOT%/products
SET ECLIPSE_INSTALLER_ARCHIVE=org.eclipse.oomph.setup.installer.product-win32.win32.x86_64.zip
SET ECLIPSE_INSTALLER=%ECLIPSE_INSTALLER_ARCHIVE:~0,-4%

powershell -nologo -noprofile -command "%POWERSHELL_TITLE%;if ( Test-Path %DL%\%ECLIPSE_INSTALLER_ARCHIVE% ) { Write-Output '   - skipping download, cause file exists - %DL%\%ECLIPSE_INSTALLER_ARCHIVE%' } else { Write-Output '   - downloading archive %ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%';(New-Object System.Net.WebClient).DownloadFile('%ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%','%DL%\%ECLIPSE_INSTALLER_ARCHIVE%')}"
IF "%ERRORLEVEL%"=="" (
    ECHO failing downloading file %ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%
    GOTO END
)

powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%SCRIPT_PATH%\%IDEFIX_NAME%' -PathType Container )  { Write-Output '   - skipping extraction, cause folder exists - %SCRIPT_PATH%\%IDEFIX_NAME%' } else { Write-Output '   - extracting ECLIPSE_INSTALLER archive to %SCRIPT_PATH%\%IDEFIX_NAME%'; Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DL%\%ECLIPSE_INSTALLER_ARCHIVE%', '%SCRIPT_PATH%\%IDEFIX_NAME%')}"

ECHO    - copying latest java %JAVA%\jre into %SCRIPT_PATH%\%IDEFIX_NAME%\jre
IF NOT EXIST %SCRIPT_PATH%\%IDEFIX_NAME%\jre\NUL (
    XCOPY /Y /I /E /H %JAVA% %SCRIPT_PATH%\%IDEFIX_NAME%\jre 2>&1 > NUL
)

SET "IDEFIX_HOME=%SCRIPT_PATH%"
MKDIR %IDEFIX_HOME% 2>&1 > NUL

SET IDEFIX_HOME=%IDEFIX_HOME:\=/%
SET IDEFIX_INI=%SCRIPT_PATH%\%IDEFIX_NAME%\eclipse-inst.ini

FINDSTR peterkir.github.io %IDEFIX_INI% 2>&1 > NUL
IF "%ERRORLEVEL%"=="" (
    ECHO    - skipping vmArgs addition, cause already inside
) ELSE (
    ECHO    - adding vmArgs to ini file
    :: allow installation of unsigned bundles
    ECHO -Declipse.p2.unsignedPolicy=allow >> %IDEFIX_INI%
    
    :: hidden p2 options (configured to default)
    ECHO -Declipse.p2.max.threads=4        >> %IDEFIX_INI%
    ECHO -Declipse.p2.force.threading=true >> %IDEFIX_INI%
    ECHO -Declipse.p2.mirrors=true         >> %IDEFIX_INI%
    
    :: filtering user displayed catalogs/products/versions
    ECHO -Doomph.setup.product.catalog.filter=osgi\.products>> %IDEFIX_INI%
    ECHO -Doomph.setup.product.filter=osgi\.idefix\.mars>> %IDEFIX_INI%
    ECHO -Doomph.setup.product.version.filter=latest\.bndtools\.bintray>> %IDEFIX_INI%
    
    ECHO -Doomph.setup.jre.choice=false                                 >> %IDEFIX_INI%
    ::ECHO -Doomph.installer.update.url=%BINTRAY_BUILD_ROOT%/p2/installer >> %IDEFIX_INI%
    ::ECHO -Doomph.update.url=%BINTRAY_BUILD_ROOT%/p2/oomph               >> %IDEFIX_INI%
    ECHO -Doomph.setup.installer.mode=advanced                          >> %IDEFIX_INI%
    ECHO -Doomph.redirection.klibProductCatalog=index:/redirectable.products.setup-^>https://peterkir.github.io/idefix/oomph/osgi/productsCatalog.setup >> %IDEFIX_INI%
    ECHO -Doomph.redirection.klibProjectCatalog=index:/redirectable.projects.setup-^>https://peterkir.github.io/idefix/oomph/osgi/projectsCatalog.setup >> %IDEFIX_INI%
)

ECHO.
ECHO # launching %IDEFIX_NAME%
ECHO.
START /B %SCRIPT_PATH%\%IDEFIX_NAME%\eclipse-inst.exe

::ECHO.
::ECHO # clean-up
::ECHO.
::RMDIR /Q /S %DL%

:END
