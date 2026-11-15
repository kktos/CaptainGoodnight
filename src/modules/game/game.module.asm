		.MODULE	GAME

	; the boot image, main memory: what the loader left at $0300 (its $063D-$073C) and T05-T07
		.segment	PAGE3
		.incbin	"../../../bin/page3.0300-03FF.bin"

		.segment	GAME_LO
		.incbin	"../../../bin/game.0800-27FF.bin"

		.segment	GAME_HI
		.incbin	"../../../bin/game.6000-62FF.bin"
		.namespace	intro
		.include	"intro.asm"
		.end namespace

		.MODULE	LC

	; the boot image, language card: T01 (bank 1), T04 (bank 2), T02-T03 ($E000-$FFFF)
		.segment	LC1
		.incbin	"../../../bin/lc1.D000-DFFF.bin"

		.segment	LC2
		.incbin	"../../../bin/lc2.D000-D00B.bin"
	; $D00C-$D3A5: the RWTS, READ_TRACK and READ_TRACK_AT, which nothing calls any more: free
		.fill	$D3A6 - *, $00
		.include	"loadtrack.asm"
		.incbin	"../../../bin/lc2.D3C6-DFFF.bin"

		.segment	LCHI
		.incbin	"../../../bin/lchi.E000-FFFF.bin"
