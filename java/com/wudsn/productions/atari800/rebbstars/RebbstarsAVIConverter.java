package com.wudsn.productions.atari800.rebbstars;

// Use "Nearest Neighbor" to keep the colors exactly as they are when resizing using VirtualDUB

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import com.wudsn.productions.atari800.rebbstars.AVIReader.ATOM;
import com.wudsn.productions.atari800.rebbstars.AVIReader.CHUNK;
import com.wudsn.productions.atari800.rebbstars.AVIReader.LIST;
import com.wudsn.productions.atari800.rebbstars.AVIReader.MainAVIHeader;

public final class RebbstarsAVIConverter {

	// Media parameters
	private static final int MEDIA_AUDIO_CHUNK_SIZE = 1280;
	private static final int MEDIA_AUDIO_CHANNELS = 2;

	// Output parameters
	private static final int OUTPUT_START_FRAME = 0;
	private static final int OUTPUT_MODULE_SIZE = 16384 * 8192; // 16k x 8k
	private static final int OUTPUT_16K_START_BANK = 16;
	private static final int OUTPUT_MAX_16K_BANKS = OUTPUT_MODULE_SIZE / 0x4000 - 1 - 8;
	private static final int OUTPUT_FRAME_LINES = 312;

	// "C:/jac/system/Atari800/Tools/EMU/Atari800Win/Palette/Real.act";
	private static final String PALETTE_FILE_PATH = "C:/jac/system/Atari800/Tools/EMU/Atari800Win/Palette/Real.act";

	private final String mediaFilePath;
	private final String outputFilePath;

	private InputStream mediaInputStream;
	private OutputStream bankOutputStream;

	private HeaderWriter headerWriter;
	private ImageWriter imageWriter;
	private AudioWriter audioWriter;

	private int frameCountSkip;

	public static void main(String[] args) {
		String folderPath;
		String fileName;

		if (args.length == 0) {
			folderPath = "C:\\jac\\system\\Atari800\\Programming\\Demos\\RebbStars\\rip";
			fileName = "GP_OCS.avi";
		} else if (args.length == 2) {
			folderPath = args[0];
			fileName = args[1];
		} else {
			System.err.println("ERROR: Invalid arguments '"
					+ Arrays.toString(args) + "'");
			return;
		}
		RebbstarsAVIConverter aviConverter = new RebbstarsAVIConverter(
				folderPath, fileName);
		aviConverter.run();
	}

	private RebbstarsAVIConverter(String folderPath, String fileName) {
		if (folderPath == null) {
			throw new IllegalArgumentException(
					"Parameter 'folderPath' must not be null.");
		}
		if (fileName == null) {
			throw new IllegalArgumentException(
					"Parameter 'fileName' must not be null.");
		}
		if (!folderPath.endsWith(File.separator)) {
			folderPath += File.separator;
		}

		// "-16kHz-stereo.avi"; // 1280 bytes audio
		// "-44.1kHz-stereo.avi"; // 3840 bytes audio
		mediaFilePath = folderPath + fileName;
		outputFilePath = folderPath + fileName + ".test";
		frameCountSkip = 1; // Integer.MAX_VALUE;

		logParameter("Output Module Size", Long.toHexString(OUTPUT_MODULE_SIZE));
		logParameter("Output Start 16k Bank",
				Long.toHexString(OUTPUT_16K_START_BANK));
		logParameter("Output Maximum 16k Banks",
				Long.toHexString(OUTPUT_MAX_16K_BANKS));
		logParameter("Output Frame Lines", Long.toHexString(OUTPUT_FRAME_LINES));
		logParameter("Output File Path", outputFilePath);
	}

	public void run() {
		long startTime = System.currentTimeMillis();
		File mediaFile = new File(mediaFilePath);
		try {
			mediaInputStream = new FileInputStream(mediaFile);
		} catch (FileNotFoundException ex1) {
			logError("ERROR: Media file '" + mediaFile.getAbsolutePath()
					+ "' not found");
			return;
		}
		String bankOutputFilePath = outputFilePath;

		File bankOutputFile = new File(bankOutputFilePath);

		try {
			bankOutputStream = new FileOutputStream(bankOutputFile);
		} catch (FileNotFoundException ex1) {
			logError("ERROR: Bank output file '"
					+ bankOutputFile.getAbsolutePath() + "' not found");
			return;
		}
		try {

			parse();
		} finally {
			try {
				bankOutputStream.close();
			} catch (IOException ex) {
				throw new RuntimeException("Cannot close file", ex);
			}
			try {
				mediaInputStream.close();
			} catch (IOException ex) {
				throw new RuntimeException("Cannot close file", ex);
			}
		}

		long duration = System.currentTimeMillis() - startTime;
		logDetail("Done after " + duration / 1000 + "s.");
		logDetail("Audio minValue=" + audioWriter.getMinValue() + ", maxValue="
				+ audioWriter.getMaxValue());

	}

