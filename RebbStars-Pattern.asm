
;	>>> RebbStars by JAC! <<<
;
;	@com.wudsn.ide.asm.mainsourcefile=RebbStars-Main.asm

	.proc pattern

;===============================================================

	.proc init
	ldx #0
	mwa #pattern_sm p1
loop	lda p1
	sta pattern_llo,x
	sta pattern_llo+1,x
	clc
	adc #pattern_sm_width
	sta p1
	lda p1+1
	sta pattern_lhi,x
	sta pattern_lhi+1,x
	adc #0
	sta p1+1
	inx
	inx
	cpx #pattern_sm_lines
	bne loop

	ldx #0
loop_cmap
	txa
	and #127
	cmp #64
	scc
	eor #127
	sta pattern_cmap,x
	inx
	bne loop_cmap

	jsr animate
	lda #0
	jsr animate_pattern_lines.init_next_variant.with_id
	jsr animate_pattern_charset
	rts
	.endp

;===============================================================

	.proc animate

	ldx #0
loop	lda #ldl_type.pattern
	sta ldl,x
	txa
	sta ldl_parameter,x
	inx
	cpx #pattern_sm_lines
	bcc loop
	jsr animate_fade
	rts

;===============================================================

	.proc animate_fade

	.enum state
	fade_stopped, fade_up, fade_up_completed, fade_down, fade_down_completed
	.ende
	
	ldx fade_offset
	lda fade_state
	cmp #state.fade_stopped
	beq set_colors			;No change

	lda fade_state
	cmp #state.fade_up_completed
	beq set_colors			;No change
	cmp #state.fade_down_completed
	beq set_colors			;No change

	lda cnt
	and #1
	beq set_colors			;No change

	ldx fade_offset
	lda fade_state
	cmp #state.fade_down
	beq fade_down

	cpx #$00
	beq fade_up_completed
	dex
	stx fade_offset
	jmp set_colors

fade_up_completed
	mva #state.fade_up_completed fade_state
	jmp set_colors

fade_down
	cpx #colors.steps
	bne fade_down_not_completed
	dec fade_offset
	mva #state.fade_down_completed fade_state
	lda fade_mirror
	eor #1
	sta fade_mirror
	rts

fade_down_not_completed
	inc fade_offset
	jmp set_colors

	.proc set_colors

	lda fade_mirror
	bne set_colors_mirrored
	ldy #0
loop	lda colors,x
	sta pattern_colors,y
	sta pattern_colors+1,y
	inx
	iny
	iny
	cpy #pattern_sm_lines
	bne loop
	rts
	.endp

	.proc set_colors_mirrored
	ldy #pattern_sm_lines-2
loop	lda colors,x
	sta pattern_colors,y
	sta pattern_colors+1,y
	inx
	dey
	dey
	bpl loop
	rts
	.endp


	.local colors
	steps = .len colors - [pattern_sm_lines/2]

	.byte 0,4,6,8,10,12,14,14,12,10,8,6,4
	.byte 0,2,4,6,8,10,12,10,8,6,4,2
	.byte 0,2,4,6,8,10,8,6,4,2
	.byte 0,2,4,6,8,6,4,2
	.byte 0,2,4,6,4,2
	.byte 0,2,4,2
	.byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2
	.endl

fade_state	.byte state.fade_stopped	;State machine state
fade_offset	.byte colors.steps		;Offset in colors
fade_mirror	.byte 0

	m_info colors
	.endp				;End of animate_fill

	.endp				;End of animate

;===============================================================

	.proc animate_pattern_charset
	.var pattern_dli_chr1 .byte
	.var pattern_dli_chr2 .byte

	lda animate.animate_fade.fade_state;Wait till fading is over
	cmp #animate.animate_fade.state.fade_up_completed
	beq wait_next_pattern
	cmp #animate.animate_fade.state.fade_down_completed
	beq start_next_pattern
	rts

wait_next_pattern
	lda pattern_chr_delay
	beq no_delay
	dec pattern_chr_delay
	rts
no_delay
	mva #animate.animate_fade.state.fade_down animate.animate_fade.fade_state
	rts

start_next_pattern
	inc pattern_chr_cnt
	lda pattern_chr_cnt
	and #3
	asl
	asl
	asl
	adc #>pattern_chr
	sta pattern_dli_chr1
	eor #4
	sta pattern_dli_chr2

	ldx #0
	lda pattern_dli_chr1
chr_loop
	sta pattern_chrs,x
	eor #4
	inx
	cpx #pattern_sm_lines
	bne chr_loop

	lda pattern_dli_chr1
	ldx #>pattern_chr1
	jsr copy_charset
	lda pattern_dli_chr2
	ldx #>pattern_chr2
	jsr copy_charset

	mva #animate.animate_fade.state.fade_up animate.animate_fade.fade_state
	mva #128 pattern_chr_delay

	jsr animate_pattern_lines.init_next_variant

