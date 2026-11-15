;
; boot blocks 0-1: the bootloader, then tiny-dos, which it copies to the aux language card, bank 2
;
		.segment	BOOTLOADER	{ start: $0800, size: $0100 }
		.segment	TINY_DOS	{ start: $D000, size: $0300 }

;
; CAPTAIN: what the SAN loader ($0406) did, with tiny-dos: Init, then AUX_LOADER, which Init copies
; to the aux language card, bank 2, at AUX_SWITCH (LOAD_TRACK's other half). Init is 2 blocks, so AUX_LOADER
; loads at $7400.
;
		.segment	INIT		{ start: $7000, size: $0400 }
		.segment	AUX_LOADER	{ start: AUX_SWITCH, size: 0 }

;
; GAME: the boot image, main memory (T05-T07, and the loader's $063D-$073C to $0300)
;
		.segment	PAGE3		{ start: $0300, end: $03FF }
		.segment	GAME_LO		{ start: $0800, end: $27FF }
		.segment	GAME_HI		{ start: $6000, end: $6FFF }

;
; LC: the boot image, language card (T01-T04). Init loads it at $8000-$BFFF and copies it there.
; LC2 has the disk layer replaced: LOAD_TRACK calls the aux language card's AUX_LOADER.
;
		.segment	LC1		{ start: $D000, end: $DFFF }
		.segment	LC2		{ start: $D000, end: $DFFF }
		.segment	LCHI		{ start: $E000, end: $FFFF }

;
; the tracks read at run time, a segment each (at where they load), a file per load:
; LOAD_TRACK finds a track's file and its place in it from AUX_LOADER's TrackMap
;

; INTRO: side A T11-T1D, by the intro's script ($631A)
		.segment	A_T11		{ start: $7000, end: $7FFF }
		.segment	A_T12		{ start: $8000, end: $8FFF }
		.segment	A_T13		{ start: $9000, end: $9FFF }
		.segment	A_T14		{ start: $A000, end: $AFFF }
		.segment	A_T15		{ start: $B000, end: $BFFF }
		.segment	A_T16		{ start: $7000, end: $7FFF }
		.segment	A_T17		{ start: $8000, end: $8FFF }
		.segment	A_T18		{ start: $9000, end: $9FFF }
		.segment	A_T19		{ start: $A000, end: $AFFF }
		.segment	A_T1A		{ start: $B000, end: $BFFF }
		.segment	A_T1B		{ start: $7000, end: $7FFF }
		.segment	A_T1C		{ start: $9000, end: $9FFF }
		.segment	A_T1D		{ start: $8000, end: $8FFF }

; PART1-PART6: sections 1-6, side B
		.segment	B_T01		{ start: $6300, end: $72FF }
		.segment	B_T02		{ start: $7300, end: $82FF }
		.segment	B_T03		{ start: $8300, end: $92FF }
		.segment	B_T04		{ start: $9300, end: $A2FF }
		.segment	B_T05		{ start: $A300, end: $B2FF }

		.segment	B_T06		{ start: $6300, end: $72FF }
		.segment	B_T07		{ start: $7300, end: $82FF }
		.segment	B_T08		{ start: $8300, end: $92FF }
		.segment	B_T09		{ start: $9300, end: $A2FF }
		.segment	B_T0A		{ start: $A300, end: $B2FF }
		.segment	B_T0B		{ start: $B000, end: $BFFF }

		.segment	B_T0C		{ start: $6300, end: $72FF }
		.segment	B_T0D		{ start: $7300, end: $82FF }
		.segment	B_T0E		{ start: $8300, end: $92FF }
		.segment	B_T0F		{ start: $9300, end: $A2FF }
		.segment	B_T10		{ start: $A300, end: $B2FF }

		.segment	B_T11		{ start: $6300, end: $72FF }
		.segment	B_T12		{ start: $7300, end: $82FF }
		.segment	B_T13		{ start: $8300, end: $92FF }
		.segment	B_T14		{ start: $9300, end: $A2FF }
		.segment	B_T15		{ start: $A300, end: $B2FF }
		.segment	B_T16		{ start: $B000, end: $BFFF }

		.segment	B_T17		{ start: $6300, end: $72FF }
		.segment	B_T18		{ start: $7300, end: $82FF }
		.segment	B_T19		{ start: $8300, end: $92FF }
		.segment	B_T1A		{ start: $9300, end: $A2FF }
		.segment	B_T1B		{ start: $A300, end: $B2FF }
		.segment	B_T1C		{ start: $B000, end: $BFFF }

		.segment	B_T1D		{ start: $6300, end: $72FF }
		.segment	B_T1E		{ start: $7300, end: $82FF }
		.segment	B_T1F		{ start: $8300, end: $92FF }
		.segment	B_T20		{ start: $9300, end: $A2FF }
		.segment	B_T21		{ start: $A300, end: $B2FF }
		.segment	B_T22		{ start: $B000, end: $BFFF }	; also the endings' LOAD_TRACK ($D006)

; END9: section 9, side A
		.segment	A_T1E		{ start: $6300, end: $72FF }
		.segment	A_T1F		{ start: $7300, end: $82FF }
		.segment	A_T10		{ start: $8300, end: $92FF }

; END11: section 11, side A
		.segment	A_T21		{ start: $6300, end: $72FF }
		.segment	A_T22		{ start: $7300, end: $82FF }

; T20: section 11's LOAD_TRACK, side A
		.segment	A_T20		{ start: $B000, end: $BFFF }
