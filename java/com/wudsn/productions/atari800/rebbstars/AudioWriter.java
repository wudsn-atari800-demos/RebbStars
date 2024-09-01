package com.wudsn.productions.atari800.rebbstars;

import java.io.IOException;
import java.io.OutputStream;

final class AudioWriter {
    private int audioChunkSize;
    private int channels;
    byte[] paddingBuffer;

    private byte[][] channelBuffer;
    private int[] offsets;

    private int minValue;
    private int maxValue;

    public AudioWriter(int audioChunkSize, int channels, int bufferSize,
	    int frameLines) {
	this.audioChunkSize = audioChunkSize;
	this.channels = channels;
	int frameBytes = frameLines * 2;
	int paddingSize = bufferSize - frameBytes * channels;
	channelBuffer = new byte[channels][];
	for (int i = 0; i < channels; i++) {
	    channelBuffer[i] = new byte[frameBytes];
	}
	paddingBuffer = new byte[paddingSize];

	offsets = new int[frameBytes];

	double factor = (audioChunkSize / channels) / (offsets.length * 1.0d);
	for (int i = 0; i < offsets.length; i++) {
	    offsets[i] = ((int) (i * factor)) * channels;
	}

	minValue = Integer.MAX_VALUE;
	maxValue = Integer.MIN_VALUE;
    }

    public void convert(byte[] audio) {
	if (audio == null) {
	    throw new IllegalArgumentException(
		    "Parameter 'audio' must not be null.");
	}
	if (audio.length > audioChunkSize) {
	    throw new IllegalArgumentException("ERROR: Audio chunk has "
			    + audio.length
			    + " bytes and is larger than the defined audio chunk size of "
			    + audioChunkSize + " bytes.");
	}
	for (int c = 0; c < channels; c++) {
	    for (int i = 0; i < offsets.length; i++) {
		int value;
		try {
		    value = (audio[offsets[i] + c] & 0xFF);
		} catch (ArrayIndexOutOfBoundsException ex) {
		    value = 0x80; // Last chunk may be smaller
		}
		if (value < minValue) {
		    minValue = value;
		} else if (value > maxValue) {
		    maxValue = value;
		}
		value = ((value >>> 4) | 0x10);
		// value = c;
		channelBuffer[c][i] = (byte) value;
	    }
	}
    }

    public void saveBank(OutputStream outputStream) throws IOException {
	if (outputStream == null) {
	    throw new IllegalArgumentException(
		    "Parameter 'outputStream' must not be null.");
	}
	for (int c = 0; c < channels; c++) {
	    outputStream.write(channelBuffer[c]);
	}
	outputStream.write(paddingBuffer);
    }

    public int getMinValue() {
	return minValue;
    }

    public int getMaxValue() {
	return maxValue;
    }

}
