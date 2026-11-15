;
; Run by the bootloader: main zero page, stack and language card, LC bank 2 read/write; tiny-dos in the aux
; language card. Does what the SAN crack's boot did (boot0, then its loader at $0406, see meta/loader.meta),
; the game loaded from the files GAME and LC instead of T01-T07, and LOAD_TRACK's aux half put in place.
;
ptr		=	$F0		; MemCopy: source, destination, size
dst		=	$F2
size		=	$F4

Init:
		sei
		ldx	#$FF
		txs

	; boot0: clear $2000-$5FFF, HGR page 1, full screen
		ldy	#$20
		ldx	#$60
		lda	#$00
		jsr	FillPages
		sta	sys::MIXEDOFF
		sta	sys::HIRESON
		sta	sys::PAGE2OFF
		sta	sys::TEXTOFF

	; the loader: AN3 on, 40 columns, 80STORE off; $4000-$5FFF AA / D5 stripes, HGR page 2 shown
		sta	sys::DHIRESOFF
		sta	sys::CLR80VID
		sta	sys::CLR80STORE
		lda	#$40
		sta	ptr+1
		stz	ptr
		ldx	#$20
		ldy	#$00
		lda	#$AA
:		sta	(ptr),y
		eor	#$7F
		iny
		bne	:-
		inc	ptr+1
		dex
		bne	:-
		sta	sys::PAGE2ON

	; the game: $0300 (the traps), $0800-$27FF, $6000-$6FFF
		ldx	#<gamePage3
		ldy	#>gamePage3
		jsr	LoadAt
		ldx	#<gameLo
		ldy	#>gameLo
		jsr	LoadAt
		ldx	#<gameHi
		ldy	#>gameHi
		jsr	LoadAt

	; the language card: LC1, LC2, LCHI at $8000-$BFFF (tiny-dos would write them to the aux one), then
	; bank 1 $D000-$DFFF, bank 2 $D000-$DFFF and $E000-$FFFF
		ldx	#<lcImages
		ldy	#>lcImages
		jsr	LoadAt
		lda	sys::LCBANK1
		lda	sys::LCBANK1
		lda	#$80
		ldx	#$D0
		ldy	#$10
		jsr	CopyPages
		lda	sys::LCBANK2
		lda	sys::LCBANK2
		lda	#$90
		ldx	#$D0
		ldy	#$30			; $9000-$BFFF -> $D000-$FFFF
		jsr	CopyPages

	; AUX_LOADER (after Init, in CAPTAIN) -> the aux language card, bank 2; the aux interrupt vectors
	; -> an RTI (interrupts are off, but an NMI)
		sta	sys::SETALTZP
		lda	#<(.segment.start + .segment.size)
		sta	ptr
		lda	#>(.segment.start + .segment.size)
		sta	ptr+1
		lda	#<AUX_SWITCH
		sta	dst
		lda	#>AUX_SWITCH
		sta	dst+1
	; its size: what it holds (a resizable segment's .size is the one declared, 0)
		lda	#<(AuxLoaderEnd - AUX_SWITCH)
		sta	size
		lda	#>(AuxLoaderEnd - AUX_SWITCH)
		sta	size+1
		jsr	MemCopy
		ldx	#5
:		lda	auxVectors,x
		sta	$FFFA,x
		dex
		bpl	:-
		sta	sys::SETSTDZP

	; the loader's end: the slot for the game and for REBOOT, the vectors to the traps
		lda	smartport::unit		; DSSS0000: the bootloader's, main zero page
		and	#$70
		sta	game::SLOT16
		lsr	a
		lsr	a
		lsr	a
		lsr	a
		ora	#$C0
		sta	game::REBOOT_SLOT
		jsr	game::SET_VECTORS

		jmp	game::ENTRY		; LC bank 2 read/write, as the loader left it

;
; X/Y: a LoadFromFileAt record, tiny-dos called in the aux language card (ALTZP on): its JSR / RTS use
; the aux stack, from the same SP, so the main stack keeps this call's return address
;
LoadAt:
		sta	sys::SETALTZP
		jsr	tinyDOS::LoadFromFileAt
		sta	sys::SETSTDZP
		rts

; A: value, Y: first page, X: page after the last
FillPages:
		sty	ptr+1
		stz	ptr
		ldy	#$00
:		sta	(ptr),y
		iny
		bne	:-
		inc	ptr+1
		cpx	ptr+1
		bne	:-
		rts

; A: source page, X: destination page, Y: pages
CopyPages:
		sta	ptr+1
		stx	dst+1
		stz	ptr
		stz	dst
		sty	size+1
		stz	size
		; fall through

; ptr -> dst, size bytes
MemCopy:
		ldy	#$00
		lda	size
		ora	size+1
		beq	:+++++
:		lda	(ptr),y
		sta	(dst),y
		inc	ptr
		bne	:+
		inc	ptr+1
:		inc	dst
		bne	:+
		inc	dst+1
:		lda	size
		bne	:+
		dec	size+1
:		dec	size
		lda	size
		ora	size+1
		bne	:----
:		rts

auxVectors:	.dw	AuxRti, AuxRti, AuxRti	; NMI, RESET (the //e's reset turns ALTZP off), IRQ

gamePage3:	.db	0, PAGE3_BLOCKS
		.dw	$0300
		.pstr	"GAME"
gameLo:		.db	PAGE3_BLOCKS, GAME_LO_BLOCKS
		.dw	$0800
		.pstr	"GAME"
gameHi:		.db	PAGE3_BLOCKS + GAME_LO_BLOCKS, GAME_HI_BLOCKS
		.dw	$6000
		.pstr	"GAME"
lcImages:	.db	0, LC_BLOCKS
		.dw	$8000
		.pstr	"LC"

		.if * > $7400 {
			.error "Init ends at " + .hex(*) + ": past $73FF, the 2 blocks AUX_LOADER loads after."
		}
