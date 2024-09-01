// Use Virtual DUB with "nearest neighbor filter mode" to force keeping the number of colors.

package com.wudsn.productions.atari800.rebbstars;

import java.io.IOException;
import java.io.InputStream;

final class AVIReader {

    public static abstract class ATOM {
	long position;
	String fourCC;
	int size;
	byte[] data;

	protected ATOM(long position) {
	    this.position = position;
	    fourCC = "????";
	    size = 0;
	    data = null;
	}

    }

    static class CHUNK extends ATOM {

	public CHUNK(long position) {
	    super(position);

	}

	@Override
	public String toString() {
	    return Long.toHexString(position) + " CHUNK: fourCC=" + fourCC
		    + " size=" + Integer.toHexString(size);
	}

    }

    static class LIST extends ATOM {
	String list;

	public LIST(long position) {
	    super(position);
	    list = "????";
	}

	@Override
	public String toString() {
	    return Long.toHexString(position) + " LIST: list=" + list
		    + " fourCC=" + fourCC + " size="
		    + Integer.toHexString(size);
	}

    }

    static class MainAVIHeader {
	int microSecPerFrame; // frame display rate (or 0)
	int maxBytesPerSec; // max. transfer rate
	int paddingGranularity; // pad to multiples of this
	// size;
	int flags; // the ever-present flags
	int totalFrames; // # frames in file
	int initialFrames;
	int streams;
	int suggestedBufferSize;
	int width;
	int height;
	int[] reserved = new int[4];

	@Override
	public String toString() {
	    return "MainAVIHeader: microSecPerFrame=" + microSecPerFrame
		    + " maxBytesPerSec=" + maxBytesPerSec
		    + " paddingGranularity=" + paddingGranularity + " flags="
		    + Integer.toHexString(flags) + " totalFrames="
		    + totalFrames + " initialFrames=" + initialFrames
		    + " streams=" + streams + " suggestedBufferSize="
		    + suggestedBufferSize + " width=" + width + " height="
		    + height;
	}
    }

    private InputStream inputStream;
    private long position;
    private byte[] dwordBuffer;

    public AVIReader(InputStream inputStream) {
	if (inputStream == null) {
	    throw new IllegalArgumentException(
		    "Parameter 'inputStream' must not be null.");
	}
	this.inputStream = inputStream;
	position = 0;
	dwordBuffer = new byte[4];
    }

    public ATOM readAtom() {

	String fourCC = readFourCC();
	if (fourCC.equals("LIST")) {
	    LIST list = new LIST(position);
	    list.list = fourCC;
	    list.size = readDWORD();
	    list.fourCC = readFourCC();
	    return list;
	}
	CHUNK chunk = new CHUNK(position);
	chunk.fourCC = fourCC;
	chunk.size = readDWORD();
	return chunk;
    }

    public void skipAtomData(ATOM atom) {
	if (atom == null) {
	    throw new IllegalArgumentException(
		    "Parameter 'atom' must not be null.");
	}

	int size = atom.size;
	if (atom instanceof LIST) {
	    size = size - 4;
	}
	try {
	    inputStream.skip(size);
	    position += size;
	} catch (IOException ex) {
	    throw new RuntimeException("Cannot skip " + atom.size
		    + " bytes of atom '" + atom.fourCC + "'.");
	}
    }

    public CHUNK readChunk() {

	CHUNK result = new CHUNK(position);

	result.fourCC = readFourCC();
	result.size = readDWORD();

	return result;
    }

    public CHUNK readChunk(String fourCC) {
	if (fourCC == null) {
	    throw new IllegalArgumentException(
		    "Parameter 'fourCC' must not be null.");
	}
	CHUNK result = readChunk();

	if (!fourCC.equals(result.fourCC)) {
	    throw new RuntimeException("FourCC is '" + result.fourCC
		    + "' instead of '" + fourCC + "'.");
	}

	return result;
    }

    public void readChunkData(CHUNK chunk) {
	if (chunk == null) {
	    throw new IllegalArgumentException(
		    "Parameter 'chunk' must not be null.");
	}
	chunk.data = new byte[chunk.size];
	try {
	    inputStream.read(chunk.data);
	    position += chunk.size;
	} catch (IOException ex) {
	    throw new RuntimeException("Cannot read " + chunk.size
		    + " bytes of chunk '" + chunk.fourCC + "'.");
	}

    }

    public LIST readList() {
	LIST result = new LIST(position);

	result.list = readFourCC();
	result.size = readDWORD();
	result.fourCC = readFourCC();

	return result;
    }

    public void readListData(LIST list) {
	if (list == null) {
	    throw new IllegalArgumentException(
		    "Parameter 'list' must not be null.");
	}
	try {

	    list.data = new byte[list.size - 4];
	    inputStream.read(list.data);

	} catch (IOException ex) {
	    throw new RuntimeException("Cannot read " + (list.size - 4)
		    + " bytes of list '" + list.fourCC + "'.");
	}
    }

    public MainAVIHeader readHeader() {
	CHUNK chunk = readChunk("avih");
	MainAVIHeader result = new MainAVIHeader();
	result.microSecPerFrame = readDWORD();
	result.maxBytesPerSec = readDWORD();
	result.paddingGranularity = readDWORD();
	result.flags = readDWORD();
	result.totalFrames = readDWORD();
	result.initialFrames = readDWORD();
	result.streams = readDWORD();
	result.suggestedBufferSize = readDWORD();
	result.width = readDWORD();
	result.height = readDWORD();
	result.reserved[0] = readDWORD();
	result.reserved[1] = readDWORD();
	result.reserved[2] = readDWORD();
	result.reserved[3] = readDWORD();
	position += chunk.size;
	return result;
    }

    private String readFourCC() {
	try {
	    inputStream.read(dwordBuffer);
	    position += 4;
	} catch (IOException ex) {
	    throw new RuntimeException(ex);
	}
	return String.valueOf((char) dwordBuffer[0])
		+ String.valueOf((char) dwordBuffer[1])
		+ String.valueOf((char) dwordBuffer[2])
		+ String.valueOf((char) dwordBuffer[3]);
    }

    private int readDWORD() {
	int result;
	int FF = 0xff;
	try {
	    inputStream.read(dwordBuffer);
	} catch (IOException ex) {
	    throw new RuntimeException(ex);
	}

	result = (dwordBuffer[3] & FF);
	result = result << 8;
	result += (dwordBuffer[2] & FF);
	result = result << 8;
	result += (dwordBuffer[1] & FF);
	result = result << 8;
	result += (dwordBuffer[0] & FF);

	position += 4;
	return result;
    }

}