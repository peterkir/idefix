@ECHO off

:: ### Prepare the Command Processor
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

:: ### Version History - x.y.z_<timestamp YYYYMMDD-hhmm> Author Description
:: !! For a new version entry, copy the last entry down and modify Date, Author and Description
SET version=1.0.0_20151210-1042 &: Peter Kirschner   initial version of the script

SET version=%version: =%
SET title=%~nx0 - version %version%
TITLE %title%

:: ### default variables
SET prgPath=%~dp0
SET prgPath=%prgPath:~0,-1%

SET DL=%prgPath%\.download

SET DOWNLOAD=^
	%DL%\org.eclipse.oomph.setup.installer.product-*^
	%DL%\setupJavaSDK.cmd^
	master_latest

SET EXECUTABLE=^
	%prgPath%\org.eclipse.oomph.setup.installer.product-win32.win32.x86_64\*^
	%prgPath%\.eclipse^
	%prgPath%\engage*

::	%prgPath%\.p2

SET INSTALLED_ARTIFACTS=^
	%prgPath%\idefixInstaller^
	%prgPath%\install^
	%prgPath%\wrkspc^
    %prgPath%\oomph

SET LOCAL_OOMPH_PREFS=^
	%USERPROFILE%\.eclipse\org.eclipse.oomph.setup.installer^
	%USERPROFILE%\.eclipse\org.eclipse.oomph.jreinfo^
	%USERPROFILE%\.eclipse\org.eclipse.oomph.p2^
	%USERPROFILE%\.eclipse\org.eclipse.oomph.setup^
	%prgPath%\org.eclipse.oomph.setup.installer.product-win32.win32.x86_64\configuration\org.eclipse.core.runtime^
	%prgPath%\org.eclipse.oomph.setup.installer.product-win32.win32.x86_64\configuration\org.eclipse.equinox.app^
	%prgPath%\org.eclipse.oomph.setup.installer.product-win32.win32.x86_64\configuration\org.eclipse.equinox.launcher^
	%prgPath%\org.eclipse.oomph.setup.installer.product-win32.win32.x86_64\configuration\org.eclipse.osgi

SET "DELETE_PATTERNS=%DOWNLOAD% %EXECUTABLE% %INSTALLED_ARTIFACTS% %LOCAL_OOMPH_PREFS%"

ECHO.
ECHO # start cleaning
ECHO.

ECHO # delete all patterns for directories
ECHO.
FOR %%d IN (%DELETE_PATTERNS%) DO ECHO execute RMDIR /Q /S "%%d" & RMDIR /Q /S "%%d" > NUL 2>&1

ECHO # delete all patterns for files
ECHO.
FOR %%f IN (%DELETE_PATTERNS%) DO ECHO execute DEL /Q /S /F "%%f" & DEL /Q /S /F "%%f" > NUL 2>&1

ECHO cleanup completed