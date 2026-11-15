;
; Captain Goodnight (SAN Inc crack): what the rehost uses of it. See meta/lc2.meta, meta/page3.meta.
;
		.namespace	game

ENTRY		=	$6300		; the intro, at boot; a section's code after LOAD_SECTION
SIDE_MARK	=	$6304		; of the $6300 page loaded: LOAD_SECTION checks it ($FF: a read error)
SLOT16		=	$BFFF		; the boot slot * 16, which the loader leaves there

; the $0300 page (traps)
REBOOT		=	$0340		; JMP $Cn00, the boot slot (REBOOT_SLOT)
REBOOT_SLOT	=	$0342		; REBOOT's JMP $Cn00: the loader patches the boot slot in
SET_VECTORS	=	$0366		; CSW, KSW, BRK, IRQ, RESET -> the traps; power-up byte

; LC bank 2: the disk layer
LOAD_TRACK	=	$D3A6		; A = track - 1, Y = first page (replaced)
SECTION		=	$D501		; the last section LOAD_SECTION was asked for
SECTION_SIDE	=	$D552		; 0: side A, 1: side B, by section

TRACKS		=	35

		.namespace
