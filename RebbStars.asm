;
;	>>> RebbStars by JAC! <<<
;
;	A 12k full overscan intro for stock Atari 800 XL/XE, 64k, PAL.
;	Uses 150 Hz music replay that eats up 30% of the CPU to not sound like POKEY.
;	Plus a software driven soft scroll to achieve free vertical positioning
;	of the hires scroller over animated overscan hires background at 50 FPS.
;	And yes, it thought it would be simple...believe me it's not with 1.79MHz :-)
;
;	This is a tribute to the good cracktro style Amiga intros I am still in love with.
;	Thanks to Shadow^GP for creating the original "Old Cranky Style" Amiga intro
;	and allowing me to use some graphics for my demake. If only I had asked for the
;	sinus table, too. It would have saved from writing a ripper that can rip sinus waves
;	from AVI recordings :-)
;	
;	External URL: https://www.wudsn.com/productions/atari800/rebbstars/rebbstars-source.zip
;	Internal URL: https://www.dropbox.com/home/jac/system/Atari800/Programming/Demos/RebbStars

	opt h+


temp_colors 	= $1e00
line1		= $1e10
line2		= $1e38

	org $1e60			;Loading screen
	jmp loader
	.byte 0,155
	.byte 'RebbStars Demo 2014-04-21 by JAC!/Peter Dell, Premium/Michael Becker, Rebb/Teemu Pohjanlehto.'
	.byte 0,155,0

;===============================================================

	.proc loader

cnt	= $14

p1	= $80

x1	= $e0
x2	= $e1
x3	= $e2

	icl "RebbStars-Global-Equates.asm"

;===============================================================

	.proc effect
	php
	txa
	pha

	lda #$ff
offset = *+1
	ldx #1
	sta loader_sm+40*0,x
	sta loader_sm+40*1,x
	sta loader_sm+40*2,x
	sta loader_sm+40*3,x
	sta loader_sm+40*4,x
	sta loader_sm+40*5,x
	cpx #38
	scs
	inc offset

	pla
	tax
	plp
	rts
	.endp

;===============================================================

	.local dl
:14	.byte $70
	.byte $4f,a(line1)
	.byte $4f,a(line2)
	.byte $4f,a(loader_sm)
:5	.byte $0f
	.byte $4f,a(line2)
	.byte $4f,a(line1)
	.byte $41,a(dl)
	.endl

	.local loader_sm
	ins "gfx/RebbStars-Loading.pic"
	.endl

	.if * > $2000
	.error "Loader overlaps demo area at ",*
	.endif

;===============================================================

	.proc main			;Will be overwritten
	jsr save_colors
	jsr init_borders
	jsr fade_up
	jsr copy_screen
	jmp fade_down

;===============================================================

	.proc save_colors
	ldx #8
loop	lda pcolor0,x
	sta temp_colors,x
	dex
	bpl loop
	rts
	
	.endp

;===============================================================
	.proc copy_screen

	sei				;Disable OS
	mva #0 nmien
	mva #$fe portb

	.proc copy_colors
	ldx #39
loop	lda temp_colors,x
	sta backup_colors,x
	lda #$ff
	sta line1,x
	lda #$00
	sta line2,x
	dex
	bpl loop
	
	lda #$80
	sta line2
	lda #$01
	sta line2+39
	.endp

	.proc copy_sm
	mwa 88 p1
	mwa p1 backup_sm
	ldx #4
	ldy #0
loop	lda (p1),y
backup_ptr = *+1
	sta backup_sm+2,y
	iny
	bne loop
	inc p1+1
	inc backup_ptr+1
	dex
	bne loop	
	.endp

	.proc copy_dl
	mwa 560 p1
	mwa p1 backup_dl
	ldx #4
	ldy #0
loop	lda (p1),y
backup_ptr = *+1
	sta backup_dl+2,y
	iny
	bne loop
	inc p1+1
	inc backup_ptr+1
	dex
	bne loop	
	.endp

	mva #$ff portb			;Enable OS
	mva #$40 nmien
	cli

	rts
	.endp

;===============================================================

	.proc fade_up
	mva #16 x1
loop_fade
	ldx #8
loop_regs
	lda pcolor0,x
	and #15
	cmp #15
	beq store
	inc pcolor0,x
	lda pcolor0,x
store	sta pcolor0,x
	dex
	bpl loop_regs
	lda #2
	jsr wait
	dec x1
	bne loop_fade
	rts
	.endp

;===============================================================

	.proc init_borders
	ldx #7				;Position player over overscan border
	lda #0
clear_loop
	sta hposp0,x
	dex
	bpl clear_loop

	lda #$ff
	sta grafp0
	sta grafp1
	sta sizep0
	sta sizep1
	lda #12
	sta hposp0
	lda #216
	sta hposp1
	rts
	.endp

	.proc fade_down
	mwa #dl 560
	lda #1
	jsr wait
	mva #15 x1
	sta 709
loop_fade
	lda x1
	sta pcolor0
	sta pcolor1
	cmp #2
	scs
	lda #$02
	ora #palette.pattern_background_chroma
	sta color2
	sta color4
	lda #2
	jsr wait
	dec x1
	bpl loop_fade
	rts
	.endp

	.proc wait			;IN: <A>=number of frames
	clc
	adc cnt
loop	cmp cnt
	bne loop
	rts
	.end
	
	.endp				;End of main
	.endp				;End of loader

	ini loader.main

	opt h-
	ins "RebbStars-Main-Packed.xex"
