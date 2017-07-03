package io.klip.prepare.eclipseinstaller;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URL;
import java.nio.channels.Channels;
import java.nio.channels.FileChannel;
import java.nio.channels.ReadableByteChannel;
import java.nio.file.FileSystem;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.StringJoiner;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import java.util.stream.Collectors;

import org.eclipse.oomph.extractor.lib.BINExtractor;
import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;

@Component
public class EclipseInstallerPatchINI {

	private static final String ECLIPSE_INST_INI = "eclipse-inst.ini";

	private static final String EXTRACTOR_EXE = "extractor.exe";
	private static final String EXTRACTOR_LIB = "extractorlib.jar";
	private static final String DESCRIPTOR = "product-descriptor";
	private static final String PRODUCT = "product.zip";
	private static final String MARKER = "marker.txt";

	private static final String SEP = File.separator;

	private static final String DL_PROD = "http://www.eclipse.org/downloads/download.php?file=/oomph/products";
	private static final String DL_NIGHTLY = "http://www.eclipse.org/downloads/download.php?file=/oomph/products/latest";

	//@formatter:off
	private static final String DIR       = System.getProperty("user.dir");
	private static final String wrkDir    = DIR + SEP + "_wrk";
	private static final String resultRootDir = DIR + SEP + "_result" + SEP + "eclipseInstaller_" + LocalDate.now() ; 
	
	HashMap<String, String[]> iniSuffix = new LinkedHashMap<String, String[]>();
	
	public EclipseInstallerPatchINI() {
		iniSuffix.put("peterkir", new String[]{ 
			"-Doomph.setup.installer.mode=advanced",
			"-Doomph.setup.installer.p2pool=C:/oomph/.p2",
			"-Doomph.setup.installer.launch=true",
			"-Doomph.redirection.idefixProductCatalog=index:/redirectable.products.setup->http://peterkir.github.io/idefix/bootstrap/peterkir/catalogProducts.setup",
			"-Doomph.redirection.idefixProjectCatalog=index:/redirectable.projects.setup->http://peterkir.github.io/idefix/bootstrap/peterkir/catalogProjects.setup",
			"-Doomph.setup.product.catalog.filter=io\\\\.klib\\\\.products",
			"-Doomph.setup.product.filter=(?\\!io\\\\.klib\\\\.products\\\\.idefix\\\\.oxygen).*",
			"-Doomph.setup.product.version.filter=.*\\\\.latest\\\\.cloudbees"
		});
		iniSuffix.put("daimler.cec", new String[]{ 
			"-Doomph.setup.installer.mode=advanced",
			"-Doomph.setup.installer.p2pooll=C:/oomph/.p2",
			"-Doomph.setup.installer.launch=true",
			"-Doomph.redirection.idefixProductCatalog=index:/redirectable.products.setup->http://peterkir.github.io/idefix/bootstrap/daimler/catalogProducts.setup",
			"-Doomph.redirection.idefixProjectCatalog=index:/redirectable.projects.setup->http://peterkir.github.io/idefix/bootstrap/daimler/catalogProjects.setup",
			"-Doomph.setup.product.catalog.filter=com\\\\.daimler\\\\.products",
			"-Doomph.setup.product.filter=(?\\!com\\\\.daimler\\\\.products\\\\.idefix\\\\.daimler).*",
			"-Doomph.setup.product.version.filter=.*\\\\.developer"
		});
		iniSuffix.put("daimler.duke", new String[]{ 
			"-Doomph.setup.installer.mode=advanced",
			"-Doomph.setup.installer.p2pool=C:/oomph/.p2",
			"-Doomph.setup.installer.launch=true",
			"-Doomph.redirection.idefixProductCatalog=index:/redirectable.products.setup->http://peterkir.github.io/idefix/bootstrap/daimler/catalogProducts.setup",
			"-Doomph.redirection.idefixProjectCatalog=index:/redirectable.projects.setup->http://peterkir.github.io/idefix/bootstrap/daimler/catalogProjects.setup",
			"-Doomph.setup.product.catalog.filter=com\\\\.daimler\\\\.products",
			"-Doomph.setup.product.filter=(?\\!com\\\\.daimler\\\\.products\\\\.idefix\\\\.daimler).*",
			"-Doomph.setup.product.version.filter=.*\\\\.duke"
		});
	};
	