	private void parse() {

		int frameCount = 0;
		int bankCount = 0;

		AVIReader aviReader = new AVIReader(mediaInputStream);
		LIST aviList = aviReader.readList();
		logDetail(aviList.toString());
		LIST hdr1List = aviReader.readList();
		logDetail(hdr1List.toString());

		MainAVIHeader header = aviReader.readHeader();
		headerWriter = new HeaderWriter(OUTPUT_16K_START_BANK);

		imageWriter = new ImageWriter();
		// imageWriter.initialize(header.width, header.height, 0.4, 1.0);
		imageWriter.initialize(header.width, header.height, 0.5, 1.0);

		float saturationFactor = 1.0f;
		float brightnessFactor = 0.8f;
		imageWriter.readPalette(PALETTE_FILE_PATH, saturationFactor,
				brightnessFactor);

		audioWriter = new AudioWriter(MEDIA_AUDIO_CHUNK_SIZE,
				MEDIA_AUDIO_CHANNELS,
				4096 - headerWriter.getCartridgeHeaderLength(),
				OUTPUT_FRAME_LINES);

		logDetail(header.toString());

		ATOM atom = null;
		atom = aviReader.readAtom();
		while (!atom.fourCC.equals("movi")) {
			aviReader.skipAtomData(atom);
			logDetail(atom.toString());
			atom = aviReader.readAtom();
		}

		int imageChunksCount = 0;
		int audioChunksCount = 0;

		int minValue = Integer.MAX_VALUE;

		List<CHUNK> imageChunks;
		List<CHUNK> audioChunks;
		imageChunks = new ArrayList<CHUNK>();
		audioChunks = new ArrayList<CHUNK>();
		atom = aviReader.readAtom();
		while (!atom.fourCC.equals("idx1")) {
			com.wudsn.productions.atari800.rebbstars.AVIReader.CHUNK imageChunk;
			CHUNK audioChunk;

			if (atom.fourCC.equals("01db")) {
				imageChunk = (CHUNK) atom;
				aviReader.readChunkData(imageChunk);
				imageChunks.add(imageChunk);
				imageChunksCount = imageChunksCount + 1;
				logDetail("Image " + imageChunksCount + ": size="
						+ imageChunk.size);

			} else if (atom.fourCC.equals("00wb")) {
				audioChunk = (CHUNK) atom;

				aviReader.readChunkData(audioChunk);
				audioChunks.add(audioChunk);
				audioChunksCount = audioChunksCount + 1;
				logDetail("Audio " + audioChunksCount + ": size="
						+ audioChunk.size);

			} else {
				aviReader.skipAtomData(atom);
				logDetail("Atom " + atom.toString());
			}

			if (!imageChunks.isEmpty() && !audioChunks.isEmpty()) {
				imageChunk = imageChunks.remove(0);
				audioChunk = audioChunks.remove(0);
				if (audioChunk.data.length > MEDIA_AUDIO_CHUNK_SIZE) {
					System.out.println("INFO: Splitting audio chunk");
					byte[] data = audioChunk.data;

					// Shorten first chunk
					audioChunk.data = new byte[MEDIA_AUDIO_CHUNK_SIZE];
					System.arraycopy(data, 0, audioChunk.data, 0,
							audioChunk.data.length);

					// Put rest into a next chunk
					CHUNK additionalAudioChunk = new CHUNK(audioChunk.position);
					additionalAudioChunk.fourCC = audioChunk.fourCC;
					additionalAudioChunk.size = audioChunk.size
							- MEDIA_AUDIO_CHUNK_SIZE;
					additionalAudioChunk.data = new byte[data.length
							- MEDIA_AUDIO_CHUNK_SIZE];
					System.arraycopy(data, 0, additionalAudioChunk.data, 0,
							additionalAudioChunk.data.length);
					audioChunks.add(0, additionalAudioChunk);

					audioChunksCount = audioChunksCount + 1;
					logDetail("Audio " + audioChunksCount + ": size="
							+ audioChunk.size);
				}
				if (imageChunksCount >= OUTPUT_START_FRAME
						&& bankCount < OUTPUT_MAX_16K_BANKS) {
					frameCount = frameCount + 1;
					logDetail("Frame " + frameCount + ":");

					// 720x568*3
					if ((frameCount - 1) % frameCountSkip == 0) {
						int xmax = 720;
						int ymax = 568;
						int bpl = xmax * 3;
						int value = -1;
						for (int y = 0; y < ymax && value == -1; y++) {
							int index = y * bpl + bpl / 2;
							int color = imageChunk.data[index]
									& imageChunk.data[index + 1]
									& imageChunk.data[index + 2];
							if (color == -1) {
								value = y;
								minValue = Math.min(value, minValue);
							}
						}
						try {
							System.out.println(value + ", " + minValue);

							bankOutputStream.write(value);
						} catch (IOException ex) {
							throw new RuntimeException(ex);
						}
						// TODO

					}
				}

				imageChunk = null;
				audioChunk = null;
			}

			atom = aviReader.readAtom();
		}

	}

	private static void logParameter(String parameterName, Object... args) {
		System.out.print(parameterName);
		System.out.print(": ");
		System.out.println(args[0]);
	}

	private static void logDetail(String s) {
		if (s == null) {
			throw new IllegalArgumentException(
					"Parameter 's' must not be null.");
		}
		System.out.println(s);
	}

	private static void logError(String s) {
		if (s == null) {
			throw new IllegalArgumentException(
					"Parameter 's' must not be null.");
		}
		System.err.println(s);
	}

}