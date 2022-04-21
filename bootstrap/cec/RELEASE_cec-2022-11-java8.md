# Release IDEfix 2022.11 - java 8 - zip version

## Installation on local machine
1. download OS specific version from 

GSEP Artifactory DE - `https://jfrogedc.gsep.daimler.com/artifactory/CEC-SDK-Release-DE/results/idefix/idefix-cec-2022-11-java8-zipped_win32.win32.x86_64.zip/` 
CEC-Build - `\\smtcf02003.rd.corpintra.net\CEC-Build$\release\IDEfix\idefix-cec-2022-11-java8-zipped_win32.win32.x86_64.zip`

2. extract the archive

**Remark:** mind the windows MAX_PATH length restrictions of 260 characters (archive content is already using 207 characters).


3. launch IDEfix from the extracted folder \
   Mind: First startup after extracting is taking quite long

## Workspace setup
After first startup of each workspace it is necessary to configure the Java 8 JDK.

### Adding Java 8 JDK to installed JREs
1. `[Window -> Preferences -> Java -> Installed JREs]`
2. `[Press 'Search' and select your extraction folder]`\
   The Java 8 jdk should be found and added to the 'Installed JREs'.\
3. Press `Apply`.

### Configure Execution Environment for JavaSE-1.8
1. Select the child node `Execution Environment`.\
2. Select `JavaSE-1.8` and check the java 8 jdk e.g. `jdk8u202-b08-jfx`.\
3. Press `Apply and Close`.

Now you are ready to import your repo and start coding.

# Content of Release

## installed IUs

* Eclipse IDE for for Eclipse Committers 2022.03
* Java 11 - jdk-11.0.14.1+1 as Eclipse Runtime java
* bndtools 5.3
* AJDT 2.2.4.202203241552 for Eclipse 4.23
* CheckStyle 9.2
* RCPTT 2.5.1

## preference settings

* org.eclipse.ant.ui
* org.eclipse.core.resources
* org.eclipse.egit.core
* org.eclipse.jdt.core
* org.eclipse.jdt.ui
* org.eclipse.ui.editors
* org.eclipse.ui.ide

## manual additions/modifications

* PAI Java 8 version - jdk8u202-b08-jfx