return	rts

;===============================================================

	.proc copy_charset		;Create linear version of charset, IN: <A>=source chr high byte, <X>=target char high byte
	sta p1+1
	stx p2+1	
	ldy #0
	sty p1
	sty p2
line_loop
	ldx #0
char_loop
	lda (p1),y
	sta (p2),y
	adw p1 #8
	inw p2
	inx
	bpl char_loop
	sbw p1 #$400
	inc p1

	lda p1
	and #7
	bne line_loop
	rts
	.endp

pattern_chr_delay 	.byte 0		;Number of delay frames
pattern_chr_cnt 	.byte -1	;Number of the current pattern (0..3)

	.endp

;===============================================================
	.proc animate_pattern_lines

variant .byte 0

	.proc init_next_variant

	lda random			; Next variant
	and #1
with_id	sta variant

	.proc init_next_plasma
retry_speed
	lda #3
	jsr get_random
	sta plasma_sx			;Speed for x 1..4
	lda #3
	jsr get_random
	sta plasma_sy			;Speed for y 1..4
	clc
	adc plasma_sx
	cmp #3
	bcc retry_speed

	lda #7
	jsr get_random
	adc #1
	sta plasma_dx			;Delta for x (variant1) 1..8
	lda #7
	jsr get_random
	adc #1
	sta plasma_dy			;Delta for y 1..8
	.endp
	
	.proc init_next_twirl
	lda #3
	jsr get_random
	clc
	adc #1
	lsr random
	bcs not_negative
	eor #$ff
	adc #$1
not_negative
	sta twirl_sr			;Speed 2...5, -2...-5
	lda random
	and #1
	sta twirl_or			;Offset 0..1
	.endp

	rts
	
	.proc get_random
	and random
	clc
	adc #1
	rts
	.endp
					;End of get_random
	.endp				;End of init_next_variant

;===============================================================

	.proc generate_pattern_lines
	ldx variant
	jeq plasma
	dex
	jeq twirl
	.byte 2

;===============================================================

	.proc plasma

	.macro m_animate_pattern_line line
	.if :line <2 .or :line > 4
	mwa #[pattern_sm+:line*pattern_sm_width] fill_pattern_line.sm_ptr1
	mwa #[pattern_sm+:line*pattern_sm_width+1] fill_pattern_line.sm_ptr2
	jsr fill_pattern_line
	.endif
	.endm

	mva plasma_y fill_pattern_line.offset_y
	mva plasma_dx fill_pattern_line.delta_x
	ldy #0
	.rept pattern_lines
	mva plasma_x fill_pattern_line.offset_x
	m_animate_pattern_line #
	adb fill_pattern_line.offset_y plasma_dy
	.endr
	
	adb plasma_y plasma_sx
	adb plasma_x plasma_sy
	rts



	.proc fill_pattern_line
offset_y = *+1
	mva sinus offset_y_copy
	
	ldx #1
	clc
fill_loop
offset_y_copy = *+1
	lda #0
offset_x = *+1
	adc sinus
	tay
	lda pattern_cmap,y
sm_ptr1 = *+1
	sta pattern_sm,x
	ora #$40
sm_ptr2	= *+1
	sta pattern_sm+1,x
	lda offset_x
delta_x = *+1
	adc #0
	sta offset_x
	inx
	inx
	cpx #pattern_sm_width-1
	bcc fill_loop
	rts
	
	.endp		;End of fill_pattern_line

	.align $100
	.local sinus
:2	.byte sin(64,64,256)
	.endl
 
	.local presets
sx	.byte 
sy	.byte 
dx	.byte 
dy	.byte 
	.endl

	.endp		;End of plasma

;===============================================================

	.proc twirl

	.macro m_animate_pattern_line line
	.if :line <2 .or :line > 4
	mwa #[twirl_data+:line*pattern_sm_width] fill_pattern_line.spiral_ptr
	mwa #[pattern_sm+:line*pattern_sm_width] fill_pattern_line.sm_ptr1
	mwa #[pattern_sm+:line*pattern_sm_width+1] fill_pattern_line.sm_ptr2
	jsr fill_pattern_line
	.endif
	.endm

	adb twirl_x twirl_sr
	sta fill_pattern_line.offset

	.rept pattern_lines
	m_animate_pattern_line #
	.endr
	rts

	.proc fill_pattern_line
	ldx #0
	adb spiral_ptr twirl_or
	clc
fill_loop
offset	= *+1
	lda #0
spiral_ptr = *+1
	adc twirl_data,x
	tay
	lda pattern_cmap,y
