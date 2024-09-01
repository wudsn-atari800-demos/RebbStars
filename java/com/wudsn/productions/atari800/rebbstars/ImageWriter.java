package com.wudsn.productions.atari800.rebbstars;

import java.awt.Color;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Map;

class ImageWriter {
    public static final int SCREEN_BPL = 40;

    private int[][] palette;
    private boolean usePaletteBrightness;
    private Map<Integer, Integer> colorMap; // Cache

    private int imageWidth;
    private int imageHeight;
    private int imageChunkSize;
    
    private double imageWidthFactor;
    private double imageHeightFactor;

    private int scaledWidth;
    private int scaledHeight;

    private static final int BPP = 4;
    private int bpl, pixelWidth, pixelHeight, bps;
    private byte[] gr9, gr10, gr11, padding;

    public ImageWriter() {
	palette = new int[256][3];
	colorMap = new HashMap<Integer, Integer>();
    }

    public void readPalette(String fileName, float saturationFactor,
	    float brighnessFactor) {

	usePaletteBrightness = true;

	byte[] d = new byte[768];
	try {
	    FileInputStream f = new FileInputStream(new File(fileName));
	    f.read(d);
	    f.close();
	} catch (IOException ex) {
	    throw new RuntimeException(ex);
	}
	int i = 0, y, r, g, b, rgb;
	float[] hsb = new float[3];
	for (y = 0; y < 256; y++) {
	    r = d[i++] & 0xFF;
	    g = d[i++] & 0xFF;
	    b = d[i++] & 0xFF;
	    Color.RGBtoHSB(r, g, b, hsb);
	    hsb[2] = Math.min(1.0f, hsb[2] * brighnessFactor);
	    rgb = Color.HSBtoRGB(hsb[0], hsb[1] / saturationFactor, hsb[2]);
	    palette[y][0] = (rgb >> 16) & 0xFF;
	    palette[y][1] = (rgb >> 8) & 0xFF;
	    palette[y][2] = (rgb) & 0xFF;
	}

	colorMap.clear(); // Palette has changed
    }

    public void initialize(int imageWidth, int imageHeight,
	    double imageWidthFactor, double imageHeightFactor) {

	this.imageWidth = imageWidth;
	this.imageHeight = imageHeight;
	this.imageChunkSize = imageWidth*imageWidth*3;

	this.imageWidthFactor = imageWidthFactor;
	this.imageHeightFactor = imageHeightFactor;

	scaledWidth = (int) (this.imageWidth * imageWidthFactor);

	scaledHeight = (int) (this.imageHeight * imageHeightFactor);

	pixelWidth = scaledWidth;
	pixelHeight = scaledHeight / 2;
	
	bpl = (pixelWidth + BPP - 1) / BPP;
	bpl = Math.max(bpl, SCREEN_BPL);
	bps = bpl * pixelHeight;

	gr9 = new byte[bps];
	gr10 = new byte[bps];
	gr11 = new byte[bps];
	padding = new byte[16384];

	colorMap.clear(); // Image has changed
    }

