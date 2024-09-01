
;	>>> RebbStars by JAC! <<<
;
;	@com.wudsn.ide.asm.mainsourcefile=RebbStars-Main.asm

	.proc scroller

;===============================================================

	.proc init
	jsr init_chr
	jsr init_text
	jsr init_tsm
	lda #0
	sta scroller_xcnt
	sta scroller_ccnt
	sta scroller_ycnt
	rts

;===============================================================

	.proc init_chr
	
	ldx #0
loop
	.rept 4
	lda scroller_chr+#*$100,x
	asl
	sta scroller_chr1+#*$100,x
	.endr
	inx
	bne loop
	rts
	.endp			;End of init_chr

;===============================================================

	.proc init_text
	lda #<scroller_text
	sta scroller_ptr
	sta p1
	lda #>scroller_text
	sta scroller_ptr+1
	sta p1+1

	ldy #0
char_loop
	lda (p1),y
	bmi done
	ldx #[.len text_encoding]-1
encoding_loop
	cmp text_encoding,x
	beq found
	dex
	bpl encoding_loop
	.byte 2
found	txa
	asl
	sta (p1),y
	inw p1
	jmp char_loop

done	rts
	
	.local text_encoding	;U="up", "L"=left, "W"=whitespace, "G"=GP
	.byte ' abcdefghijklmnopqrstuvwxyz[&]ULW!"G$%&''()*+,-./0123456789:;W=W?'
	.endl

	m_info text_encoding
	.endp			;End of init_text

;===============================================================

	.proc init_tsm
	lda #0
	tax
loop	sta scroller_tsm,x
	inx
	bne loop
	rts
	.endp

	.endp			;End of init

;===============================================================

	.proc animate

	lda flash_delay
	beq do_flash
	dec flash_delay
	rts

do_flash
	clc
	lda flash_add
	cmp #$ff
	beq do_flash_end
	inc flash_add
	jmp do_flash_next
do_flash_end
	cmp flash_done
	beq do_flash_next
	lsr logo.animate.flash_lock	;Unlock logo fading
	sta flash_done
do_flash_next
	sec
	adc flash_cnt
	sta flash_cnt
	bcc do_not_show
do_show

	jsr vertical
do_not_show

	lda flash_done
	beq horizontal.no_move
	bne horizontal

flash_delay	.byte 200
flash_cnt	.byte 0
flash_add	.byte 128
flash_done	.byte 0

;===============================================================

	.proc vertical
	lda scroller_ycnt
	clc
	adc #8			;Taken from orignal frame 105 vs. 113
	and #127
	tax
	lda scroller_sin,x
	clc
	adc #90
	pha
	lsr
	lsr
	lsr
	clc
	tax
	stx scroller_screen.ldl_line

	lda #ldl_type.scroll
	sta ldl,x
	lda #0
	sta ldl_parameter,x
	inx
	lda #ldl_type.scroll
	sta ldl,x
	lda #1
	sta ldl_parameter,x
	inx
	lda #ldl_type.scroll
	sta ldl,x
	lda #2
	sta ldl_parameter,x

	pla
	and #7
	sta scroller_screen.fine_delay

	inc scroller_ycnt
	rts
	.endp			;End of vertical

;===============================================================

	.proc horizontal
	dec scroller_xcnt
no_move	lda scroller_xcnt
	and #7
	lsr
	sta scroller_screen.hscrol
	lda #>scroller_chr
	scs
	lda #>scroller_chr1
	sta scroller_screen.chbase

	lda scroller_xcnt	;Fine scrolling for 1 char completed?
	and #7
	cmp #7
	bne no_next_char

	inc scroller_ccnt	;Scroll LMS address offset
	lda scroller_ccnt
	cmp #scroller_sm_width
	sne
	lda #0
	sta scroller_ccnt
	tax

	ldy #0			;Print character to SM...
warp_around
	lda (scroller_ptr),y
	bpl no_wrap_around
	mwa #scroller_text scroller_ptr
	jmp warp_around

no_wrap_around
	inw scroller_ptr

	sta scroller_tsm+scroller_sm_width*0,x	;Two lines with warp around buffer
	sta scroller_tsm+scroller_sm_width*1,x
	ora #1
	sta scroller_tsm+scroller_sm_width*2,x
	sta scroller_tsm+scroller_sm_width*3,x

no_next_char
	rts
	.endp			;End of horizontal

	.endp			;End of animate

;===============================================================

	.proc generate_dl_line		;IN: ldl, <X>=ldl index
	poke_dl = screen.animate.poke_dl
	poke_dl.ptr = screen.animate.poke_dl.ptr
	.var hsm_ptr .word

	lda ldl_parameter,x		;First logical line?
	jne not_first

	lda pattern_chrs+1,x		;Select charset for pattern continuation DLI	
	sta dli.scroller_line_last.dli_chr


	mwa #scroller_hsm1 hsm_ptr	;Set HSM buffer pointer to start address

	ldy scroller_screen.fine_delay	;Fine delay
	beq fine_upper_loop_skip

