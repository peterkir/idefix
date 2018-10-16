package io.klib.prepare.eclipseinstaller;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;
import java.net.URL;
import java.nio.channels.Channels;
import java.nio.channels.FileChannel;
import java.nio.channels.ReadableByteChannel;
import java.nio.charset.Charset;
import java.nio.file.DirectoryStream;
import java.nio.file.FileSystem;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import java.util.stream.Collectors;

import org.apache.commons.compress.archivers.tar.TarArchiveEntry;
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream;
import org.apache.commons.compress.archivers.tar.TarArchiveOutputStream;
import org.apache.commons.compress.compressors.gzip.GzipCompressorInputStream;
import org.apache.commons.compress.compressors.gzip.GzipCompressorOutputStream;
import org.apache.commons.compress.utils.IOUtils;
import org.eclipse.oomph.extractor.lib.BINExtractor;
import org.osgi.application.Framework;
import org.osgi.framework.BundleException;
import org.osgi.framework.FrameworkUtil;
import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;

// @formatter:off
@Component
public class EclipseInstallerPatchINI {

	private static final String DL_PROD    = "http://www.eclipse.org/downloads/download.php?file=/oomph/products";
	
	// format: archive name, download URL, oomph archive name, IDEfix archive name, setup.p2.agent location
	
	String[][] archives = {
		{ "prod.macosx.x86-64",   DL_PROD,    "eclipse-inst-mac64.tar.gz",   "IDEfix.inst.macosx.x86-64.tar.gz", "@user.home/oomph/.p2"   },
		{ "prod.linux.x86-64",    DL_PROD,    "eclipse-inst-linux64.tar.gz", "IDEfix.inst.linux.x86-64.tar.gz",  "@user.home/oomph/.p2"   },
//		{ "prod.linux.x86",       DL_PROD,    "eclipse-inst-linux32.tar.gz", "IDEfix.inst.linux.x86.tar.gz",     "@user.home/oomph/.p2"   },
		{ "prod.win32.x86-64",    DL_PROD,    "eclipse-inst-win64.exe",      "IDEfix.inst.win32.x86-64.exe",     "C:/IDEfix/.p2" },
//		{ "prod.win32.x86",       DL_PROD,    "eclipse-inst-win32.exe",      "IDEfix.inst.win32.x86.exe",        "C:/IDEfix/.p2" },
	};

	private static final String DL_NIGHTLY = "http://www.eclipse.org/downloads/download.php?file=/oomph/products/latest";
	String[][] archivesNightly = {
//		{ "nightly.macosx.x86-64", DL_NIGHTLY, "eclipse-inst-mac64.tar.gz",   "eclipse-inst-nightly.macosx.x86-64.tar.gz", "@user.home/oomph/.p2"  },
//		{ "nightly.linux.x86-64",  DL_NIGHTLY, "eclipse-inst-linux64.tar.gz", "eclipse-inst-nightly.linux.x86-64.tar.gz",  "@user.home/oomph/.p2"  },
//		{ "nightly.linux.x86",     DL_NIGHTLY, "eclipse-inst-linux32.tar.gz", "eclipse-inst-nightly.linux.x86.tar.gz",     "@user.home/oomph/.p2"  },
//		{ "nightly.win32.x86-64",  DL_NIGHTLY, "eclipse-inst-win64.exe",      "eclipse-inst-nightly.win32.x86-64.exe",     "C:/IDEfix/.p2" },
//		{ "nightly.win32.x86",     DL_NIGHTLY, "eclipse-inst-win32.exe",      "eclipse-inst-nightly.win32.x86.exe",        "C:/IDEfix/.p2" },
	};

	private static final String ECL_DL_SUFFIX = "&r=1";

	private static final String EXTRACTOR_EXE    = "extractor.exe";
	private static final String EXTRACTOR_LIB    = "extractorlib.jar";
	private static final String DESCRIPTOR       = "product-descriptor";
	private static final String PRODUCT          = "product.zip";
	private static final String MARKER           = "marker.txt";

