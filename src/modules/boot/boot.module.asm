		.MODULE	BOOT

	;
	; blocks 0-1: the ROM loads block 0 at $0800, the bootloader reads block 1 at $0A00,
	; moves tiny-dos to the aux language card, bank 2 ($D000), loads the file CAPTAIN and runs it
	;

		.segment	BOOTLOADER
		.include	"bootloader.asm"

		.segment	TINY_DOS
		.include	"tiny-dos.asm"
