### default variables

prgPath=$0
DOWNLOAD=${prgPath}/download

EXECUTABLE= \
	${prgPath}/org.eclipse.oomph.setup.installer.product-macosx.cocoa.x86_64/* \
	${prgPath}/.eclipse

#	${prgPath}/.p2
	
INSTALLED_ARTIFACTS= \
	${prgPath}/oomphInstaller \
	${prgPath}/install \
	${prgPath}/wrkspc \
    ${prgPath}/oomph

LOCAL_OOMPH_PREFS= \
	~/.eclipse/org.eclipse.oomph.setup.installer \
	~/.eclipse/org.eclipse.oomph.jreinfo \
	~/.eclipse/org.eclipse.oomph.p2 \
	~/.eclipse/org.eclipse.oomph.setup \
	${prgPath}/org.eclipse.oomph.setup.installer.product-win32.win32.x86_64/configuration/org.eclipse.core.runtime \
	${prgPath}/org.eclipse.oomph.setup.installer.product-win32.win32.x86_64/configuration/org.eclipse.equinox.app \
	${prgPath}/org.eclipse.oomph.setup.installer.product-win32.win32.x86_64/configuration/org.eclipse.equinox.launcher \
	${prgPath}/org.eclipse.oomph.setup.installer.product-win32.win32.x86_64/configuration/org.eclipse.osgi

DELETE_PATTERNS=${DOWNLOAD} ${EXECUTABLE} ${INSTALLED_ARTIFACTS} ${LOCAL_OOMPH_PREFS}

echo
echo # start cleaning
echo

echo # delete all patterns for directories
echo
for i in $INSTALLED_ARTIFACTS; do
	echo $i
done
#FOR %%d IN (%DELETE_PATTERNS%) DO echo execute RMDIR /Q /S "%%d" & RMDIR /Q /S "%%d" > NUL 2>&1

echo # delete all patterns for files
echo

#FOR %%f IN (%DELETE_PATTERNS%) DO echo execute DEL /Q /S /F "%%f" & DEL /Q /S /F "%%f" > NUL 2>&1
for i in $DELETE_PATTERNS; do
	echo $i
done

echo cleanup completed