	private static final String ECLIPSE_INST_INI = "eclipse-inst.ini";

	private static final String SEP           = File.separator;
	private static final String DIR           = System.getProperty("user.dir");
	private static final String wrkDir        = DIR + SEP + "_wrk";
	private static final String resultRootDir = DIR + SEP + "_result";
	
	private static final String ts = DateTimeFormatter.ofPattern("yyyyMMdd-HHmm").format(LocalDateTime.now());
	private static final String resultVariantDir = resultRootDir + SEP + ts;

	private static final int BUFFER_SIZE = 4096;

	private static final HashMap<String, String[]> iniSuffix = new LinkedHashMap<String, String[]>();

	public EclipseInstallerPatchINI() {
		iniSuffix.put("peterkir", new String[] { 
			"-Doomph.setup.installer.mode=advanced",
			"-Doomph.setup.installer.p2pool=true", 
			"-Doomph.setup.installer.launch=true",
			"-Doomph.update.url=http://download.eclipse.org/oomph/updates/release/latest/",
			"-Doomph.redirection.idefixProductCatalog=index:/redirectable.products.setup->http://peterkir.github.io/idefix/bootstrap/peterkir/catalogProducts.setup",
			"-Doomph.redirection.idefixProjectCatalog=index:/redirectable.projects.setup->http://peterkir.github.io/idefix/bootstrap/peterkir/catalogProjects.setup",
			"-Doomph.setup.product.catalog.filter=io\\\\.klib\\\\.products",
			"-Doomph.setup.product.filter=(?\\!io\\\\.klib\\\\.products\\\\.idefix\\\\.oxygen).*",
			"-Doomph.setup.product.version.filter=.*\\\\.latest\\\\.cloudbees",
			"-Dsetup.p2.agent="
		});
		
		iniSuffix.put("IDEfix.cec.1812", new String[] {
				"-Doomph.setup.installer.mode=advanced",
				"-Doomph.setup.stats.skip=true",
				"-Doomph.setup.installer.p2pool=true",
				"-Doomph.setup.installer.launch=true",
				"-Doomph.update.url=http://download.eclipse.org/oomph/updates/release/latest/",
				"-Doomph.redirection.idefixProductCatalog=index:/redirectable.products.setup->http://peterkir.github.io/idefix/bootstrap/daimler.cec/1812/catalog.product.idefix.setup",
				"-Doomph.redirection.idefixProjectCatalog=index:/redirectable.projects.setup->http://peterkir.github.io/idefix/bootstrap/daimler.cec/1812/catalog.project.cec.setup",
				"-Doomph.setup.product.catalog.filter=(idefix\\\\.products)",
				"-Doomph.setup.product.filter=(.*oxygen.*)",
				"-Doomph.setup.product.version.filter=(.*1812.*)",
				"-Doomph.setup.jre.choice=false",
				"-Dsetup.p2.agent="	
			});
			
		iniSuffix.put("daimler.cec.182", new String[] {
			"-Doomph.setup.installer.mode=advanced",
			"-Doomph.setup.installer.p2pool=true",
			"-Doomph.setup.installer.launch=true",
			"-Doomph.update.url=http://download.eclipse.org/oomph/updates/release/latest/",
			"-Doomph.redirection.idefixProductCatalog=index:/redirectable.products.setup->http://peterkir.github.io/idefix/bootstrap/daimler.cec/182/catalogProducts.setup",
			"-Doomph.redirection.idefixProjectCatalog=index:/redirectable.projects.setup->http://peterkir.github.io/idefix/bootstrap/daimler.cec/182/catalogProjects.setup",
			"-Doomph.setup.product.catalog.filter=com\\\\.daimler\\\\.products",
			"-Doomph.setup.product.filter=(.*idefix).*",
			"-Doomph.setup.product.version.filter=(.*idefix.*)",
			"-Dsetup.p2.agent="	
		});
		
		iniSuffix.put("daimler.ec.172", new String[] {
			"-Doomph.setup.installer.mode=advanced",
			"-Doomph.setup.installer.p2pool=true",
			"-Doomph.setup.installer.launch=true",
			"-Doomph.update.url=http://download.eclipse.org/oomph/updates/release/latest/",
			"-Doomph.redirection.idefixProductCatalog=index:/redirectable.products.setup->http://peterkir.github.io/idefix/bootstrap/daimler.ec/catalogProducts.setup",
			"-Doomph.redirection.idefixProjectCatalog=index:/redirectable.projects.setup->http://peterkir.github.io/idefix/bootstrap/daimler.ec/catalogProjects.setup",
			"-Doomph.setup.product.catalog.filter=com\\\\.daimler\\\\.products",
			"-Doomph.setup.product.filter=(.*idefix).*",
			"-Doomph.setup.product.version.filter=.*?(appdev).*?",
			"-Dsetup.p2.agent="
		});

		iniSuffix.put("daimler.ec.181", new String[] {
				"-Doomph.setup.installer.mode=advanced",
				"-Doomph.setup.installer.p2pool=true",
				"-Doomph.setup.installer.launch=true",
				"-Doomph.update.url=http://download.eclipse.org/oomph/updates/release/latest/",
				"-Doomph.redirection.idefixProductCatalog=index:/redirectable.products.setup->http://peterkir.github.io/idefix/bootstrap/daimler.ec/181/catalogProducts.setup",
				"-Doomph.redirection.idefixProjectCatalog=index:/redirectable.projects.setup->http://peterkir.github.io/idefix/bootstrap/daimler.ec/181/catalogProjects.setup",
				"-Doomph.setup.product.catalog.filter=com\\\\.daimler\\\\.products",
				"-Doomph.setup.product.filter=(.*idefix).*",
				"-Doomph.setup.product.version.filter=.*?(appdev).*?",
				"-Dsetup.p2.agent="
			});

		iniSuffix.put("daimler.ec.182", new String[] {
				"-Doomph.setup.installer.mode=advanced",
				"-Doomph.setup.installer.p2pool=true",
				"-Doomph.setup.installer.launch=true",
				"-Doomph.update.url=http://download.eclipse.org/oomph/updates/release/latest/",
				"-Doomph.redirection.idefixProductCatalog=index:/redirectable.products.setup->http://peterkir.github.io/idefix/bootstrap/daimler.ec/182/catalogProducts.setup",
				"-Doomph.redirection.idefixProjectCatalog=index:/redirectable.projects.setup->http://peterkir.github.io/idefix/bootstrap/daimler.ec/182/catalogProjects.setup",
				"-Doomph.setup.product.catalog.filter=com\\\\.daimler\\\\.products",
				"-Doomph.setup.product.filter=(.*idefix).*",
				"-Doomph.setup.product.version.filter=.*?(appdev).*?",
				"-Dsetup.p2.agent="
			});
};

