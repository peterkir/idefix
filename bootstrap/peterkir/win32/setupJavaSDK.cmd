:: this script will use defaults if no parameter is given.
:: available paramters are
:: 1. <full_windows_path> as root install location
:: 2. Java version to install (csv 5,6,7,8)

@ECHO off
SETLOCAL EnableExtensions
SETLOCAL EnableDelayedExpansion

:: ### Version History -- X.Y.Z_YYYYMMDD-hhmm Author Description
SET version=1.0.0_20160307 &: Peter Kirschner   downloading,extract,configure latest Java SDK 
SET version=%version: =%
SET title=Java SDK setup script %~nx0 - version %version%
TITLE %title%
SET POWERSHELL_TITLE=$Host.UI.RawUI.WindowTitle='%title%'

:: source archives location
SET JAVA_WEB=http://www.klib.io/_archives/java

:: concrete version names for the Java Archives
SET JAVA5_ARCHIVE=win32.x86_64-jdk1.5.0_22.zip
SET JAVA6_ARCHIVE=win32.x86_64-jdk1.6.0_45.zip
SET JAVA7_ARCHIVE=win32.x86_64-jdk1.7.0_75.zip
SET JAVA8_ARCHIVE=win32.x86_64-jdk1.8.0_74.zip


:: ###########################################################
SET SCRIPTNAME=%~n0
SET SCRIPT_PATH=%~dp0
SET SCRIPT_PATH=%SCRIPT_PATH:~0,-1%

:: local Java storage root path
IF "%1"=="" (
	SET JAVA=%SCRIPT_PATH%\java
	ECHO using default Java root in !JAVA!
) ELSE (
	SET JAVA=%1\java
	ECHO using Java root in !JAVA!
)

:: these are configuration parameter
IF "%2" == "" (
	SET JAVA_VERSIONS=5,6,7,8
) ELSE (
	SET JAVA_VERSIONS=%2
)
ECHO.
ECHO installing java version %JAVA_VERSIONS%

SET DL=%SCRIPT_PATH%\.download
:: folder must exists for powershell download requests
MKDIR %DL% 1> NUL 2>&1

FOR %%a IN (%JAVA_VERSIONS%) DO (
	SET CURR_JAVA=JAVA%%a_ARCHIVE
	CALL :downloadAndExtract !CURR_JAVA!
)

GOTO :END

:downloadAndExtract

:: processing with the value of the passed parameter
SET JAVA_ARCHIVE=!%~1!

:: Java Name (includes version)
SET JAVA_VERSION=%JAVA_ARCHIVE:~16,-9%

:: Java Major.Minor Version 
SET JAVA_NAME=%JAVA_ARCHIVE:~13,-4%

:: web download URLs
SET JAVA_WEB_DL=%JAVA_WEB%/%JAVA_VERSION%/%JAVA_ARCHIVE%

:: download locations
SET JAVA_DL=%DL%\%JAVA_ARCHIVE%

:: extract locations
SET JAVA_EXTRACT=%JAVA%\%JAVA_VERSION%

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
ECHO # setup local JDK %JAVA_VERSION% in version %JAVA_NAME%
ECHO.
powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%JAVA_DL%' ) { Write-Output '   - skipping download,   cause file exists   - %JAVA_DL%' } else { Write-Output '   - downloading archive %JAVA_ARCHIVE%';$browser = New-Object System.Net.WebClient; $browser.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials; $browser.DownloadFile('%JAVA_WEB_DL%','%JAVA_DL%')}"
IF "%ERRORLEVEL%"=="" (
	ECHO failing downloading file %JAVA_WEB%/%JAVA_ARCHIVE%
	GOTO END
)

powershell -nologo -noprofile  -command "%POWERSHELL_TITLE%;if ( Test-Path '%JAVA_EXTRACT%\%JAVA_NAME%' -PathType Container )  { Write-Output '   - skipping extraction, cause folder exists - %JAVA_EXTRACT%\%JAVA_NAME%' } else { Write-Output '   - extracting %JAVA_DL% archive to %JAVA_EXTRACT%'; Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%JAVA_DL%', '%JAVA_EXTRACT%')}"

GOTO :EOF

:END
ECHO.
ECHO done
