;
;	>>> RebbStars by JAC! <<<
;
;	Main part, to be packed with Exomizer.

.def alignment_mode	;Should be set by default

cnt		= $14

p1		= $80	;Common usage
p2		= $82

x1		= $88	;Common usage
x2		= $89
x3		= $8a
x4		= $8b

ldl_line	= $90		;Logical line number during VBI
pattern_dli_cnt = $91		;Number of the current pattern DLI line
scroller_pattern_ptr = $92	;Scroller HSM pattern pointer during VBI

plasma_x	= $a0
plasma_y	= $a1
plasma_sx	= $a2
plasma_sy	= $a3
plasma_dx	= $a4
plasma_dy	= $a5
twirl_x		= $a6
twirl_sr	= $a7
twirl_or	= $a8

scroller_ptr	= $b0		;Scroller text pointer
scroller_xcnt	= $b2		;Scroller x fine scrolling counter (3..0)
scroller_ccnt	= $b3		;Scroller characeter counter (0..63)
scroller_ycnt	= $b4		;Scroller y counter ($00..$7f)


base		= $5000		;Start of heap base memory

ldl_lines	= $20		;Maximum number of lines in the logical display list
ldl		= base+$00	;Logical display list commands type
ldl_parameter	= base+$20	;Logical display list command parameters
dl		= base+$400	;Physical display list

dli_tab_lines	= $20		;Maximum number of lines in the DLI table
dli_tab_lo	= base+$40	;Lo bytes of DLI routines
dli_tab_hi	= base+$60	;Hi bytes of DLI routines
dli_tab_snd	= base+$80	;Flag byte of DLI lines with sound replay

logo_lines	= logo_sm_lines/8;Logo height in graphics 0 lines
logo_sm_lines	= 64		;Logo height in graphics 15 lines
logo_sm_width	= 40		;Logo width in graphics 15 bytes

logo_sm		= $8000		;Logo screen memory, 4*$960 byte at logo_sm, logo_sm+$1000,logo_sm+$2000,logo_sm+$3000
logo_sm1	= $8000		;"RebbStars"
logo_sm2	= $9000		;"JAC"
logo_sm3	= $a000		;"Rebb"
logo_sm4	= $b000		;"Premium"

scroller_sin	= $8a00		;Scroller sinus table ($80 bytes)
scroller_tsm	= $8b00		;Scroller text screen memory (2*2)*64 = $100 bytes
scroller_chr	= $8c00		;Scroller charset ($400 bytes, 64 chars x 2)
scroller_chr1	= $9c00		;Scroller charset, shifted by 1 pixel to the left
scroller_sm_width = 48		;Scroller wrap around buffer size
scroller_hsm1	= $aa00		;Scroller hires screen memory 48*8 = $180 bytes
scroller_hsm2	= $ae00		;Scroller hires screen memory 48*8 = $180 bytes

pattern_sm_width= 48		;Bytes per screen memory line
pattern_sm_lines= 28		;Screen memory lines
pattern_lines	= 14		;Double screen lines
pattern_llo	= $ba00		;pattern_sm_lines low bytes
pattern_lhi	= $ba20		;pattern_sm_lines high bytes
pattern_chrs	= $ba40		;pattern_sm_lines charset high bytes
pattern_colors	= $ba60		;pattern_sm_lines color bytes
pattern_sm	= $bac0		;pattern_sm_width*pattern_sm_lines = $540 screen bytes
pattern_chr	= $6000		;4*2 charset, 4*2*$400 bytes = $2000 bytes
pattern_cmap	= base+$700	;Lookup table to map 256 => 0...63...0
pattern_chr1	= base+$800	;Remapped active charset for even lines
pattern_chr2	= base+$c00	;Remapped active charset for odd lines


	opt h+l+r-		;Not using R+ is better when using Exomizer!

	icl "RebbStars-Global-Equates.asm"

;===============================================================

	org $2000

start	jmp main

	buffer_mode = 0
	icl "snd/RebbStars-Sound.asm"
	
	opt f+
	icl "RebbStars-Kernel.asm"

;===============================================================

	.proc main
	jsr system.init

	jsr effect.screen.init
	jsr effect.pattern.init
	jsr effect.logo.init
	jsr effect.scroller.init
	ldx #<effect.vbi		
	ldy #>effect.vbi
	jsr system.set_vbiv

	mva cnt sync_cnt
main_loop
sync_cnt = *+1
	lda #0