sm_ptr1	= *+1
	sta pattern_sm,x
	ora #$40
sm_ptr2	=*+1
	sta pattern_sm+1,x
	inx
	inx
	cpx #pattern_sm_width
	bne fill_loop
	rts
	
	.endp				;End of fill_pattern_line

	.local twirl_data
	.byte 112,239,113,235,114,231,115,227,116,224,117,221,119,219,120,217,121,216,123,216,125,216,126,216,0,90,1,91,3,94,4,97,6,101,8,105,9,109,10,114,11,119,13,125,14,131,15,137,110,229,111,224,112,220,113,216,115,212,116,209,117,206,119,204,120,203,122,202,124,203,126,204,0,77,1,79,3,82,5,85,7,90,9,94,10,99,12,105,13,110,14,117,15,123,16,129,109,219,109,214,110,209,112,205,113,201,114,197,116,194,117,192,119,190,121,189,123,189,126,190,0,64,2,66,4,70,6,74,8,79,10,85,12,90,13,96,15,103,16,109,17,116,18,123,107,210,107,204,108,199,109,194,110,189,112,185,113,181,115,179,117,177,120,176,122,176,125,177,0,51,2,54,5,59,8,64,10,70,12,76,14,82,16,89,17,96,18,103,19,110,20,117,104,202,105,196,106,190,107,184,108,179,109,174,110,169,112,166,115,163,117,162,120,161,124,163,0,38,3,42,7,48,10,55,13,61,15,69,17,76,19,84,20,91,21,98,22,106,23,114,102,195,102,189,103,182,103,175,104,169,105,164,107,158,108,154,110,150,113,147,117,147,122,149,0,25,5,32,10,40,14,48,17,57,19,65,21,72,22,81,23,88,24,96,25,104,25,112,99,190,99,183,99,175,100,168,100,161,101,155,102,148,103,142,104,137,107,132,110,130,117,132,0,12,10,25,17,37,21,46,23,56,25,64,26,72,27,81,27,88,28,96,28,104,28,112,96,186,96,178,96,171,96,163,96,156,96,148,96,141,96,133,96,126,96,118,96,111,96,103,64,64,32,39,32,47,32,54,32,62,32,69,32,77,32,84,32,92,32,99,32,107,32,114,93,184,93,176,93,169,92,161,92,153,91,145,90,137,89,129,88,120,85,111,82,101,75,89,64,76,53,67,46,65,42,68,40,72,38,78,37,84,36,90,36,97,35,104,35,111,35,118,90,184,90,176,89,168,89,161,88,153,87,145,85,137,84,129,82,121,79,113,75,104,70,96,64,89,58,84,53,82,49,83,46,85,44,89,42,94,41,99,40,105,39,111,38,117,38,124,88,186,87,178,86,170,85,163,84,155,83,148,82,141,80,133,77,126,75,119,72,113,68,107,64,102,60,99,56,97,53,97,50,99,48,101,46,105,44,109,43,114,42,120,41,125,40,131,85,189,85,182,84,175,83,168,82,161,80,154,79,147,77,140,75,134,72,128,70,123,67,119,64,115,61,113,58,111,55,111,53,112,51,114,49,117,47,121,46,125,45,130,44,135,43,140,83,194,83,187,82,180,80,173,79,167,78,161,76,155,75,149,73,144,71,139,69,135,66,131,64,128,61,126,59,125,57,125,55,126,53,127,51,130,50,133,48,136,47,140,46,144,45,149,82,200,81,194,80,187,79,181,77,175,76,169,75,164,73,159,72,154,70,150,68,146,66,143,64,141,62,139,60,138,58,138,56,138,54,140,53,142,51,144,50,148,49,151,48,155,47,160
	.endl
	m_info twirl_data

	.endp				;End of twirl

;===============================================================

	.endp				;End of generate_pattern_lines

	.endp				;End of animate_pattern_lines


;===============================================================

	.proc generate_dl_line		;IN: ldl, <X>=ldl index
	poke_dl = screen.animate.poke_dl
	poke_dl.ptr = screen.animate.poke_dl.ptr

	lda #$42+$80			;By default pattern lines have DLIs
	jsr poke_dl
	lda pattern_llo,x
	jsr poke_dl
	lda pattern_lhi,x
	jsr poke_dl
	m_set_dli_tab dli.pattern_chr_line
	rts
	.endp				;End of generate_line


;===============================================================

	.proc dli

	.proc pattern_chr_line
	ldx pattern_dli_cnt
	sta wsync
	lda pattern_chrs,x
	sta chbase
	lda pattern_colors,x
	sta colpf1
	inc pattern_dli_cnt
	jmp dli.next_dli
	.endp

	.endp
;===============================================================

	.endp		;End of pattern

	m_info pattern