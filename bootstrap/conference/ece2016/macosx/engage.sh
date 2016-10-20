#!/bin/bash
echo -e "\n###------------------------------------------------------------------------------"
echo "# Eclipse Installer "
echo "###------------------------------------------------------------------------------"

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DL="$SCRIPT_PATH/download"
echo "creating download folder $DL"
mkdir $DL > /dev/null 2>&1
pushd $DL > /dev/null 2>&1

ECL_INST_ARCHIVE=eclipse-inst-mac64.tar.gz
ECL_INST_WEB="http://www.eclipse.org/downloads/download.php?file=/oomph/products/${ECL_INST_ARCHIVE}&r=1"
ECL_INST_APP=Eclipse\ Installer.app
ECL_INST=eclipseInstaller

CUSTOM=public/ece2016
PROD_CAT_FILTER=ece2016\\.products
PROD_FILTER=osgi\\.idefix\\.oyygen
PROD_VERSION=osgi\\.idefix\\.oyygen\\.bndtools\\.3\\.3\\.0

echo -e "\n###------------------------------------------------------------------------------"
echo "# downloading and preparing $ECL_INST_APP"
echo "###------------------------------------------------------------------------------"

if [ -e $DL/$ECL_INST_ARCHIVE ]
then
   echo "   - skipping download - file already exists"
else
   echo "   - downloading archive $ECL_INST_WEB"
   curl -L -\# -o $DL/$ECL_INST_ARCHIVE ${ECL_INST_WEB}
fi

ECL_INST_LOC=$SCRIPT_PATH/$ECL_INST_APP
ECL_INST_ECLIPSE_LOC=$ECL_INST_LOC/Contents/Eclipse

if [ -e "$ECL_INST_LOC" ]
then
   echo "   - skipping unzipping "$ECL_INST_LOC" - folder already exists"
else
   echo "   - extracting $DL/$ECL_INST_ARCHIVE to $ECL_INST_LOC"
   tar -xzf $DL/$ECL_INST_ARCHIVE -C $SCRIPT_PATH \
   >  ${ECL_INST}_unzip_stdout.log \
   2> ${ECL_INST}_unzip_stderr.log
fi

#JAVA_WEB=https://s3-eu-west-1.amazonaws.com/klib.io/www/_archives/java/zipped/1.8
JAVA_WEB=http://www.klib.io/_archives/java/1.8
JAVA_ARCHIVE=macosx.x86_64-jre1.8.0_66.zip
JAVA=${JAVA_ARCHIVE:0:25}
echo -e "\n###------------------------------------------------------------------------------"
echo "# downloading and preparing Java $JAVA"
echo "###------------------------------------------------------------------------------"

if [ -e $JAVA_ARCHIVE ]
then
   echo "   - skipping download - file $JAVA_ARCHIVE already exists"
else
   echo "   - downloading java archive $JAVA_WEB/$JAVA_ARCHIVE"
   curl -L -\# -O $JAVA_WEB/$JAVA_ARCHIVE
fi

if [ -d "$DL/$JAVA" ]
then
   echo "   - skipping extraction - already existing folder $DL/$JAVA"
else
   echo "   - extracting archive $JAVA_ARCHIVE to $ECL_INST_ECLIPSE_LOC/jre"
   unzip -d $DL $DL/$JAVA_ARCHIVE \
   >  ${JAVA_ARCHIVE}_unzip_stdout.log \
   2> ${JAVA_ARCHIVE}_unzip_stderr.log
fi

if [ -d "$ECL_INST_ECLIPSE_LOC/jre" ]
then
   echo "   - skipping jre preparation - already existing folder $ECL_INST_ECLIPSE_LOC/jre"
else
   echo "   - copy JRE to $ECL_INST_ECLIPSE_LOC/jre"
   cp -r  "$DL/$JAVA" "$ECL_INST_ECLIPSE_LOC/jre"
fi

JAVA_HOME=$ECL_INST_ECLIPSE_LOC/jre

echo "###------------------------------------------------------------------------------"
echo '# configuring Eclipse Installer'
echo "###------------------------------------------------------------------------------"

ECL_INST_INI=$ECL_INST_ECLIPSE_LOC/eclipse-inst.ini

if grep -q peterkir.github.io "$ECL_INST_INI"; then
   echo "skipping vmArgs cause already contained"
else
   ECL_INST_INI_ORG=$DL/eclipse-inst_ORIGINAL.ini
   ECL_INST_INI_BAK=$DL/eclipse-inst.ini

   cp -f "$ECL_INST_INI" "$ECL_INST_INI_ORG"
   cp -f "$ECL_INST_INI" "$ECL_INST_INI_BAK"

   #JVM=`echo -vm'\n'$JAVA_HOME/bin'\n'-vmargs`
   #sed -i 's/-vmargs/${JVM}/' "${ECL_INST_INI}"

   echo adding vmArgs to ini file

   # allow installation of unsigned bundles
   echo "-Declipse.p2.unsignedPolicy=allow" >> "$ECL_INST_INI_BAK"

   # hidden p2 options (configured to default)
   echo "-Declipse.p2.max.threads=4"        >> "$ECL_INST_INI_BAK"
   echo "-Declipse.p2.force.threading=true" >> "$ECL_INST_INI_BAK"
   echo "-Declipse.p2.mirrors=true"         >> "$ECL_INST_INI_BAK"

   # filtering user displayed catalogs/products/versions
   echo "-Doomph.setup.product.catalog.filter=${PROD_CAT_FILTER}"  >> "$ECL_INST_INI_BAK"
   echo "-Doomph.setup.product.filter=${PROD_FILTER}"              >> "$ECL_INST_INI_BAK"
   echo "-Doomph.setup.product.version.filter=${PROD_VERSION}"     >> "$ECL_INST_INI_BAK"

   echo "-Doomph.setup.jre.choice=false"                           >> "$ECL_INST_INI_BAK"
   echo "-Doomph.setup.installer.mode=advanced"                    >> "$ECL_INST_INI_BAK"
   echo "-Doomph.redirection.idefixProductCatalog=index:/redirectable.products.setup->http://peterkir.github.io/idefix/oomph/${CUSTOM}/catalogProducts.setup" >> "$ECL_INST_INI_BAK"
   echo "-Doomph.redirection.idefixProjectCatalog=index:/redirectable.projects.setup->http://peterkir.github.io/idefix/oomph/${CUSTOM}/catalogProjects.setup" >> "$ECL_INST_INI_BAK"

   #INSTALL_ROOT=$SCRIPT_PATH/install
   #mkdir ${INSTALL_ROOT} > /dev/null 2>&1
   #echo "-Dinstall.root=$INSTALL_ROOT" >> "$ECL_INST_INI_BAK"

   #WRKSPC_ROOT=$SCRIPT_PATH/wrkspc
   #mkdir ${WRKSPC_ROOT} > /dev/null 2>&1
   #echo "-Dworkspace.container.root=$WRKSPC_ROOT" >> "$ECL_INST_INI_BAK"

   cp -f "$ECL_INST_INI_BAK" "$ECL_INST_INI"
fi

echo "###------------------------------------------------------------------------------"
echo "# launching Eclipse Installer"
echo "###------------------------------------------------------------------------------"
echo "open $SCRIPT_PATH/Eclipse\ Installer.app"
open "$SCRIPT_PATH/Eclipse Installer.app"

popd > /dev/null 2>&1

echo -e "\ndone - look for the eclipse installer application window"
