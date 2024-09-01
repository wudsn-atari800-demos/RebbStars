;
;	>>> RebbStars by JAC! <<<
;
;	@com.wudsn.ide.asm.mainsourcefile=RebbStars-Main.asm

	.proc logo
	
	.proc init
	rts
	.endp

;===============================================================

	.proc animate

	lda flash_lock
	bne return
	lda flash_delay
	beq do_flash
	lda cnt
	and #1
	bne return
	dec flash_delay
return
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
	mvx #pattern.animate.animate_fade.state.fade_down pattern.animate.animate_fade.fade_state
	sta flash_done
do_flash_next
	sec
	adc flash_cnt
	sta flash_cnt
	bcc do_not_show
do_show
	ldx #2
	.rept logo_lines
	lda #ldl_type.logo
	sta ldl,x
	lda #[#]
	sta ldl_parameter,x
	inx
	.endr

do_not_show
	lda flash_done
	beq not_done
	jmp animate_logo_content

not_done
	ldx animate_logo_content.fade_offset
	jmp animate_logo_content.fade_set_colors


flash_lock	.byte 1
flash_delay	.byte 250
flash_cnt	.byte 0
flash_add	.byte 128
flash_done	.byte 0

;===============================================================

	.proc animate_logo_content
	lda cnt
	and #1
	beq fade_step
	rts

fade_step
	lda fade_delay
	beq fade_up_or_down
	dec fade_delay
	rts

fade_up_or_down
	ldx fade_offset
	lda fade_direction
	beq fade_up
	
	cpx #$ff
	bne fade_down_not_completed

	inc fade_logo
	lda fade_logo
	and #3
	asl
	asl
	asl
	asl
	adc #>logo_sm
	sta logo_screen.logo_dl.lms+1

	inc fade_offset
	mva #0 fade_direction
	mva #10 fade_delay
	lda fade_chroma
no_black
	clc
	adc #$10
	cmp #palette.logo_chroma_end+1
	scc
	lda #palette.logo_chroma_start
	sta fade_chroma
	rts

fade_down_not_completed
	dec fade_offset
	jmp fade_set_colors

fade_up
	cpx #colors.steps
	bne fade_up_not_completed
	dec fade_offset
	mva #1 fade_direction
	mva #250 fade_delay
	rts

fade_up_not_completed
	inc fade_offset

fade_set_colors
	lda fade_chroma
	cpx #0
	sne
	lda #$00

	ora colors.color1,x
	sta dli.logo_line_first.color1
	and #$f0
	ora colors.color2,x
	sta dli.logo_line_first.color2
	and #$f0
	ora colors.color3,x
	sta dli.logo_line_first.color3
	rts

fade_logo	.byte 0
fade_delay	.byte 100		;Number of inital delay frames
fade_offset	.byte colors.steps-1	;Offset in colors
fade_direction	.byte 0			;Fade direction: 0=up, 1=down
fade_chroma	.byte palette.logo_chroma_start


	.local colors
steps	= $0e

;	      01,02,03,04,05,06,07,08,09,0a,0b,0c,0d,0e
color1	.byte  0, 0, 2 ,4 ,6 ,8,10,12,14,12,10, 8, 6, 4
color2	.byte  0, 0, 2 ,4 ,6 ,8,10,12,14,12,10, 8, 8, 8
color3	.byte  0, 0, 2 ,4 ,6 ,8,10,12,14,14,14,14,14,14
	.endl
	
	.endp				;End of animate_logo_content

	.endp				;End of animate
;===============================================================

	.proc generate_dl_line		;IN: ldl, <X>=ldl index
	poke_dl = screen.animate.poke_dl
	poke_dl.ptr = screen.animate.poke_dl.ptr

	lda ldl_parameter,x
	bne not_first

	lda #$01			;Jump to logo_dl and back
	jsr poke_dl
	lda #<logo_screen.logo_dl
	jsr poke_dl
	lda #>logo_screen.logo_dl
	jsr poke_dl

	mwa poke_dl.ptr logo_screen.logo_dl.jump

	m_set_dli_tab dli.logo_line_first
	rts

not_first
	cmp #logo_lines-1
	beq last
	m_set_dli_tab dli.logo_line_middle
	rts

last	
	m_set_dli_tab dli.logo_line_last
	rts


	.endp		;End of generate_line

;===============================================================

	.proc dli

	.proc logo_line_first

	lda #palette.separator
	sta wsync
	sta colbk			;Set all relevant registers to the same value
	sta colpf1
	sta colpf2
	mva #$22 dmactl

	sta wsync
	lda #palette.logo_background
	sta colbk			;Set all relevant registers to the same value
color1 = *+1
	lda #palette.logo_background
	sta colpf0
color2 = *+1
	lda #palette.logo_background
	sta colpf1
color3 = *+1
	lda #palette.logo_background
	sta colpf2

	clc
	lda pattern_dli_cnt
	adc #logo_lines
	sta pattern_dli_cnt
	jmp dli.next_dli

	.endp

;===============================================================

	.proc logo_line_middle
	jmp dli.next_dli
	.endp

;===============================================================

	.proc logo_line_last
	mva #$23 dmactl			;Wide screen
	mva #palette.logo_background colpf1
	mva #palette.pattern_background colpf2
	sta wsync
	mva #palette.separator colbk
	jmp dli.next_dli
	.endp				;End of logo_line_last

	.endp				;End of dli

;===============================================================

	.local logo_screen

	.local logo_dl
	dc = $0e

	.byte $00,$00,$40+dc
lms	.byte a(logo_sm)
	.byte dc,dc,dc,dc,dc+$80
:5	.byte dc,dc,dc,dc,dc,dc,dc,dc+$80
	.byte dc,dc,dc,dc,dc,dc,dc,dc
	.byte dc,dc,dc,dc,$80,$40+dc,a(fill_sm),$81
jump	.word $ffff
	.endl			;End of logo_dl

	.local fill_sm
:48	.byte $aa
	.endl			;End of fill_sm

	.endl			;End of logo_screen
	.endp			;End of logo

;===============================================================

	m_info logo