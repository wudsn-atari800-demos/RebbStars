;
;	>>> RebbStars by JAC! <<<
;
;	Triple speed sound test with and without buffering.

buffer_mode = 1

	org $2000
	icl "RebbStars-Kernel-Equates.asm"
	icl "snd/RebbStars-Sound.asm"


	org $3000
start

	ldx #<sound.module		;Low byte of RMT module to X reg
	ldy #>sound.module		;High byte of RMT module to Y reg
	lda #0				;Starting song line 0-255 to A reg
	jsr sound.init

;Init returns instrument speed (1..4 => from 1/screen to 4/screen)

loop
	.if buffer_mode = 1
	jsr vbi
	.endif

	base = 16
	speed = 52

	.rept 3
	lda #base+speed*#
	cmp VCOUNT				;vertical line counter synchro
	bne *-3
	lda #$34
	sta $d01a

	.if buffer_mode = 1
	jsr sound.buffer.copy_from_buffer
	.else
	jsr sound.play
	.endif

	mva #0 $d01a
	.endr

	jmp loop				;no => loop

	.proc vbi
	
	.if buffer_mode = 1
	lda sound.buffer.copy_to_buffer.count
	cmp sound.buffer.copy_from_buffer.count
	seq
	.byte 2
	
	mva #14 $d01a
	jsr sound.play
	jsr sound.buffer.copy_to_buffer
	jsr sound.play
	jsr sound.buffer.copy_to_buffer
	jsr sound.play
	jsr sound.buffer.copy_to_buffer
	
	lda sound.buffer.copy_to_buffer.count
	sta sound.buffer.copy_from_buffer.count
	cmp sound.buffer.copy_from_buffer.count
	seq
	.byte 2
	mva #$00 $d01a
	.endif

	rts
	.endp
;
;
;
tabpp  dta 156,78,52,39			        ;line counter spacing table for instrument speed from 1 to 4
;
;
	run start			        ;run addr
;
;that's all... ;-)