    public void convert(byte[] image) {
	if (image == null) {
	    throw new IllegalArgumentException(
		    "Parameter 'image' must not be null.");
	}
	if (image.length > imageChunkSize) {
	    throw new IllegalArgumentException(
		    "ERROR: Image chunk has "
			    + image.length
			    + " bytes and is larger than the defined audio chunk size of "
			    + imageChunkSize + " bytes.");
	}

	int x, y, j, m, diff, n, d, e;
	int[] lu = new int[3];
	int[] ru = new int[3];
	int[] ld = new int[3];
	int[] rd = new int[3];

	int r[] = new int[BPP];
	int g[] = new int[BPP];
	int b[] = new int[BPP];
	int c[] = new int[BPP];
	for (y = 0; y < pixelHeight; y++) {
	    int y2 = y << 1;
	    for (x = 0; x < bpl; x++) {
		int x4 = x << 2;
		for (j = 0; j < BPP; j++) {

		    int xj = x4 + j;
		    getRGB(image, xj, y2, lu);
		    getRGB(image, xj + 1, y2, ru);
		    getRGB(image, xj, y2 + 1, ld);
		    getRGB(image, xj + 1, y2 + 1, rd);
		    r[j] = ((lu[0]) + ru[0] + ld[0] + rd[0]) / 4;
		    g[j] = ((lu[1]) + ru[1] + ld[1] + rd[1]) / 4;
		    b[j] = ((lu[2]) + ru[2] + ld[2] + rd[2]) / 4;

		    int color = r[j] << 16 | g[j] << 8 | b[j];
		    Integer colorKey = new Integer(color);
		    Integer colorValue;

		    colorValue = colorMap.get(colorKey);

		    if (colorValue == null) {

			diff = 0x7fffffff;
			n = 0;
			for (m = 0; m < 256; m++) {
			    e = (palette[m][0] - r[j]);
			    d = e * e;
			    e = (palette[m][1] - g[j]);
			    d += e * e;
			    e = (palette[m][2] - b[j]);
			    d += e * e;
			    if (d < diff) {
				diff = d;
				n = m;
			    }
			}
			colorValue = new Integer(n);
			colorMap.put(colorKey, colorValue);
		    }

		    c[j] = colorValue.intValue();
		    b[j] = (r[j] + g[j] + b[j]) / 48;
		}
		int offset = x + y * bpl;
		if (usePaletteBrightness) {
		    gr9[offset] = (byte) (((c[0] & 0x0f) << 4) | (c[2] & 0x0f));
		    gr10[offset] = (byte) (((c[1] & 0x0e) << 3) | ((c[3] & 0x0e) >> 1));
		} else {
		    gr9[offset] = (byte) (((b[0]) << 4) | b[2]);
		    gr10[offset] = (byte) (((b[1] & 0x0e) << 3) | ((b[3] & 0x0e) >> 1));
		}
		gr11[offset] = (byte) ((c[0] & 0xf0) | ((c[2] & 0xf0) >> 4));
	    }

	}
    }

    private final void getRGB(byte[] image, int x, int y, int[] rgb) {
	if (x >= scaledWidth || y > scaledHeight) {
	    rgb[0] = 0;
	    rgb[1] = 0;
	    rgb[2] = 0;
	    return;
	}
	int scaledx = (int) (x / imageWidthFactor);
	int scaledy = (int) ((scaledHeight - 1 - y) / imageHeightFactor);

	int offset = (scaledx + scaledy * imageWidth) * 3;
	try {
	    rgb[0] = image[offset + 2] & 0xFF; // R
	    rgb[1] = image[offset + 1] & 0xFF; // G
	    rgb[2] = image[offset + 0] & 0xFF; // B
	} catch (ArrayIndexOutOfBoundsException ex) {
	    // throw new IllegalArgumentException("Position x=" + x + " y="
	    // + y + " is out of range.");
	    rgb[0] = 0;
	    rgb[1] = 0;
	    rgb[2] = 0;
	}
	// System.err.println(Arrays.toString(rgb));
    }

    /**
     * Saves exactly $3000 bytes to the stream
     * 
     * @param outputStream
     *            The output stream, not <code>null</code>.
     * @throws IOException
     *             If an IO error occurs.
     */
    public void saveBank(OutputStream outputStream) throws IOException {
	if (outputStream == null) {
	    throw new IllegalArgumentException(
		    "Parameter 'outputStream' must not be null.");
	}
	outputStream.write(gr11, 0, gr11.length);
	outputStream.write(padding, 0, 4096 - bps);
	outputStream.write(gr9, 0, gr9.length);
	outputStream.write(padding, 0, 4096 - bps);
	outputStream.write(gr10, 0, gr10.length);
	outputStream.write(padding, 0, 4096 - bps);
    }

    public void saveTIP(OutputStream outputStream) throws IOException {
	if (outputStream == null) {
	    throw new IllegalArgumentException(
		    "Parameter 'outputStream' must not be null.");
	}
	outputStream.write('T');
	outputStream.write('I');
	outputStream.write('P');
	outputStream.write(1);
	outputStream.write(0);
	outputStream.write(bpl * BPP);
	outputStream.write(pixelHeight);
	outputStream.write(bps & 0xFF);
	outputStream.write((bps >>> 8) & 0xFF);
	outputStream.write(gr9, 0, gr9.length);
	outputStream.write(gr10, 0, gr10.length);
	outputStream.write(gr11, 0, gr11.length);
    }
}