sync_loop
	cmp cnt
	beq main_loop
	sta sync_cnt
	jsr effect.pattern.animate_pattern_charset
	jsr effect.pattern.animate_pattern_lines.generate_pattern_lines
	jmp main_loop
	.endp

;===============================================================

	.proc system

	.proc init
	sei
	jsr sync.vcount
	mva #$00 nmien

	lda 710
	and #15
	sta fade_luma
fade_loop
	jsr sync.vcount
	jsr sync.vcount
	lda 709
	and #15
fade_luma = *+1
	cmp #$00
	sta colpf1
	beq fade_done
	dec 709
	jmp fade_loop
fade_done
	mva #0 dmactl			;Blank screen completely until first VBI was there

	ldx #<sound.module		;Low byte of RMT module to X reg
	ldy #>sound.module		;High byte of RMT module to Y reg
	lda #0				;Starting song line 0-255 to A reg
	jsr sound.init

	mva #$fe portb
	mwa #nmi.handler $fffa
	mva #$40 nmien
	rts
	.endp				;End of init

;===============================================================
;	Externally used vectors

	vbiv = nmi.vbi.jump_vbi+1
	dliv = nmi.handler.jump_dli+1

	.proc set_vbiv
	jsr sync.cnt
	stx vbiv
	sty vbiv+1
	jmp sync.cnt
	.endp

	.proc nmi

	.proc handler
	bit nmist
	bpl vbi
	pha
	txa
	pha
jump_dli
	jmp effect.dli.none_line
	.endp

	.proc vbi
	sta nmires
	pha
	txa
	pha
	tya
	pha

jump_vbi
	jsr empty_procedure

	inc cnt
	pla
	tay
	pla
	tax
	pla
	rti
	.endp	;End of vbi

	.endp	;End of nmi

	.endp	;End of system

;===============================================================

	.proc effect

	.proc vbi
	jsr sound.play

	mva #$23 dmactl
	mwa #dl dlptr
	mva #$c0 nmien
	lda #palette.pattern_background
	sta colpf2
	sta colbk
	lda #palette.pattern_foreground
	sta colpf1

	mvx #0 effect.dli.dli_cnt		;For DLI vector
	mva dli_tab_lo,x system.dliv
	mva dli_tab_hi,x system.dliv+1
	mva #0 pattern_dli_cnt			;For pattern colors

	jsr screen.animate		;Create physical dl based on logical DL
	jsr pattern.animate		;Start new/next logical DL
	jsr logo.animate

	lda trig0
	and trig1
	and #1
	beq button_pressed
	lda skstat
	and #12
	cmp #12
	bne button_pressed

	jsr effect.scroller.generate_hsm
	jsr scroller.animate
	rts

button_pressed
	jmp ending

	.endp		;End of vbi

;===============================================================

	.proc dli
next_dli
	inc dli_cnt

dli_cnt = *+1
	ldx #0
	mva dli_tab_lo,x system.dliv
	mva dli_tab_hi,x system.dliv+1
	lda dli_tab_snd,x
	bne play_sound

none_line
	pla
	tax
	pla
	rti

play_sound
	sta nmires			;Paranoia
	tya
	pha
	txa
	jsr sound.play
	pla
	tay
	jmp none_line

	.endp				;End of DLI

;===============================================================

	icl "RebbStars-Screen.asm"
	icl "RebbStars-Pattern.asm"
	icl "RebbStars-Logo.asm"
	icl "RebbStars-Scroller.asm"
	icl "RebbStars-Ending.asm"

;===============================================================

	.endp		;End of effect

;===============================================================

	m_info effect

	.if * > base
	.error "Code exceed base start address."
	.endif

	org pattern_chr
	ins "RebbStars-Pattern.chr"
;	ins "RebbStars-Pattern-Test.chr"

	org logo_sm1
	ins 'gfx/RebbStars-Logo.pic'		;$960 bytes
:$a0	.byte $12

	org scroller_sin
	ins 'gfx/RebbStars-Scroller.sin'

	org scroller_chr
	ins 'gfx/RebbStars-Scroller-Font.bin'

	org logo_sm2
	ins 'gfx/RebbStars-Logo-JAC.pic'	;$960 bytes
:$a0	.byte $00
	org logo_sm3
	ins 'gfx/RebbStars-Logo-Rebb.pic'	;$960 bytes
:$a0	.byte $00


	org logo_sm4
	ins 'gfx/RebbStars-Logo-Premium.pic'	;$960 bytes
:$a0	.byte $00


;===============================================================

	run start
