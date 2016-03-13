#!/bin/bash
echo -e "\n###------------------------------------------------------------------------------"
echo "# oomphInstaller "
echo "###------------------------------------------------------------------------------"

SCRIPT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

GITHUB_IO=http://peterkir.github.io/org.eclipse.oomph
GITHUB_IO_LATEST=latest
BRANCH=peterkir
LATEST_URL=$GITHUB_IO/$BRANCH/$GITHUB_IO_LATEST

OOMPH_NAME=oomphInstaller
DOWNLOAD_LOCATION=$SCRIPT_PATH/download
mkdir $DOWNLOAD_LOCATION > /dev/null 2>&1
pushd $DOWNLOAD_LOCATION > /dev/null 2>&1

echo "###"
echo "# retrieving latest build from $LATEST_URL"
echo "###"
LATEST=`curl -L -\# -O $LATEST_URL && cat $DOWNLOAD_LOCATION/$GITHUB_IO_LATEST`
BINTRAY_BUILD_ROOT=https://dl.bintray.com/peterkir/generic/org.eclipse.oomph/1.3.0/$BRANCH/$LATEST

ECLIPSE_INSTALLER_WEB=$BINTRAY_BUILD_ROOT/products
ECLIPSE_INSTALLER_ARCHIVE=org.eclipse.oomph.setup.installer.product-macosx.cocoa.x86_64.zip
ECLIPSE_INSTALLER=${ECLIPSE_INSTALLER_ARCHIVE%.zip}
echo -e "\n###------------------------------------------------------------------------------"
echo "# downloading and preparing $ECLIPSE_INSTALLER"
echo "###------------------------------------------------------------------------------"

if [ -e $DOWNLOAD_LOCATION/$ECLIPSE_INSTALLER_ARCHIVE ]
then
   echo "skipping download - file already exists"
else
   echo "downloading archive $ECLIPSE_INSTALLER_WEB/$ECLIPSE_INSTALLER_ARCHIVE"
   curl -L -\# -O $ECLIPSE_INSTALLER_WEB/$ECLIPSE_INSTALLER_ARCHIVE
fi

OOMPH_LOC=$SCRIPT_PATH/Eclipse\ Installer.app
OOMPH_ECLIPSE_LOC=$OOMPH_LOC/Contents/Eclipse

echo extracting ECLIPSE_INSTALLER archive to $OOMPH_LOC
if [ -e "$OOMPH_LOC" ]
then
   echo "skipping unzipping "$OOMPH_LOC" - folder already exists"
else
   unzip -d $SCRIPT_PATH $DOWNLOAD_LOCATION/$ECLIPSE_INSTALLER_ARCHIVE \
   >  ${ECLIPSE_INSTALLER}_unzip_stdout.log \
   2> ${ECLIPSE_INSTALLER}_unzip_stderr.log
fi

JAVA_WEB=https://s3-eu-west-1.amazonaws.com/klib.io/www/_archives/java/zipped/1.8
JAVA_ARCHIVE=macosx.x86_64-jre1.8.0_66.zip
JAVA=${JAVA_ARCHIVE%.zip}
echo -e "\n###------------------------------------------------------------------------------"
echo "# downloading and preparing jre $JAVA"
echo "###------------------------------------------------------------------------------"

if [ -e $JAVA_ARCHIVE ]
then
   echo "skipping download - file $JAVA_ARCHIVE already exists"
else
   echo "downloading java archive $JAVA_WEB/$JAVA_ARCHIVE"
   curl -L -\# -O $JAVA_WEB/$JAVA_ARCHIVE
fi

echo "extracting $JAVA archive to $OOMPH_ECLIPSE_LOC/jre"
if [ -e "$OOMPH_ECLIPSE_LOC/jre" ]
then
   echo 'skipping jre preparation - folder already exists'
else
   unzip -d $DOWNLOAD_LOCATION $DOWNLOAD_LOCATION/$JAVA_ARCHIVE \
   >  ${JAVA_ARCHIVE}_unzip_stdout.log \
   2> ${JAVA_ARCHIVE}_unzip_stderr.log

   mv "$DOWNLOAD_LOCATION/$JAVA" "$OOMPH_ECLIPSE_LOC/jre"
