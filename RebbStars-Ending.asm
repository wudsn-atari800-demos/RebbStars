;
;	>>> RebbStars by JAC! <<<
;
;	@com.wudsn.ide.asm.mainsourcefile=RebbStars-Main.asm

	.proc ending
	
	sei				;Disable OS
	lda #0
	sta nmien
	ldx #8
clear_pokey
	sta $d200,x
	dex
	bne clear_pokey

	mva #$fe portb

	jsr copy_colors
	jsr copy_screen

	mva #$ff portb			;Enable OS
	mva #$40 nmien
	cli
	jsr print_message
	jmp *

;===============================================================

	.proc copy_colors
	ldx #8
loop	lda backup_colors,x
	sta pcolor0,x
	dex
	bpl loop
	rts
	.endp

;===============================================================
	.proc copy_screen


	.proc copy_sm
	mwa backup_sm p1
	mwa p1 88
	ldx #4
	ldy #0
loop
backup_ptr = *+1
	lda backup_sm+2,y
	sta (p1),y
	iny
	bne loop
	inc backup_ptr+1
	inc p1+1
	dex
	bne loop	
	.endp

	.proc copy_dl
	mwa backup_dl p1
	mwa p1 560
	ldx #4
	ldy #0
loop
backup_ptr = *+1
	lda backup_dl+2,y
	sta (p1),y

	iny
	bne loop
	inc backup_ptr+1
	inc p1+1
	dex
	bne loop	
	.endp

	rts
	.endp

;===============================================================

	.proc print_message

index = *+1
loop	ldx #0
	lda text,x
	beq return
	jsr print_char
	inc index
	jmp loop
return	rts

	.local text
	.byte $9b,'REBBSTAR.XEX failed returncode 1337.',$9b
	.byte 0 
	.endl

	.proc print_char
	sta temp
	lda $e407			;Beter user $0346/$0347 next time
	pha
	lda $e406
	pha
temp = *+1
	lda #0
	rts
	.endp				;End of print_char
	.endp				;End of print_message

;===============================================================

	.endp