	@Activate
	public void activate() {

		createWorkingDirs();
		
		for (int archiveIndex = 0; archiveIndex < archives.length; archiveIndex++) {

			String productVersion     = archives[archiveIndex][0];
			String sourceUrl          = archives[archiveIndex][1];
			String archiveName        = archives[archiveIndex][2];
			String patchedArchiveName = archives[archiveIndex][3];
			String p2PoolPath         = archives[archiveIndex][4];

			String downloadDir = wrkDir + SEP + "1_download"    + SEP + productVersion;
			String extractDir  = wrkDir + SEP + "2_extracted"   + SEP + productVersion;
			String patchDir    = wrkDir + SEP + "3_patched_INI" + SEP + productVersion;

			iniSuffix.forEach((variant, iniSuffix) -> {
				
				String resultDir = resultVariantDir + SEP + variant;
				System.out.format("# processing variant <%s> product version <%s>\n", variant, productVersion);

				download(sourceUrl, downloadDir, archiveName, ECL_DL_SUFFIX);

				String archiveSuffix = archiveName.replaceFirst("eclipse-inst-(.+?)(\\.tar\\.gz|\\.exe)", "$1");
				switch (archiveSuffix) {
				case "win64":
					extractExe(downloadDir + SEP + archiveName, extractDir);

					patchIniInZip(
						patchDir, 
						extractDir + SEP + PRODUCT, 
						ECLIPSE_INST_INI, 
						p2PoolPath, 
						iniSuffix
					);
					
					replaceWithPatchedINI(
						extractDir + SEP + PRODUCT, 
						patchDir + SEP + ECLIPSE_INST_INI, 
						SEP + ECLIPSE_INST_INI
					);
					
					packPatchedExe(
						patchedArchiveName, 
						extractDir, 
						resultDir
					);
					break;

				case "mac64":
					extractTarGz(
						downloadDir, 
						archiveName, 
						extractDir
					);
					String iniFile = extractDir + SEP + "Eclipse Installer.app/Contents/Eclipse"+ SEP + ECLIPSE_INST_INI;
					patchIni(
						patchDir, 
						iniFile, 
						p2PoolPath, 
						iniSuffix
					);
					
					packPatchedTarGz(
						patchedArchiveName, 
						extractDir, 
						resultDir
					);
					
					break;

				case "linux64":
					extractTarGz(
							downloadDir, 
							archiveName, 
							extractDir
					);
                    iniFile = extractDir + SEP + "eclipse-installer"+ SEP + ECLIPSE_INST_INI;
                    patchIni(
                    	patchDir, 
                    	iniFile, 
                    	p2PoolPath, 
                    	iniSuffix
                    );
						
                    packPatchedTarGz(
                    	patchedArchiveName, 
                    	extractDir, 
                    	resultDir
                    );
				
                    break;

				default:
					System.out.format("No strategy for archive <%s> with suffix <%s>", archiveName, archiveSuffix);
					break;
				}

			});
		}

		updateIndexFile();
		try {
			Files.write(Paths.get(resultRootDir, "LATEST-IDEFIX-BUILD.txt"), ts.getBytes(), StandardOpenOption.CREATE);
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		System.out.println("done");
		try {
			FrameworkUtil.getBundle(FrameworkUtil.class).getBundleContext().getBundle(0).stop();
		} catch (BundleException e) {
			e.printStackTrace();
		}
	}

	private void updateIndexFile() {
		StringBuffer sb = new StringBuffer();
		sb.append(String.format("<html>\n<head>\n<title>IDEfix installers</title>\n</head>\n<body>\n",ts));
		sb.append("<h1>Pre-Requisites</h1>\n");
		sb.append("<p>Download and install the latest Java SDK version (minimum Java 8)</p>\n");
		
		sb.append("<a href='http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html'>Java SDK Download</a>\n");
		sb.append("<h1>IDEfix installers</h1>\n");
		sb.append("<p>Download and store the executable for your platform locally and run it.\n");
		Path resultRootPath = Paths.get(resultRootDir);
		
		try {
			Files.list(resultRootPath).filter( f ->
					!f.toFile().getName().startsWith(".") && 
					!f.toFile().getName().endsWith("index.html")
				).forEach(version -> {
				sb.append(String.format("<h2>Version %s</h2>\n",resultRootPath.relativize(version)));
				if (version.toFile().isDirectory() ) {
					try {
						Files.list(version).filter(f->!f.toFile().getName().startsWith(".")).forEach(customer -> {
							sb.append(String.format("    <h2>Customer %s</h2>\n", version.relativize(customer)));
							if (customer.toFile().isDirectory()) {
								try {
									Files.list(customer).filter( f -> 
										!f.toFile().getName().startsWith(".") 
										&& f.toFile().isFile()).forEach( os -> {
											if ( !os.toString().startsWith(".") )
													sb.append(String.format("        <a href='%s'>%s</a><br/>\n", resultRootPath.relativize(os),customer.relativize(os)));
									});
								} catch (IOException e) {
									e.printStackTrace();
								}
							}
						});
					} catch (IOException e) {
						e.printStackTrace();
					}
				}
			});
			sb.append("</body>\n</html>");
			System.out.println(sb.toString());
			Files.write(resultRootPath.resolve("index.html"), sb.toString().getBytes(Charset.forName("UTF-8")), StandardOpenOption.CREATE,StandardOpenOption.WRITE);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private void patchIni(String patchDir, String iniFile, String p2PoolPath, String[] iniSuffixArguments) {
		try {
			String suffix = (
				Arrays.asList(iniSuffixArguments).stream().collect(Collectors.joining(System.lineSeparator()))
			);
			suffix = suffix.replace("-Dsetup.p2.agent=", "-Dsetup.p2.agent=" + p2PoolPath);
			Path filePathName = new File(iniFile).toPath();
			Files.write(filePathName, suffix.getBytes("utf-8"), StandardOpenOption.APPEND);
			System.out.format("  3. creating patched ini file inside %s \n", filePathName);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private void packPatchedTarGz(String patchedArchiveName, String extractDir, String resultDir) {
		try {
			Path inputDirectoryPath = new File(extractDir).toPath();
			File outputFile = new File(resultDir + SEP + patchedArchiveName);
			new File(resultDir).mkdirs();
			try (FileOutputStream fileOutputStream = new FileOutputStream(outputFile);
					BufferedOutputStream bufferedOutputStream = new BufferedOutputStream(fileOutputStream);
					GzipCompressorOutputStream gzipOutputStream = new GzipCompressorOutputStream(bufferedOutputStream);
					TarArchiveOutputStream tarArchiveOutputStream = new TarArchiveOutputStream(gzipOutputStream)) {

				tarArchiveOutputStream.setBigNumberMode(TarArchiveOutputStream.BIGNUMBER_POSIX);
				tarArchiveOutputStream.setLongFileMode(TarArchiveOutputStream.LONGFILE_GNU);

				List<Path> files = listFiles(inputDirectoryPath, new LinkedList<Path>());

				files.forEach(f -> {
					File file = f.toFile();
					String relativeFilePath = new File(inputDirectoryPath.toUri()).toURI()
							.relativize(new File(file.getAbsolutePath()).toURI()).getPath();

					TarArchiveEntry tarEntry = new TarArchiveEntry(file, relativeFilePath);
					tarEntry.setSize(file.length());

					try {
						if (Files.isExecutable(FileSystems.getDefault().getPath(file.getAbsolutePath()))) {
							tarEntry.setMode(493);
					      }
						tarArchiveOutputStream.putArchiveEntry(tarEntry);
						tarArchiveOutputStream.write(IOUtils.toByteArray(new FileInputStream(file)));
						tarArchiveOutputStream.closeArchiveEntry();
					} catch (IOException e) {
						e.printStackTrace();
					}
				});
				tarArchiveOutputStream.close();
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private List<Path> listFiles(Path path, List<Path> files) throws IOException {
		try (DirectoryStream<Path> stream = Files.newDirectoryStream(path)) {
			for (Path entry : stream) {
				if (Files.isDirectory(entry)) {
					listFiles(entry, files);
				} else {
					files.add(entry);
				}
			}
		}
		return files;
	}

	private void extractTarGz(String downloadDir, String archiveName, String extractDir) {

		System.out.format("  2. extracting %s into %s\n", archiveName, extractDir);
		
		new File(extractDir).mkdirs();
		try {
			File file = new File(downloadDir + SEP + archiveName);
			GzipCompressorInputStream gzipIn = new GzipCompressorInputStream(new FileInputStream(file));
			try (TarArchiveInputStream tarIn = new TarArchiveInputStream(gzipIn)) {
				TarArchiveEntry entry;

				while ((entry = (TarArchiveEntry) tarIn.getNextEntry()) != null) {
					/** If the entry is a directory, create the directory. **/
					String filename = extractDir + SEP + entry.getName();
					if (entry.isDirectory()) {
						File f = new File(filename);
						boolean created = f.mkdirs();
						if (!f.exists() && !created) {
							System.out.printf(
									"Unable to create directory '%s', during extraction of archive contents.\n",
									f.getAbsolutePath());
						}
					} else {
						int count;
						byte data[] = new byte[BUFFER_SIZE];
						FileOutputStream fos = new FileOutputStream(filename, false);
						try (BufferedOutputStream dest = new BufferedOutputStream(fos, BUFFER_SIZE)) {
							while ((count = tarIn.read(data, 0, BUFFER_SIZE)) != -1) {
								dest.write(data, 0, count);
							}
							dest.close();
							if (entry.getMode()==493) {
								System.out.format("     set execution right file - %s\n", entry);
								new File(filename).setExecutable(true);
							}
							System.out.format("     extracted file %s with permissions %s\n", entry.getName(), entry.getMode());
						}
					}
				}
				tarIn.close();
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private void packPatchedExe(String archiveName, String extractDir, String resultDir) {
		System.out.format("  5. packing patched exe %s%s%s \n", resultDir, SEP, archiveName);
		try {
			Files.createDirectories(Paths.get(resultDir));
		} catch (IOException e) {
			e.printStackTrace();
		}

		concatenateFiles(resultDir + SEP + archiveName, extractDir, EXTRACTOR_EXE, MARKER, EXTRACTOR_LIB, MARKER,
				DESCRIPTOR, MARKER, PRODUCT, MARKER);
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

	private void patchIniInZip(String extractDir, String jarName, String filename, String p2PoolPath, String[] iniSuffixArguments) {
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

				String suffix = (
					Arrays.asList(iniSuffixArguments).stream().collect(Collectors.joining(System.lineSeparator()))
				);
				suffix = suffix.replace("-Dsetup.p2.agent=", "-Dsetup.p2.agent=" + p2PoolPath);
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
		if (executable.contains("win64")) {
			try {
				System.out.println("     --> replacing executable with signed version");
				Path source = Paths.get(DIR,"signed_extractor/win64/extractor.exe");
				Path destination = Paths.get(wrkDir,"2_extracted/prod.win32.x86-64/extractor.exe");
				if (source.toFile().exists()) {
					Path copy = Files.copy(source,destination, StandardCopyOption.REPLACE_EXISTING);
				} else {
					System.out.println("no source file exists " + source);
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	private void download(String url, String location, String filename, String suffix) {
		String prod_win32 = String.format("%s/%s%s", url, filename, suffix);
		Path path = Paths.get(location, filename);
		if (!path.toFile().exists()) {
			System.out.format("  1. downloading %s\n", prod_win32);
			try {
				Files.createDirectories(Paths.get(location));
				URL website = new URL(prod_win32);
				ReadableByteChannel rbc = Channels.newChannel(website.openStream());
				FileChannel fc = FileChannel.open(path, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING,
						StandardOpenOption.WRITE);
				fc.transferFrom(rbc, 0, Long.MAX_VALUE);
				rbc.close();
				fc.close();
			} catch (Exception e) {
				e.printStackTrace();
			}
		} else {
			System.out.format("  1. already existing %s - skipping download\n", prod_win32);
		}
	}

	private void createWorkingDirs() {
		try {
			Files.createDirectories(Paths.get(wrkDir));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/*
	 * concatenation was not working - don't know why - replaced it with windows OS
	 * system call copy concatenateFilesOsCall
	 */
	private void concatenateFiles(String destFileName, String packDir, String... filesToConcatenate) {

		OutputStream out;
		try {
			out = new FileOutputStream(destFileName);
			byte[] buf = new byte[4096];
			for (String file : filesToConcatenate) {
				InputStream in = new FileInputStream(packDir + SEP + file);
				int b = 0;
				while ((b = in.read(buf)) >= 0) {
					out.write(buf, 0, b);
					out.flush();
				}
				in.close();
			}
			out.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