	String[][] archives = { 
		{ "prod.win32.x86-64"   , DL_PROD,    "eclipse-inst-win64.exe", "&r=1" , "eclipse-inst-prod.win32.x86-64.exe"},
		{ "prod.win32.x86"      , DL_PROD,    "eclipse-inst-win32.exe", "&r=1" , "eclipse-inst-prod.win32.x86.exe"}, 
		{ "nightly.win32.x86-64", DL_NIGHTLY, "eclipse-inst-win64.exe", "&r=1" , "eclipse-inst-nightly.win32.x86-64.exe"},
		{ "nightly.win32.x86"   , DL_NIGHTLY, "eclipse-inst-win32.exe", "&r=1" , "eclipse-inst-nightly.win32.x86.exe"} 
	};
	//@formatter:on

	@Activate
	public void activate() {

		//@formatter:off
		createWorkingDirs();

		for (int archiveIndex = 0; archiveIndex < archives.length; archiveIndex++) {

			String productVersion     = archives[archiveIndex][0];
			String sourceUrl          = archives[archiveIndex][1];
			String archiveName        = archives[archiveIndex][2];
			String dlSuffix           = archives[archiveIndex][3];
			String patchedArchiveName = archives[archiveIndex][4];

			String downloadDir   = wrkDir + SEP + productVersion + SEP + "1_download" ;
			String extractDir    = wrkDir + SEP + productVersion + SEP + "2_extracted" ; 
			String patchDir      = wrkDir + SEP + productVersion + SEP + "3_patched_INI" ; 

			iniSuffix.forEach((variant, iniSuffix) -> {
				
				String resultDir      = resultRootDir + SEP + variant  ; 
				System.out.format("# processing variant <%s> product version <%s>\n", variant, productVersion);

				download(sourceUrl, downloadDir, archiveName, dlSuffix);

				extractExe(downloadDir + SEP + archiveName, extractDir);
				
				patchIni(
					patchDir, 
					extractDir + SEP + PRODUCT, 
					ECLIPSE_INST_INI, 
					iniSuffix
				);

				replaceWithPatchedINI(
					extractDir + SEP + PRODUCT, 
					patchDir + SEP + ECLIPSE_INST_INI,
					SEP + ECLIPSE_INST_INI
				);

				packPatchedExe(patchedArchiveName, extractDir, resultDir);
			});
			//@formatter:on
		}

		System.out.println("done");
	}

	private void packPatchedExe(String archiveName, String extractDir, String resultDir) {
		System.out.format("  5. packing patched exe %s%s%s \n", resultDir, SEP, archiveName);
		//@formatter:off
		try {
			Files.createDirectories(Paths.get(resultDir));
		} catch (IOException e) {
			e.printStackTrace();
		}
		concatenateFilesOsCall(
			resultDir + SEP + archiveName, 
			extractDir,
			EXTRACTOR_EXE, 
			MARKER, 
			EXTRACTOR_LIB, 
			MARKER, 
			DESCRIPTOR, 
			MARKER, 
			PRODUCT, 
			MARKER
		);
		//@formatter:on
	}

	private void replaceWithPatchedINI(String zipArchive, String fileToPack, String filePathInZip) {
		Map<String, String> env = new HashMap<>();
		env.put("create", "true");
		URI uri = URI.create("jar:" + new File(zipArchive).toURI());

		try (FileSystem zipfs = FileSystems.newFileSystem(uri, env)) {
			Path externalFile = Paths.get(fileToPack);
			Path pathInZipfile = zipfs.getPath(filePathInZip);
			Files.copy(externalFile, pathInZipfile, StandardCopyOption.REPLACE_EXISTING);
		} catch (IOException e) {
			e.printStackTrace();
		}
		System.out.format("  4. replacing INI file with patched one inside %s \n", zipArchive);
	}

