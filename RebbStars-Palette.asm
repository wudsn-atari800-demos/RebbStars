;
;	>>> RebbStars by JAC! <<<
;
;	@com.wudsn.ide.asm.mainsourcefile=RebbStars-Main.asm

	.enum palette
	pattern_background_chroma = $80 
	pattern_background        = pattern_background_chroma+$02
	pattern_foreground        = $0a

	logo_chroma_start = $00
	logo_chroma_end	  = $00
	logo_background   = $00
	logo_color1       = $0e
	logo_color2       = $04
	logo_color3	  = $08

	scroller_background = $42
	scroller_foreground = $0e
	
	separator = $0e
	.ende