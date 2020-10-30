package io.klib.eclipse.p2;

import java.text.MessageFormat;

import org.eclipse.core.runtime.IStatus;
import org.eclipse.equinox.internal.p2.director.app.DirectorApplication;
import org.eclipse.equinox.internal.p2.director.app.ILog;

public class P2DirectorWrapper extends DirectorApplication {

    private final DirectorApplication directorApp;

    public P2DirectorWrapper() {
        directorApp = new DirectorApplication();
        directorApp.setLog(new ILog() {

            @Override
            public void log(final String message) {
                System.out.println(message);
            }

            @Override
            public void log(final IStatus status) {
                System.out.println(status.getMessage());
            }

            @Override
            public void close() {
                // nothing to do
            }
        });
    }

    public void install(final String repoURIs,
                        final String installIUs,
                        final String destination,
                        final String profile,
                        final String p2os,
                        final String p2ws,
                        final String p2arch) {

        // store launchTime for duration calculation
        long launchTime = System.nanoTime();

        // prepare launch arguments
        // @formatter:off
		String[] args = new String[] {
				// ,"-help" , ""
				// ,"-list" , ""
				// ,"-listInstalledRoots" , ""
				"-installIU", installIUs
				// ,"-uninstallIU" , ""
				// ,"-revert" , ""
				, "-destination", destination
				// ,"-metadatarepository" , ""
				// ,"-artifactrepository" , ""
				, "-repository", repoURIs
				// ,"-verifyOnly" , ""
				, "-profile", profile
				, "-flavor", "tooling"
				// ,"-shared" , "true"
				// ,"-bundlepool" , ""
				// ,"-iuProfileproperties" , ""
				, "-profileproperties"
				, "org.eclipse.update.install.features=true"
				, "-roaming"
				, "-p2.os", p2os
				, "-p2.ws", p2ws
				, "-p2.arch", p2arch
				// ,"-p2.nl" , ""
				, "-purgeHistory"
		// ,"-followReferences"
		// ,"-tag" , ""
		// ,"-listTags" , ""
		// ,"-downloadOnly" , ""
		// ,"-showLocation" , ""
		};
		// @formatter:on

        // actual p2.director call
        try {
/*
        	for (String arg: args) {
                System.out.println(arg);
            }
*/
            directorApp.run(args);
        }
        catch (Exception e) {
            e.printStackTrace();
        }
        long installationTime = System.nanoTime() - launchTime;
        System.out.println(MessageFormat.format("execution of p2 director took ms", installationTime * 1000));
    }

}
