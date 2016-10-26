@ECHO off
SETLOCAL EnableExtensions
SETLOCAL EnableDelayedExpansion

SET version=1.0.0_20160616-0600
SET title=idefixInstaller script %~nx0 - version %version%
TITLE %title%
SET POWERSHELL_TITLE=$Host.UI.RawUI.WindowTitle='%title%'

SET JAVA_WEB=http://www.klib.io/_archives/java/1.8
SET JAVA_ARCHIVE=win32.x86_64-jre1.8.0_74.zip
SET JAVA=%JAVA_ARCHIVE:~13,-4%

:: ###########################################################
SET SCRIPTNAME=%~n0
SET SCRIPT_PATH=%~dp0
SET SCRIPT_PATH=%SCRIPT_PATH:~0,-1%

SET ECL_INST_NAME=idefixInstaller
SET DL=%SCRIPT_PATH%\.download
:: folder must exists for powershell download requests
MKDIR %DL% 2>&1 > NUL

SET GITHUB_IO_BOOT=http://peterkir.github.io/idefix/bootstrap/peterkir/win32

SET BUILD_SERVER_ROOT=https://dl.bintray.com/peterkir/generic/org.eclipse.oomph
::SET BUILD_SERVER_ROOT=http://www.klib.io/org.eclipse.oomph
SET OOMPH_VERSION=1.6.0

SET PROD_CAT_FILTER=io\\.klib\\.products
SET PROD_FILTER=osgi\\.idefix\\.neon
SET PROD_VERSION=osgi\\.idefix\\.neon\\.bndtools\\.3\\.3\\.0

SET productSetup=http://peterkir.github.io/idefix/bootstrap/peterkir/catalogProducts.setup
SET projectSetup=http://peterkir.github.io/idefix/bootstrap/peterkir/catalogProjects.setup

SET INSTALLER_UPDATE_URL=http://www.klib.io/org.eclipse.oomph/%OOMPH_VERSION%/installer
SET UPDATE_URL=http://www.klib.io/org.eclipse.oomph/%OOMPH_VERSION%/product

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

SET JAVA_CMD=setupJavaSDK.cmd
ECHO.
ECHO # downloading and configuring Java via %GITHUB_IO_BOOT%/%JAVA_CMD%
ECHO.
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path %DL%\%JAVA_CMD% ) { Write-Output 'skipping download, cause file exists - %DL%\%JAVA_CMD%' } else {(New-Object System.Net.WebClient).DownloadFile('%GITHUB_IO_BOOT%/%JAVA_CMD%','%DL%\%JAVA_CMD%')}"
IF "%ERRORLEVEL%"=="" (
    ECHO failing downloading file %GITHUB_IO_BOOT%/%JAVA_CMD%
    GOTO END
)

:: installing JDKs into %SCRIPT_PATH%/java
CALL %DL%\%JAVA_CMD% %SCRIPT_PATH%

FOR /F %%a IN ('DIR /B %SCRIPT_PATH%\java\1.8') DO SET JAVA8=%SCRIPT_PATH%\java\1.8\%%a

ECHO.
ECHO # download and extract into %SCRIPT_PATH%\%ECL_INST_NAME%
ECHO.

SET ECLIPSE_INSTALLER_WEB=%BUILD_SERVER_ROOT%/%OOMPH_VERSION%
SET ECLIPSE_INSTALLER_ARCHIVE=org.eclipse.oomph.setup.installer.product-win32.win32.x86_64.zip
SET ECLIPSE_INSTALLER=%ECLIPSE_INSTALLER_ARCHIVE:~0,-4%

powershell -nologo -noprofile -command "%POWERSHELL_TITLE%;if ( Test-Path %DL%\%ECLIPSE_INSTALLER_ARCHIVE% ) { Write-Output '   - skipping download, cause file exists - %DL%\%ECLIPSE_INSTALLER_ARCHIVE%' } else { Write-Output '   - downloading archive %ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%';$browser = New-Object System.Net.WebClient; $browser.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials; $browser.DownloadFile('%ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%','%DL%\%ECLIPSE_INSTALLER_ARCHIVE%')}"
IF "%ERRORLEVEL%"=="" (
    ECHO failing downloading file %ECLIPSE_INSTALLER_WEB%/%ECLIPSE_INSTALLER_ARCHIVE%
    GOTO END
)

powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%SCRIPT_PATH%\%ECL_INST_NAME%' -PathType Container )  { Write-Output '   - skipping extraction, cause folder exists - %SCRIPT_PATH%\%ECL_INST_NAME%' } else { Write-Output '   - extracting ECLIPSE_INSTALLER archive to %SCRIPT_PATH%\%ECL_INST_NAME%'; Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DL%\%ECLIPSE_INSTALLER_ARCHIVE%', '%SCRIPT_PATH%\%ECL_INST_NAME%')}"

ECHO    - copying latest java %JAVA8%\jre into %SCRIPT_PATH%\%ECL_INST_NAME%\jre
IF NOT EXIST %SCRIPT_PATH%\%ECL_INST_NAME%\jre\NUL (
    XCOPY /Y /I /E /H %JAVA8%\jre %SCRIPT_PATH%\%ECL_INST_NAME%\jre 2>&1 > NUL
)

SET ECL_INST_INI=%SCRIPT_PATH%\%ECL_INST_NAME%\eclipse-inst.ini

FINDSTR peterkir.github.io %ECL_INST_INI% 2>&1 > NUL
IF "%ERRORLEVEL%"=="" (
    ECHO    - skipping vmArgs addition, cause already inside
) ELSE (
    ECHO    - adding vmArgs to ini file
    :: allow installation of unsigned bundles
    ECHO -Declipse.p2.unsignedPolicy=allow >> %ECL_INST_INI%

    :: hidden p2 options (configured to default)
    ECHO -Declipse.p2.max.threads=4        >> %ECL_INST_INI%
    ECHO -Declipse.p2.force.threading=true >> %ECL_INST_INI%
    ECHO -Declipse.p2.mirrors=true         >> %ECL_INST_INI%

    :: filtering user displayed catalogs/products/versions
    ECHO -Doomph.setup.product.catalog.filter=%PROD_CAT_FILTER%>> %ECL_INST_INI%
    ECHO -Doomph.setup.product.filter=%PROD_FILTER%>>             %ECL_INST_INI%
    ECHO -Doomph.setup.product.version.filter=%PROD_VERSION%>>    %ECL_INST_INI%

    ECHO -Doomph.setup.jre.choice=false                          >> %ECL_INST_INI%
    ECHO -Doomph.installer.update.url=%INSTALLER_UPDATE_URL%    >> %ECL_INST_INI%
    ECHO -Doomph.update.url=%UPDATE_URL%                         >> %ECL_INST_INI%
    ECHO -Doomph.setup.installer.mode=advanced                   >> %ECL_INST_INI%
    ECHO -Doomph.redirection.klibProductCatalog=index:/redirectable.products.setup-^>%productSetup% >> %ECL_INST_INI%
    ECHO -Doomph.redirection.klibProjectCatalog=index:/redirectable.projects.setup-^>%projectSetup% >> %ECL_INST_INI%
)

ECHO.
ECHO # launching %ECL_INST_NAME%
ECHO.
START /B %SCRIPT_PATH%\%ECL_INST_NAME%\eclipse-inst.exe

::ECHO.
::ECHO # clean-up
::ECHO.
::RMDIR /Q /S %DL%

:END