fine_upper_loop
	lda #$4f
	jsr poke_dl
	lda hsm_ptr
	jsr poke_dl
	lda hsm_ptr+1
	jsr poke_dl
	adw hsm_ptr #scroller_sm_width
	dey
	bne fine_upper_loop
fine_upper_loop_skip

	lda #$10			;Upper padding
	jsr poke_dl

	lda #$52+$80			;Scroller line 1
;	lda #$5f+$80			;For equidistant height test
	jsr poke_dl
	lda scroller_ccnt
	jsr poke_dl
	lda #>scroller_tsm
	jsr poke_dl
;	lda #$20			;For equidistant height test
;	jsr poke_dl

	
	mva scroller_screen.hscrol     dli.scroller_line_first.screen_hscrol
	mva scroller_screen.chbase     dli.scroller_line_first.screen_chbase
	mva scroller_screen.fine_delay dli.scroller_line_first.screen_fine_delay
	beq without_fine_delay
	m_set_dli_tab dli.scroller_line_first
	rts

without_fine_delay
	m_set_dli_tab dli.scroller_line_first.without_fine_delay
	rts

not_first
	cmp #1
	bne not_second
	lda #$52+$80			;Scroller line 2
	jsr poke_dl
	lda scroller_ccnt
	clc
	adc #scroller_sm_width*2
	jsr poke_dl
	lda #>scroller_tsm
	jsr poke_dl
	m_set_dli_tab dli.scroller_line_second
	rts

not_second
	lda #$10			;Lower padding
	jsr poke_dl

	sec
	lda #8
	sbc scroller_screen.fine_delay	;Fine delay
	sta dli.scroller_line_last.screen_fine_delay
	tay
	
	mwa #scroller_hsm2 hsm_ptr	;Set HSM buffer pointer to start address
fine_lower_loop
	lda #$4f
	jsr poke_dl
	lda hsm_ptr
	jsr poke_dl
	lda hsm_ptr+1
	jsr poke_dl
	adw hsm_ptr #scroller_sm_width
	dey
	bne fine_lower_loop

	m_set_dli_tab dli.scroller_line_last
	rts

	.endp				;End of generate_dl

;===============================================================

	.proc generate_hsm		;Generate Hires padding screen memory content