	private void patchIni(String extractDir, String jarName, String filename, String[] iniSuffixArguments) {
		JarFile jar = null;
		try {
			jar = new JarFile(jarName);
			Enumeration<?> enumEntries = jar.entries();
			while (enumEntries.hasMoreElements()) {
				JarEntry file = (JarEntry) enumEntries.nextElement();
				if (filename != null & filename.length() > 0) {
					if (!filename.equals(file.getName())) {
						continue;
					}
				}

				Files.createDirectories(Paths.get(extractDir));
				String filePathName = extractDir + SEP + file.getName();
				File f = new File(filePathName);
				if (file.isDirectory()) {
					f.mkdir();
					continue;
				}
				InputStream is = jar.getInputStream(file);
				FileOutputStream fos = new FileOutputStream(f);

				while (is.available() > 0) {
					fos.write(is.read());
				}
				is.close();
				fos.close();

				String suffix = (Arrays.asList(iniSuffixArguments).stream()
						.collect(Collectors.joining(System.lineSeparator())));
				Files.write(f.toPath(), suffix.getBytes("utf-8"), StandardOpenOption.APPEND);
				System.out.format("  3. creating patched ini file inside %s \n", filePathName);
			}
			jar.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private void extractExe(String executable, String targetFolder) {

		System.out.format("  2. extracting %s into %s\n", executable, targetFolder);

		//@formatter:off
		String markerFile     = MARKER;
		String productFile    = PRODUCT;
		String extractorFile  = EXTRACTOR_EXE;
		String libdataFile    = EXTRACTOR_LIB;
		String descriptorFile = DESCRIPTOR;

		String[] args = new String[] { 
			executable, 
			targetFolder + SEP + productFile, 
			"-export", 
				targetFolder + SEP + markerFile, 
				targetFolder + SEP + extractorFile, 
				targetFolder + SEP + libdataFile,
				targetFolder + SEP + descriptorFile 
		};
		try {
			BINExtractor.main(args);
		} catch (Exception e) {
			e.printStackTrace();
		}
		//@formatter:on
	}

	private void download(String url, String location, String filename, String suffix) {
		String prod_win32 = String.format("%s/%s%s", url, filename, suffix);

		System.out.format("  1. downloading %s\n", prod_win32);

		try {
			Files.createDirectories(Paths.get(location));
			URL website = new URL(prod_win32);
			ReadableByteChannel rbc = Channels.newChannel(website.openStream());
			FileChannel fc = FileChannel.open(Paths.get(location, filename), StandardOpenOption.CREATE,
					StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.WRITE);
			fc.transferFrom(rbc, 0, Long.MAX_VALUE);
			rbc.close();
			fc.close();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private void createWorkingDirs() {
		try {
			Files.createDirectories(Paths.get(wrkDir));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private void concatenateFilesOsCall(String destFileName, String packDir, String... filesToConcatenate) {

		//@formatter:off
		StringJoiner sj = new StringJoiner("+");
		
		for (String file : filesToConcatenate) {
			sj.add(file.replaceAll("/", "\\"));
		}
		ProcessBuilder pb = new ProcessBuilder(
			"CMD",
			"/C",
			"COPY",
			"/B",
			sj.toString(),
			destFileName
		);
		@SuppressWarnings("unused") // necessary to set the env (otherwise it was null)$
		Map<String, String> env = pb.environment();
		pb.directory(new File(packDir.replaceAll("/", "\\")));
		pb.redirectErrorStream(true);
		try {
			pb.start();
		} catch (IOException e) {
			e.printStackTrace();
		}
		//@formatter:on	
	}

	/*
	 * concatenation was not working - don't know why - replaced it with windows
	 * OS system call copy concatenateFilesOsCall
	 */
	@SuppressWarnings("unused")
	private void concatenateFiles(String destFileName, String... filesToConcatenate) {
		System.out.format("concatenation into file %s\n", destFileName);

		// try {
		// FileChannel dest = new FileOutputStream(destFile).getChannel();
		// for (String file : filesToConcatenate) {
		// FileChannel src = new FileInputStream(file).getChannel();
		// dest.transferFrom(src, 0, src.size());
		// src.close();
		// }
		// dest.close();
		// } catch (IOException e) {
		// e.printStackTrace();
		// }

		try {
			//@formatter:off
			for (String file : filesToConcatenate) {
				
				Path destPath = new File(destFileName).toPath();
				FileChannel fc;
				if (Files.exists(destPath, LinkOption.NOFOLLOW_LINKS)) {
					fc = FileChannel.open(
						destPath,
						StandardOpenOption.WRITE,
						StandardOpenOption.APPEND
					);
				} else {
					fc = FileChannel.open(
						destPath, 
						StandardOpenOption.CREATE,
						StandardOpenOption.WRITE
					);
				}
				ReadableByteChannel rbc = Channels.newChannel(new File(file).toURI().toURL().openStream());
				fc.transferFrom(rbc, 0, Long.MAX_VALUE);
				fc.close();
				rbc.close();
			}
			//@formatter:on
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public static void main(String[] args) {
		//@formatter:off
//		String archiveName = "eclipse-inst-win64.exe";
//		String extractDir = extractRootDir + SEP + 0 + SEP + archiveName;
//		new EclipseInstallerPatchINI().concatenateFiles(
//				extractRootDir + SEP + archiveName,
//				extractDir + SEP + EXTRACTOR_EXE, 
//				extractDir + SEP + MARKER, 
//				extractDir + SEP + EXTRACTOR_LIB,
//				extractDir + SEP + MARKER, 
//				extractDir + SEP + DESCRIPTOR, 
//				extractDir + SEP + MARKER,
//				extractDir + SEP + PRODUCT, 
//				extractDir + SEP + MARKER
//		);
		//@formatter:on
		System.out.println("done");
	}
}
