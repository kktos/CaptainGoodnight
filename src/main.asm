		.cpu	"65C02"

; LOAD_TRACK's STA SETALTZP (main LC bank 2) and AUX_LOADER's STA SETSTDZP (aux LC bank 2) are at this same address:
; each switch's next instruction is fetched from the other language card, at AUX_SWITCH + 3
AUX_SWITCH	=	$D3B0

		.include	"segments.asm"

		.include	"includes/a2-firmware.asm"
		.include	"includes/smartport.asm"
		.include	"includes/extended-cmds.asm"
		.include	"includes/game.asm"

; file layout, in 512-byte blocks: each segment of a file starts on a block
PAGE3_BLOCKS	=	($0400 - $0300 + 511) / 512
GAME_LO_BLOCKS	=	($2800 - $0800) / 512
GAME_HI_BLOCKS	=	($7000 - $6000) / 512
LC_BLOCKS	=	($10000 - $D000 + $1000) / 512	; LC1, LC2, LCHI: $D000-$DFFF twice, $E000-$FFFF
TRACK_BLOCKS	=	$1000 / 512

		.include	"modules/boot/boot.module.asm"
		.include	"modules/captain/captain.module.asm"
		.include	"modules/game/game.module.asm"
		.include	"modules/tracks/tracks.module.asm"