;---------------------------------------------------------------
	.macro m_generate_hsm_char position pattern_adr lines
	.if :position = 1
	.rept :lines
	lda :pattern_adr+[#]*$80,x
	sta scroller_hsm1+[#]*scroller_sm_width,y
	.endr
	.else
	.rept :lines
	lda :pattern_adr+[8-:lines+#]*$80,x
	sta scroller_hsm2+[#]*scroller_sm_width,y
	.endr
	.endif
	.endm

;---------------------------------------------------------------
	.macro m_generate_hsm_line position pattern_adr lines
	ldy #scroller_sm_width-1
loop
	.byte $b3,scroller_pattern_ptr		;lax (p1),y

	m_generate_hsm_char :position :pattern_adr :lines

	dey
	bpl loop
	.endm

;---------------------------------------------------------------
	.macro m_generate_hsm position	;IN: <C>=0 for chr1, 1 for char2, <A>=fine_delay (0..7)
	jcs use_pattern_chr2

use_pattern_chr1
	cmp #0
	bne chr1_1
	m_generate_hsm_line :position pattern_chr1 1
	jmp skip
chr1_1	cmp #1
	bne chr1_2
	m_generate_hsm_line :position pattern_chr1 2
	jmp skip
chr1_2	cmp #2
	bne chr1_3
	m_generate_hsm_line :position pattern_chr1 3
	jmp skip
chr1_3	cmp #3
	bne chr1_4
	m_generate_hsm_line :position pattern_chr1 4
	jmp skip
chr1_4	cmp #4
	bne chr1_5
	m_generate_hsm_line :position pattern_chr1 5
	jmp skip
chr1_5	cmp #5
	bne chr1_6
	m_generate_hsm_line :position pattern_chr1 6
	jmp skip
chr1_6	cmp #6
	bne chr1_7
	m_generate_hsm_line :position pattern_chr1 7
	jmp skip
chr1_7	m_generate_hsm_line :position pattern_chr1 8
	jmp skip

use_pattern_chr2
	cmp #0
	bne chr2_1
	m_generate_hsm_line :position pattern_chr2 1
	jmp skip
chr2_1	cmp #1
	bne chr2_2
	m_generate_hsm_line :position pattern_chr2 2
	jmp skip
chr2_2	cmp #2
	bne chr2_3
	m_generate_hsm_line :position pattern_chr2 3
	jmp skip
chr2_3	cmp #3
	bne chr2_4
	m_generate_hsm_line :position pattern_chr2 4
	jmp skip
chr2_4	cmp #4
	bne chr2_5
	m_generate_hsm_line :position pattern_chr2 5
	jmp skip
chr2_5	cmp #5
	bne chr2_6
	m_generate_hsm_line :position pattern_chr2 6
	jmp skip
chr2_6	cmp #6
	bne chr2_7
	m_generate_hsm_line :position pattern_chr2 7
	jmp skip
chr2_7	m_generate_hsm_line :position pattern_chr2 8
	jmp skip

skip
	.endm

;---------------------------------------------------------------

	ldy #0

	ldx scroller_screen.ldl_line
	mva pattern_llo,x scroller_pattern_ptr
	mva pattern_lhi,x scroller_pattern_ptr+1
	txa
	lsr
	lda scroller_screen.fine_delay

	m_generate_hsm 1
	
	ldx scroller_screen.ldl_line
	inx
	inx
	mva pattern_llo,x scroller_pattern_ptr
	mva pattern_lhi,x scroller_pattern_ptr+1
	txa
	lsr
	lda scroller_screen.fine_delay
	eor #7
	m_generate_hsm 2
	rts
	.endp

	m_info generate_hsm

;===============================================================

	.proc dli

	.proc scroller_line_first
	ldx pattern_dli_cnt
	sta wsync
	lda pattern_colors,x
	sta colpf1
screen_fine_delay = *+1
	ldx #0
	dex
	beq wsync_loop_end
wsync_loop
	sta wsync
	dex
	bne wsync_loop

wsync_loop_end

without_fine_delay
	lda #palette.separator
	sta wsync
	sta colbk
	sta colpf2			;Set all relevant registers to the same value

screen_hscrol = *+1
	mva #0 hscrol

	lda pattern_dli_cnt
	clc
	adc #2
	sta pattern_dli_cnt

	sta wsync
	lda #palette.scroller_background
	sta colpf2
	sta colbk
screen_chbase = *+1
	mva #>scroller_chr chbase
	mva #palette.scroller_foreground colpf1

	jmp dli.next_dli
	.endp

;===============================================================

	scroller_line_second = dli.next_dli

;===============================================================

	.proc scroller_line_last
dli_chr = *+1
	lda #$ff
	sta wsync
	sta chbase
	ldx pattern_dli_cnt
	lda pattern_colors,x
	inc pattern_dli_cnt
	sta wsync
	sta colpf1
	lda #palette.separator
	sta colpf2			;Set all relevant registers to the same value
	sta colbk
	sty wsync
	lda #palette.pattern_background
	sta colpf2			;Set all relevant registers to the same value
	sta colbk

screen_fine_delay = *+1
	ldx #0
	dex
	beq wsync_loop_end
wsync_loop
	sta wsync
	dex
	bne wsync_loop

wsync_loop_end
	ldx pattern_dli_cnt
	lda pattern_colors,x
	sta wsync
	sta colpf1
	inc pattern_dli_cnt
	jmp dli.next_dli
	.endp			;End of scroller_line_last

	.endp			;End of dli


;===============================================================

	.local scroller_screen

hscrol		.byte 0		;Horizontal fine scroll value (3..0)
chbase		.byte 0		;High byte of charset base
ldl_line	.byte 0		;Number of the LDL line where the scroller starts (0..27)
fine_delay	.byte 0		;Number of lines (0..7) to delay

	.endl			;End of scroller_screen

	.local scroller_text
;	 .byte 'abcdefghijklmnopqrstuvwxyz[&]ULW!"G$%&''()*+,-./0123456789:; = ?'
	.byte 'one day when we grow up we''re going to be rebb stars. '
	.byte 'jac!, rebb and premium finally at revision 2014 afer 3 years of trying. '
	.byte 'this is a tribute to the cracktro style amiga intros we are still in love with. '
	.byte 'thanks to shadow of gp for creating the original "old cranky style" amiga intro '
	.byte 'and allowing me to use some graphics for my demake. if only i had asked for the '
	.byte 'sinus table, too. it would have saved me from from writting a ripper that can rip sinus '
	.byte 'waves from avi recordings :-) '

	.byte 'code by jac! logos by rebb. music by premium. '
	.byte 'greetings to abbuc, abyss, agenda, checkpoint, cosine, desire, dma, grey, mega, genesis projects, lamers, mec, laresistance, mystic bytes, noice, our5oft, oxyron, scarab, svolli, squoquo, taquart, vcsdev and all atari supporters. see you at silly venture 2k14!'
	.byte '                                                  '
	.byte $ff
	.endl

;===============================================================

	.endp			;End of scroller

	m_info scroller