;
;	>>> RebbStars by JAC! <<<
;
;	@com.wudsn.ide.asm.mainsourcefile=RebbStars-Main.asm

	.enum ldl_type			;Type of logical DL
	empty = 0
	pattern = 1
	logo = 2
	scroll = 3
	termination = $ff
	.ende
	
	.macro m_set_dli_tab		;Sets dli_tab_lo/hi,x to [:1]
	mva #<[:1] dli_tab_lo,x
	mva #>[:1] dli_tab_hi,x
	.endm

	.proc screen

	.proc init
	ldx #0
	lda #ldl_type.empty
loop	sta ldl,x
	inx
	cpx #ldl_lines-1
	bne loop
	lda #ldl_type.termination	;Set termination mark
	sta ldl,x
	
	ldx #dli_tab_lines-1
loop1
	m_set_dli_tab dli.next_dli	;Set empty DLI procedures
	mva #0 dli_tab_snd,x		;Clear sound DLI flags
	dex
	bpl loop1
	
	lda #1
	sta dli_tab_snd+3
	sta dli_tab_snd+16
;	sta dli_tab_snd+29		;This is done in the VBI instead
	rts
	.endp

;===============================================================

	.proc animate			;Create physical dl based on logical DL
	mwa #dl poke_dl.ptr

	lda #$80+$70			;Leading PAL blank area
	jsr poke_dl

	mva #0 ldl_line
loop	ldx ldl_line			;Check type of each logical line
	lda ldl,x
	bmi done			;Termination mark
	beq generate_empty_dl_line
	cmp #ldl_type.pattern
	beq generate_pattern_dl_line
	cmp #ldl_type.logo
	beq generate_logo_dl_line
	cmp #ldl_type.scroll
	beq generate_scroller_dl_line
	.byte 2				;JAM in case of error

;===============================================================

	.proc generate_empty_dl_line
	lda #$70
	jsr poke_dl
	jmp next
	.endp

;===============================================================

	.proc generate_pattern_dl_line
	jsr pattern.generate_dl_line
	jmp next
	.endp

;===============================================================

	.proc generate_logo_dl_line
	jsr logo.generate_dl_line
	jmp next
	.endp

;===============================================================
	.proc generate_scroller_dl_line
	jsr scroller.generate_dl_line
	.endp
next
	inc ldl_line
	jmp loop

done	jsr poke_dl_end
	rts

;===============================================================

	.proc poke_dl		;IN: <A>=byte to store in the DL
ptr=*+1
	sta dl
	inw ptr
	rts
	.endp			;End of poke_dl

;===============================================================

	.proc poke_dl_end	;IN: <X>=ldl_line
	lda #$41
	jsr poke_dl
	lda #<dl
	jsr poke_dl
	lda #>dl
	jsr poke_dl
	m_set_dli_tab dli.none_line
	rts
	.endp			;End of poke_dl_end

	.endp			;End of animate

	.endp			;End of screen

	m_info screen