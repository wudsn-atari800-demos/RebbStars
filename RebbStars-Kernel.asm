;
;	>>> RebbStars by JAC! <<<
;
;	@com.wudsn.ide.asm.mainsourcefile=RebbStars-Main.asm


;===============================================================

	empty_procedure 	= fill_memory.return

;===============================================================

;	Use as "m_fill_memory start length value", or "m_fill_memory start length" to use the current value of fill_memory.value
	.macro m_fill_memory
	.if :0=3
	mva #:3 fill_memory.value
	.endif
	
	.if (:1 & $ff == 0)
	.if (:2 & $ff == 0)
		lda #>[:1]
		ldx #>[:2]
		jsr fill_memory.fill_page_ax
	.else
		lda #>[:1]
		ldx #>[:2]
		ldy #<[:2]
		jsr fill_memory.fill_page_axy
	.endif
	.else
		.error "fill page not even ", :1, " ", :2
	.endif
	.endm

	.local fill_memory	;IN: <A>=address high byte, <X>=count high byte, <Y>=count low byte 
fill_page_ax
	ldy #0
fill_page_axy
	sta fill_page_axy_adr+2
	sty fill_page_axy_low+1
	txa
	beq fill_page_axy_low
value = *+1 
	lda #0
	ldy #0
fill_page_axy_adr
	sta $ff00,y
	iny
	bne fill_page_axy_adr
	inc fill_page_axy_adr+2
	dex
	bne fill_page_axy_adr

fill_page_axy_low
	ldx #0
	bne fill_low
	rts

fill_low
	lda fill_page_axy_adr+2
	sta fill_low_adr+2
	lda value
	tay
fill_low_adr
	sta $ff00,y
	iny
	dex
	bne fill_low_adr
return	rts
	.endl

;===============================================================

	.macro m_copy_memory
	mwa #:1 copy_memory.source_adr
	mwa #:2 copy_memory.destination_adr
	mva #<:3 copy_memory.bytes
	mva #>:3 copy_memory.pages
	jsr copy_memory
	.endm

	.local copy_memory
	ldx #0
	stx bytes_count
	ldy #$00
pages = *-1
	beq no_pages
	jsr copy_loop
no_pages
	lda #$00
bytes = *-1
	beq no_bytes
	sta bytes_count
	ldy #1
copy_loop
	lda $ffff,x
source_adr = *-2
	sta $ffff,x
destination_adr = *-2
	inx
	cpx #$00
bytes_count = *-1
	bne copy_loop
	inc source_adr+1
	inc destination_adr+1
	dey
	bne copy_loop
no_bytes
	rts
	.endl

;===============================================================

	.proc sync.vcount
sync1	lda :vcount
	bne sync1
sync2	lda :vcount
	beq sync2 
	rts
	.endp

	.proc sync.cnt
	lda :cnt
loop	cmp :cnt
	beq loop
	rts
	.endp

;===============================================================
	.proc wait
;
;	.proc cnt	;IN: <A>=number of frames
;	clc
;	adc cnt
;	jmp sync.cnt.loop
;	.endp

;	.proc vcount	;IN: <X>=number of frames
;loop	jsr sync.vcount
;	dex
;	bne loop
;	rts
;	.endp

	.endp

;===============================================================

	.proc add_byte_to_pointer	;IN: <A>=byte, <X>=pointer address in zeropage
	pha
	clc
	adc $00,x
	sta $00,x
	scc
	inc $01,x
	pla
	rts
	.endp

;===============================================================

	.macro m_init_squares
	lda #<:1
	ldx #>:1
	ldy #:2
	jsr init_squares
	.endm

	.proc init_squares	;IN: <A>=callback lo, <X>=callback hi, <Y>=number of right shifts
	square_value = p1
	shifted_value = p2

	sta callback_adr+1
	stx callback_adr+2
	sty shift_count+1

	ldx #0
	stx square_value
	stx square_value+1
loop	mwa square_value shifted_value
shift_count
	ldy #5
	beq shift_loop_end
shift_loop
	lsr shifted_value+1
	ror shifted_value
	dey
	bne shift_loop
shift_loop_end
callback_adr
	jsr empty_procedure
	txa			;Add <X>*2+1
	bpl no_inc_2
	inc square_value+1
no_inc_2
	asl
	sec
	adc square_value
	sta square_value
	bcc no_inc
	inc square_value+1
no_inc	inx
	bne loop
	rts
	.endp