fi

JAVA_HOME=$OOMPH_ECLIPSE_LOC/jre
OOMPH_HOME=$SCRIPT_PATH/oomph
P2_HOME=$SCRIPT_PATH/p2

echo "###------------------------------------------------------------------------------"
echo '# configuring oomph installer'
echo "###------------------------------------------------------------------------------"
OOMPH_HOME=$SCRIPT_PATH/oomph
OOMPH_ECLIPSE_INI=$OOMPH_ECLIPSE_LOC/eclipse-inst.ini

mkdir ${OOMPH_HOME} > /dev/null 2>&1

JVM=`echo -vm'\n'$JAVA_HOME/bin'\n'-vmargs`
sed -i 's/-vmargs/${JVM}/' ${OOMPH_ECLIPSE_INI}

echo adding vmArgs to ini file

# custom added parameters
echo "-Doomph.home=$OOMPH_HOME"          >> "$OOMPH_ECLIPSE_INI"
echo "-Doomph.p2.agent.path=$P2_HOME"    >> "$OOMPH_ECLIPSE_INI"

# allow installation of unsigned bundles
echo "-Declipse.p2.unsignedPolicy=allow" >> "$OOMPH_ECLIPSE_INI"

# hidden p2 options (configured to default)
echo "-Declipse.p2.max.threads=4"        >> "$OOMPH_ECLIPSE_INI"
echo "-Declipse.p2.force.threading=true" >> "$OOMPH_ECLIPSE_INI"
echo "-Declipse.p2.mirrors=true"         >> "$OOMPH_ECLIPSE_INI"

# filtering user displayed catalogs/products/versions
echo "-Doomph.setup.product.catalog.filter=io.klib.products" >> "$OOMPH_ECLIPSE_INI"
echo "-Doomph.setup.product.filter=idefix.cec"               >> "$OOMPH_ECLIPSE_INI"
echo "-Doomph.setup.product.version.filter=161.slim"         >> "$OOMPH_ECLIPSE_INI"

echo "-Doomph.setup.jre.choice=false"                                 >> "$OOMPH_ECLIPSE_INI"
echo "-Doomph.installer.update.url=$BINTRAY_BUILD_ROOT/p2/installer"  >> "$OOMPH_ECLIPSE_INI"
echo "-Doomph.update.url=$BINTRAY_BUILD_ROOT/p2/oomph"                >> "$OOMPH_ECLIPSE_INI"
echo "-Doomph.setup.installer.mode=advanced"                          >> "$OOMPH_ECLIPSE_INI"
echo "-Doomph.redirection.idefixProductCatalog=index:/redirectable.products.setup->http://peterkir.github.io/idefix/oomph/products/productsCatalog.setup" >> "$OOMPH_ECLIPSE_INI"
echo "-Doomph.redirection.idefixProjectCatalog=index:/redirectable.projects.setup->http://peterkir.github.io/idefix/oomph/projects/projectsCatalog.setup" >> "$OOMPH_ECLIPSE_INI"

#INSTALL_ROOT=$SCRIPT_PATH/install
#mkdir ${INSTALL_ROOT} > /dev/null 2>&1
#echo "-Dinstall.root=$INSTALL_ROOT" >> "$OOMPH_ECLIPSE_INI"

#WRKSPC_ROOT=$SCRIPT_PATH/wrkspc
#mkdir ${WRKSPC_ROOT} > /dev/null 2>&1
#echo "-Dworkspace.container.root=$WRKSPC_ROOT" >> "$OOMPH_ECLIPSE_INI"

echo "###------------------------------------------------------------------------------"
echo "# launching oomph app"
echo "###------------------------------------------------------------------------------"

echo "open $SCRIPT_PATH/Eclipse\ Installer.app"
open "$SCRIPT_PATH/Eclipse Installer.app"

popd > /dev/null 2>&1

echo -e "\ndone - look for the eclipse installer application window"
