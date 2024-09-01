package com.wudsn.productions.atari800.rebbstars;

import java.io.IOException;
import java.io.OutputStream;

final class HeaderWriter {
    private byte[] cartridgeHeader;

    public HeaderWriter(int startBank) {
	int i = 0;
	cartridgeHeader = new byte[32];
	cartridgeHeader[i++] = (byte) 0xa9; // lda #4 // 16k module
	cartridgeHeader[i++] = (byte) 0x04;
	cartridgeHeader[i++] = (byte) 0x9d; // sta $d5a5
	cartridgeHeader[i++] = (byte) 0xa0;
	cartridgeHeader[i++] = (byte) 0xd5;
	cartridgeHeader[i++] = (byte) 0xa9; // lda #<START_BANK
	cartridgeHeader[i++] = (byte) (startBank & 0xFF);
	cartridgeHeader[i++] = (byte) 0x9d; // sta $d5a0
	cartridgeHeader[i++] = (byte) 0xa0;
	cartridgeHeader[i++] = (byte) 0xd5;
	cartridgeHeader[i++] = (byte) 0xa9; // lda #>START_BANK
	cartridgeHeader[i++] = (byte) (startBank / 256);
	cartridgeHeader[i++] = (byte) 0x9d; // sta $d5a1
	cartridgeHeader[i++] = (byte) 0xa1;
	cartridgeHeader[i++] = (byte) 0xd5;
	cartridgeHeader[i++] = (byte) 0x6c; // jmp ($bffe)
	cartridgeHeader[i++] = (byte) 0xfe;
	cartridgeHeader[i++] = (byte) 0xbf;
	if (i > 0x1a) {
	    throw new IllegalStateException("Index is " + i + ".");
	}

	cartridgeHeader[0x1a] = (byte) 0x00; // Cartridge start address (cartcs)
	cartridgeHeader[0x1b] = (byte) 0x00;
	cartridgeHeader[0x1c] = (byte) 0x00; // Indicate there is a cartridge
	cartridgeHeader[0x1d] = (byte) 0x04; // Normal cartridge, call cartad
					     // and
					     // cartcs (cartfg)
	cartridgeHeader[0x1e] = (byte) 0xe0; // Cartridge init address (cartad)
	cartridgeHeader[0x1f] = (byte) 0xbf;
    }

    public int getCartridgeHeaderLength() {

	return cartridgeHeader.length;
    }

    public void saveBank(OutputStream outputStream) throws IOException {
	if (outputStream == null) {
	    throw new IllegalArgumentException(
		    "Parameter 'outputStream' must not be null.");
	}
	outputStream.write(cartridgeHeader);
    }
}
