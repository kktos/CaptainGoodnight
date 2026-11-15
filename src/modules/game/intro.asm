; The intro, side A T07 $6300-$6FFF (the boot image). Copied from out/asm/intro/intro.asm (dis.py,
; meta/intro.meta, round-trip checked), then maintained here: the meta's listing (out/intro.lst) is the original's.

PAL_BIT		=	$01
SRC		=	$09
SCRN		=	$0B
SCRN_PAGE	=	$0F
MIRROR_TMP	=	$1B
MSG_Y		=	$1F
MSG_X		=	$20
COUNTER		=	$80
NOTE_PERIOD	=	$D0
NOTE_COUNT	=	$D1
NOTE_LEN_HI	=	$D2
NOTE_LEN_LO	=	$D3
NOTE_INDEX	=	$D5
NOTE_D6		=	$D6
NOTE_D7		=	$D7
NOTE_D8		=	$D8
WIPE_SRC	=	$E1
WIPE_DST	=	$E3
WIPE_LEFT	=	$E5
WIPE_RIGHT	=	$E6
FLASH_COUNT	=	$E9
TUNE_PLAYED	=	$EA
PACK_SRC	=	$F0
PACK_COL	=	$F2
PACK_PASS	=	$F4
PACK_DST	=	$F5
RUN_VALUE	=	$F7
RUN_COUNT	=	$F8
PAGE		=	$F9
MIRROR		=	$0200
JMPDISK		=	$1D17
WAIT		=	$6225
SETSCRN		=	$6231
LOAD_SECTION_V	=	$D000

		.org	$6300
; the intro's entry (the loader's JMP $6300)
INTRO:
		nop
		nop
		nop
SECTION_MARKS:
		ldx	#$00			; DISK_MARK ($6303) = $A2 = SECTION_MARK[0], SIDE_MARK ($6304) = 0 (side A): also this LDX #$00
; clears the keyboard; the script from its start, the tune not played yet
FLUSH_START:
		lda	sys::KBDSTRB		; <- $6309
		inx
		bne	FLUSH_START
		lda	#$00
		sta	SCRIPT_PC
		sta	TUNE_PLAYED
		sta	$46
		jsr	CHECK_JOYSTICK		; both buttons down: no joystick, or a bad one
		jmp	RUN_SCRIPT

; the script: 0 X Y LOAD_TRACK X (track - 1) to page Y | 1 a CLEAR_HOLES ($00 page 1, $20 page 2) |
; 2 WIPE page 2 -> page 1 | 3 n PAUSE n+1 | 4 TUNE | 5 / 6 show page 1 / 2 | 7 a p UNPACK page a to page p |
; 8 CHECK_SIDE | $FF (anything else) FLASH_BAND, then from the start again
SCRIPT:
		.db	$00,$10,$70		; T11 -> $7000
		.db	$00,$11,$80		; T12 -> $8000
		.db	$00,$12,$90		; T13 -> $9000
		.db	$00,$13,$A0		; T14 -> $A000
		.db	$00,$14,$B0		; T15 -> $B000
		.db	$08			; side A in the drive?
		.db	$07,$70,$20		; $7000 -> page 1
		.db	$01,$00
		.db	$05			; show page 1
		.db	$03,$18
		.db	$07,$80,$40		; $8000 -> page 2
		.db	$01,$20
		.db	$02			; wipe it in
		.db	$04			; the tune (the first time round)
		.db	$07,$90,$40		; $9000 -> page 2
		.db	$01,$20
		.db	$02
		.db	$03,$18
		.db	$07,$A0,$40		; $A000 -> page 2
		.db	$01,$20
		.db	$02
		.db	$03,$18
		.db	$07,$B0,$40		; $B000 -> page 2
		.db	$01,$20
		.db	$02
		.db	$03,$14
		.db	$00,$15,$70		; T16 -> $7000
		.db	$00,$16,$80		; T17 -> $8000
		.db	$00,$17,$90		; T18 -> $9000
		.db	$00,$18,$A0		; T19 -> $A000
		.db	$00,$19,$B0		; T1A -> $B000
		.db	$08
		.db	$07,$70,$40		; $7000 -> page 2, shown
		.db	$06
		.db	$03,$1F
		.db	$07,$80,$20		; $8000 -> page 1, shown
		.db	$05
		.db	$03,$1F
		.db	$07,$90,$40
		.db	$06
		.db	$03,$1F
		.db	$07,$A0,$20
		.db	$05
		.db	$03,$1F
		.db	$07,$B0,$40
		.db	$06
		.db	$03,$17
		.db	$00,$1A,$70		; T1B -> $7000
		.db	$00,$1B,$90		; T1C -> $9000
		.db	$00,$1C,$80		; T1D -> $8000
		.db	$08
		.db	$07,$70,$20
		.db	$05
		.db	$03,$1F
		.db	$07,$90,$40
		.db	$06
		.db	$03,$1F
		.db	$07,$80,$20		; $8000 -> page 1 and page 2
		.db	$01,$00
		.db	$05
		.db	$07,$80,$40
		.db	$01,$20
		.db	$06
		.db	$FF			; the end: FLASH_BAND, again
SCRIPT_PC:
		.db	$00
RUN_SCRIPT:
		ldx	SCRIPT_PC		; <- $6317 $6459 $6803
		lda	SCRIPT,x
		beq	OP_LOAD_TRACK
		cmp	#$01
		beq	OP_CLEAR_HOLES
		cmp	#$02
		beq	OP_WIPE
		cmp	#$03
		beq	OP_PAUSE
		cmp	#$04
		beq	OP_TUNE
		cmp	#$05
		beq	OP_PAGE1
		cmp	#$06
		beq	OP_PAGE2
		cmp	#$07
		beq	OP_UNPACK
		cmp	#$08
		beq	OP_CHECK_SIDE
		jmp	OP_END

OP_CHECK_SIDE:
		lda	$7FFF			; $7FFF is T11's last byte: $AA on side A, not on side B | <- $63C9
		cmp	#$AA
		beq	NEXT_OP
		sec				; C = 1: the disk was turned over already, TURN_DISK won't ask
		jmp	TURN_DISK

OP_END:
		lda	#$00			; <- $63CB
		sta	SCRIPT_PC
		jmp	FLASH_BAND

OP_LOAD_TRACK:
		inx				; <- $63A9
		lda	SCRIPT,x
		pha
		inx
		stx	SCRIPT_PC
		lda	SCRIPT,x
		tay
		pla
		tax
		lda	#$FF			; LOAD_SECTION A = $FF: LOAD_TRACK X to pages Y.., no check
		jsr	LOAD_SECTION_V
		inc	COUNTER
		jmp	NEXT_OP

OP_CLEAR_HOLES:
		inx				; <- $63AD
		lda	SCRIPT,x
		sta	PAGE
		stx	SCRIPT_PC
		jsr	CLEAR_HOLES
		jmp	NEXT_OP

OP_WIPE:
		jsr	WIPE			; <- $63B1
		jmp	NEXT_OP

OP_PAUSE:
		inx				; <- $63B5
		lda	SCRIPT,x
		stx	SCRIPT_PC
		tax
		jsr	PAUSE
		jmp	NEXT_OP

OP_TUNE:
		jsr	TUNE			; <- $63B9
		jmp	NEXT_OP

OP_PAGE1:
		bit	sys::PAGE2OFF		; <- $63BD
		jmp	NEXT_OP

OP_PAGE2:
		bit	sys::PAGE2ON		; <- $63C1
		jmp	NEXT_OP

OP_UNPACK:
		inx				; <- $63C5
		lda	SCRIPT,x
		sta	PACK_SRC+1
		lda	#$00
		sta	PACK_SRC
		inx
		stx	SCRIPT_PC
		lda	SCRIPT,x
		sta	PAGE
		jsr	UNPACK
; the next step; a key or a button ends the intro
NEXT_OP:
		inc	SCRIPT_PC		; <- 8 refs
		inc	COUNTER
		lda	sys::KBD
		bmi	NEXT_OP_KEY
		lda	sys::BUTN0
		bmi	NEXT_OP_BUTN0
		lda	sys::BUTN1
		bmi	NEXT_OP_BUTN1
		jmp	RUN_SCRIPT

NEXT_OP_BUTN0:
		lda	sys::BUTN0		; <- $6452 $645F
		bmi	NEXT_OP_BUTN0
		bpl	NEXT_OP_KEY
NEXT_OP_BUTN1:
		lda	sys::BUTN1		; <- $6457 $6466
		bmi	NEXT_OP_BUTN1
NEXT_OP_KEY:
		sta	sys::KBDSTRB		; <- $644D $6461
		clc
		jmp	TURN_DISK

; the game's yhigh / ylow, again (the same bytes): Y 0 = row 191, page 1
ROW_HI:
		.db	$3F,$3B,$37,$33,$2F,$2B,$27,$23
		.db	$3F,$3B,$37,$33,$2F,$2B,$27,$23
		.db	$3E,$3A,$36,$32,$2E,$2A,$26,$22
		.db	$3E,$3A,$36,$32,$2E,$2A,$26,$22
		.db	$3D,$39,$35,$31,$2D,$29,$25,$21
		.db	$3D,$39,$35,$31,$2D,$29,$25,$21
		.db	$3C,$38,$34,$30,$2C,$28,$24,$20
		.db	$3C,$38,$34,$30,$2C,$28,$24,$20
		.db	$3F,$3B,$37,$33,$2F,$2B,$27,$23
		.db	$3F,$3B,$37,$33,$2F,$2B,$27,$23
		.db	$3E,$3A,$36,$32,$2E,$2A,$26,$22
		.db	$3E,$3A,$36,$32,$2E,$2A,$26,$22
		.db	$3D,$39,$35,$31,$2D,$29,$25,$21
		.db	$3D,$39,$35,$31,$2D,$29,$25,$21
		.db	$3C,$38,$34,$30,$2C,$28,$24,$20
		.db	$3C,$38,$34,$30,$2C,$28,$24,$20
		.db	$3F,$3B,$37,$33,$2F,$2B,$27,$23
		.db	$3F,$3B,$37,$33,$2F,$2B,$27,$23
		.db	$3E,$3A,$36,$32,$2E,$2A,$26,$22
		.db	$3E,$3A,$36,$32,$2E,$2A,$26,$22
		.db	$3D,$39,$35,$31,$2D,$29,$25,$21
		.db	$3D,$39,$35,$31,$2D,$29,$25,$21
		.db	$3C,$38,$34,$30,$2C,$28,$24,$20
		.db	$3C,$38,$34,$30,$2C,$28,$24,$20
ROW_LO:
		.db	$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0
		.db	$50,$50,$50,$50,$50,$50,$50,$50
		.db	$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0
		.db	$50,$50,$50,$50,$50,$50,$50,$50
		.db	$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0
		.db	$50,$50,$50,$50,$50,$50,$50,$50
		.db	$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0
		.db	$50,$50,$50,$50,$50,$50,$50,$50
		.db	$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
		.db	$28,$28,$28,$28,$28,$28,$28,$28
		.db	$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
		.db	$28,$28,$28,$28,$28,$28,$28,$28
		.db	$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
		.db	$28,$28,$28,$28,$28,$28,$28,$28
		.db	$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
		.db	$28,$28,$28,$28,$28,$28,$28,$28
		.db	$80,$80,$80,$80,$80,$80,$80,$80
		.db	$00,$00,$00,$00,$00,$00,$00,$00
		.db	$80,$80,$80,$80,$80,$80,$80,$80
		.db	$00,$00,$00,$00,$00,$00,$00,$00
		.db	$80,$80,$80,$80,$80,$80,$80,$80
		.db	$00,$00,$00,$00,$00,$00,$00,$00
		.db	$80,$80,$80,$80,$80,$80,$80,$80
		.db	$00,$00,$00,$00,$00,$00,$00,$00
; page 2 -> page 1, from the centre out: columns $13 / $14, $12 / $15 ... 0 / $27, all rows but Y 0
WIPE:
		lda	#$13			; <- $6409
		sta	WIPE_LEFT
		lda	#$14
		sta	WIPE_RIGHT
WIPE_STEP:
		ldx	#$BF			; <- $6624
WIPE_ROW:
		lda	ROW_LO,x		; <- $6617
		sta	WIPE_SRC
		sta	WIPE_DST
		lda	ROW_HI,x
		sta	WIPE_DST+1
		clc
		adc	#$20
		sta	WIPE_SRC+1
		ldy	WIPE_LEFT
		lda	(WIPE_SRC),y
		sta	(WIPE_DST),y
		ldy	WIPE_RIGHT
		lda	(WIPE_SRC),y
		sta	(WIPE_DST),y
		dex
		bne	WIPE_ROW
		inc	WIPE_RIGHT
		dec	WIPE_LEFT
		bmi	WIPE_DONE
		lda	#$90
		jsr	WAIT
		jmp	WIPE_STEP

WIPE_DONE:
		rts				; <- $661D

; zeroes the 8-byte screen holes ($xx78-$xx7F, $xxF8-$xxFF) of a hires page, PAGE = $00 / $20
CLEAR_HOLES:
		lda	#$00			; <- $6403
		sta	SCRN
		lda	#$20
		clc
		adc	PAGE
		sta	SCRN+1
		ldx	#$00
CLEAR_HOLES_PAGE:
		ldy	#$78			; <- $664C
		lda	#$00
CLEAR_HOLE1:
		sta	(SCRN),y		; <- $663E
		iny
		cpy	#$80
		bne	CLEAR_HOLE1
		ldy	#$F8
CLEAR_HOLE2:
		sta	(SCRN),y		; <- $6645
		iny
		bne	CLEAR_HOLE2
		inc	SCRN+1
		inx
		cpx	#$20
		bne	CLEAR_HOLES_PAGE
		rts

; X+1 x WAIT 0; a key or a button ends the intro
PAUSE:
		lda	#$00			; <- $6417 $6666 $6682 $67CC
		jsr	WAIT
		inc	COUNTER
		lda	sys::KBD
		bmi	PAUSE_KEY
		lda	sys::BUTN0
		bmi	PAUSE_BUTN0
		lda	sys::BUTN1
		bmi	PAUSE_BUTN1
		dex
		bpl	PAUSE
		rts

PAUSE_BUTN0:
		lda	sys::BUTN0		; <- $665E $666C
		bmi	PAUSE_BUTN0
		bpl	PAUSE_KEY
PAUSE_BUTN1:
		lda	sys::BUTN1		; <- $6663 $6673
		bmi	PAUSE_BUTN1
PAUSE_KEY:
		sta	sys::KBDSTRB		; <- $6659 $666E
		clc
		jmp	TURN_DISK

; the tune, once; then only a pause
TUNE:
		lda	TUNE_PLAYED		; <- $641D
		beq	TUNE_PLAY
		ldx	#$11
		jmp	PAUSE

TUNE_PLAY:
		inc	TUNE_PLAYED		; <- $667E
		ldx	#$00
		stx	NOTE_INDEX
TUNE_NEXT:
		ldx	NOTE_INDEX		; <- $66C0
		lda	TUNE_NOTES,x
		beq	TUNE_END
		sta	NOTE_PERIOD
		inx
		lda	TUNE_NOTES,x
		sta	NOTE_COUNT
		inx
		lda	TUNE_NOTES,x
		sta	NOTE_LEN_HI
		inx
		lda	TUNE_NOTES,x
		sta	NOTE_LEN_LO
		inx
		stx	NOTE_INDEX
		jsr	PLAY_NOTE
		lda	#$60
		jsr	WAIT
		lda	sys::KBD
		bmi	TUNE_KEY
		lda	sys::BUTN0
		bmi	TUNE_BUTN0
		lda	sys::BUTN1
		bmi	TUNE_BUTN1
		jmp	TUNE_NEXT

TUNE_BUTN0:
		lda	sys::BUTN0		; <- $66B9 $66C6
		bmi	TUNE_BUTN0
		bpl	TUNE_END
TUNE_BUTN1:
		lda	sys::BUTN1		; <- $66BE $66CD
		bmi	TUNE_BUTN1
TUNE_END:
		sta	sys::KBDSTRB		; the end of the tune (0), or a button: on with the script. A key: TURN_DISK | <- $6690 $66C8
		rts

TUNE_KEY:
		clc				; <- $66B4
		jmp	TURN_DISK

; a note: clicks every NOTE_PERIOD loops, for about NOTE_PERIOD x NOTE_LEN_LO x NOTE_LEN_HI loops (?)
PLAY_NOTE:
		lda	NOTE_LEN_LO		; <- $66A9
		sta	NOTE_D6
		lda	NOTE_LEN_HI
		sta	NOTE_D7
		lda	NOTE_PERIOD
		sta	NOTE_D8
PN_RELOAD:
		sta	NOTE_COUNT		; NOTE_COUNT from the table is overwritten here: the notes' 2nd byte is unused | <- $66F2
		jsr	CLICK
PN_LOOP:
		lda	NOTE_COUNT		; <- $66FB $670A $6716
		sbc	#$01
		sta	NOTE_COUNT
		bne	PN_TICK
		lda	NOTE_PERIOD
		jmp	PN_RELOAD

PN_TICK:
		lda	NOTE_D8			; <- $66EE
		sbc	#$01
		sta	NOTE_D8
		bne	PN_LOOP
		jsr	CLICK
		lda	NOTE_PERIOD
		sta	NOTE_D8
		lda	NOTE_D6
		sbc	#$01
		sta	NOTE_D6
		bne	PN_LOOP
		lda	NOTE_LEN_LO
		sta	NOTE_D6
		lda	NOTE_D7
		sbc	#$01
		sta	NOTE_D7
		bne	PN_LOOP
		rts

CLICK:
		bit	sys::SPKR		; <- $66E5 $66FD
		rts

; 42 notes: period, (unused), length hi, length lo; 0 ends
TUNE_NOTES:
		.db	$32,$02,$31,$02,$3F,$08,$1D,$08
		.db	$55,$07,$1C,$07,$4C,$02,$20,$02
		.db	$55,$02,$1C,$02,$60,$02,$19,$02
		.db	$55,$07,$1C,$07,$60,$02,$19,$02
		.db	$67,$02,$17,$02,$60,$02,$19,$02
		.db	$55,$05,$1C,$05,$67,$02,$17,$02
		.db	$74,$02,$15,$02,$88,$08,$12,$08
		.db	$3F,$03,$27,$03,$4C,$06,$20,$06
		.db	$55,$03,$1C,$03,$60,$03,$19,$03
		.db	$55,$06,$1C,$06,$60,$03,$19,$03
		.db	$55,$03,$1C,$03,$4C,$0A,$20,$0A
		.db	$43,$03,$24,$03,$3F,$06,$27,$06
		.db	$43,$03,$24,$03,$4C,$03,$20,$03
		.db	$43,$06,$24,$06,$4C,$03,$20,$03
		.db	$55,$03,$1C,$03,$4C,$06,$20,$06
		.db	$55,$03,$1C,$03,$60,$03,$19,$03
		.db	$55,$06,$1C,$06,$67,$04,$17,$04
		.db	$81,$02,$13,$02,$74,$0B,$15,$0B
		.db	$55,$07,$1C,$07,$3F,$0A,$27,$0A
		.db	$81,$02,$13,$02,$81,$02,$13,$02
		.db	$81,$02,$13,$02,$81,$0A,$13,$0A
		.db	$00
; the script's end: the bottom 9 rows of page 2 (Y 0-8) inverted 7 times, then the script again
FLASH_BAND:
		lda	#$06			; <- $63DE
		sta	FLASH_COUNT
FLASH_LOOP:
		ldx	#$09			; <- $67FC
		jsr	PAUSE
		inc	COUNTER
		lda	sys::KBD
		bpl	FLASH_ROWS
		sta	sys::KBDSTRB
		clc
		jmp	TURN_DISK

FLASH_ROWS:
		ldx	#$08			; <- $67D4
FLASH_ROW:
		lda	ROW_LO,x		; <- $67F8
		sta	WIPE_SRC
		lda	ROW_HI,x
		clc
		adc	#$20
		sta	WIPE_SRC+1
		ldy	#$27
FLASH_BYTE:
		lda	(WIPE_SRC),y		; <- $67F5
		eor	#$7F
		sta	(WIPE_SRC),y
		dey
		bpl	FLASH_BYTE
		dex
		bpl	FLASH_ROW
		dec	FLASH_COUNT
		bpl	FLASH_LOOP
		lda	#$00
		sta	SCRIPT_PC
		jmp	RUN_SCRIPT

; not called: fills page 2 with AA D5 and shows it
FILL_PAGE2:
		lda	#$00
		sta	WIPE_SRC
		lda	#$40
		sta	WIPE_SRC+1
		ldy	#$00
FILL_LOOP:
		lda	#$AA			; <- $681A $6822
		sta	(WIPE_SRC),y
		iny
		lda	#$D5
		sta	(WIPE_SRC),y
		iny
		bne	FILL_LOOP
		inc	WIPE_SRC+1
		lda	WIPE_SRC+1
		cmp	#$60
		bne	FILL_LOOP
		bit	sys::PAGE2ON
		rts

; a picture from (PACK_SRC) to the hires page PAGE: RLE, 0 count value (count 0 = 256) or a literal byte;
; column by column, the odd rows first (1, 3 ... 191 of columns 0-$27), then the even rows
UNPACK:
		lda	PAGE			; <- $6442
		ora	#$04
		sta	PACK_DST+1
		ldx	#$01
		stx	PACK_PASS
		ldy	#$00
		sty	PACK_COL
		sty	PACK_DST
		sty	RUN_COUNT
UNPACK_NEXT:
		lda	(PACK_SRC),y		; <- $687B $687F
		bne	UNPACK_PUT
		inc	PACK_SRC
		bne	UNPACK_COUNT
		inc	PACK_SRC+1
UNPACK_COUNT:
		lda	(PACK_SRC),y		; <- $6840
		sta	RUN_COUNT
		inc	PACK_SRC
		bne	UNPACK_VALUE
		inc	PACK_SRC+1
UNPACK_VALUE:
		lda	(PACK_SRC),y		; <- $684A
		sta	RUN_VALUE
UNPACK_RUN:
		lda	RUN_VALUE		; <- $6877
		dec	RUN_COUNT
UNPACK_PUT:
		ldy	PACK_COL		; <- $683C
		sta	(PACK_DST),y
		inx
		inx
		cpx	#$C0
		bcc	UNPACK_ROW
		inc	PACK_COL
		ldy	PACK_COL
		cpy	#$28
		bcc	UNPACK_COL
		dec	PACK_PASS
		bmi	UNPACK_DONE
		ldy	#$00
		sty	PACK_COL
UNPACK_COL:
		ldx	PACK_PASS		; <- $6866
UNPACK_ROW:
		jsr	ROW_ADDR		; <- $685E
		ldy	RUN_COUNT
		bne	UNPACK_RUN
		inc	PACK_SRC
		bne	UNPACK_NEXT
		inc	PACK_SRC+1
		bne	UNPACK_NEXT
UNPACK_DONE:
		rts				; <- $686A

; PACK_DST = the hires address of screen row X (0 = top), on PAGE
ROW_ADDR:
		txa				; <- $6872
		and	#$C0
		sta	PACK_DST
		lsr	a
		lsr	a
		ora	PACK_DST
		sta	PACK_DST
		txa
		sta	PACK_DST+1
		asl	a
		asl	a
		asl	a
		rol	PACK_DST+1
		asl	a
		rol	PACK_DST+1
		asl	a
		ror	PACK_DST
		lda	PACK_DST+1
		and	#$1F
		ora	PAGE
		sta	PACK_DST+1
		rts

; the intro's end. C = 0: a key or a button; C = 1: CHECK_SIDE found side B already in the drive
TURN_DISK:
		sta	sys::KBDSTRB		; <- 5 refs
		php
; LC: bank 1 RAM read / write (the CAPTAIN module), what the game runs with
		bit	sys::ROMIN2
		ldy	#$08
		lda	sys::LCBANK1-8,y
		lda	sys::LCBANK1-8,y
		lda	#$C0			; $2D/$2E = SPKR (the game's sound? not seen yet)
		sta	$2E
		lda	#$30
		sta	$2D
; MIRROR ($0200): each byte's 7 pixel bits reversed, bit 7 (palette) kept, for FLIP (?)
		ldx	#$00
		stx	MIRROR_TMP
MIRROR_BYTE:
		txa				; <- $68D9
		and	#$80
		sta	PAL_BIT
		txa
		and	#$7F
		ldy	#$07
MIRROR_BIT:
		ror	a			; <- $68CF
		pha
		rol	MIRROR_TMP
		pla
		dey
		bne	MIRROR_BIT
		lda	MIRROR_TMP
		ora	PAL_BIT
		sta	MIRROR,x
		inx
		bne	MIRROR_BYTE
; $1F00: X (2-pixel units) -> byte column (X / 3.5): 0-$27 for X 0-139, then $DE-$FF (-34..-1) for X 140-255
		ldx	#$00
		ldy	#$00
XCOL_PAIR:
		cpy	#$28			; <- $690D
		bne	XCOL_EVEN
		ldy	#$DE
		tya
		sta	$1F00,x
		bne	XCOL_ODD
XCOL_EVEN:
		tya				; <- $68E1
		sta	$1F00,x
		inx
		sta	$1F00,x
		inx
		sta	$1F00,x
		inx
		sta	$1F00,x
XCOL_ODD:
		inx				; <- $68E9
		iny
		tya
		sta	$1F00,x
		inx
		sta	$1F00,x
		inx
		sta	$1F00,x
		inx
		iny
		beq	CLEAR_HGR
		jmp	XCOL_PAIR

; clears both hires pages, shows page 2 (blank), full screen
CLEAR_HGR:
		lda	#$00			; <- $690B
		sta	SCRN
		lda	#$20
		sta	SCRN+1
		ldy	#$00
CLEAR_HGR_LOOP:
		lda	#$00			; <- $691F $6927
		sta	(SCRN),y
		iny
		bne	CLEAR_HGR_LOOP
		inc	SCRN+1
		lda	SCRN+1
		cmp	#$60
		bne	CLEAR_HGR_LOOP
		bit	sys::TEXTOFF
		bit	sys::HIRESON
		bit	sys::MIXEDOFF
		bit	sys::PAGE2ON
; draws the message on page 1, Y $96 down to $8C (rows 41-51), then shows it
DRAW_MSG:

; rehost: no disk to turn over. The original went on drawing the message on page 1 (LDA #$00 / STA SCRN_PAGE, then
; below), showed it and waited for a key or a button: now straight to section 1, page 2 (blank) shown.
		;lda	#$00
		;sta	SCRN_PAGE

		plp				; TURN_DISK's PHP, as FLUSH_KBD's end did
		jmp	TO_SECTION1
		.if	* != $6939
			.error	"DRAW_MSG's patch must replace exactly LDA #$00 / STA SCRN_PAGE"
		.end

	; not reached any more
		lda	#<TURN_MSG
		sta	SRC
		lda	#>TURN_MSG
		sta	SRC+1
		lda	#$96			; the top row: Y $96 (screen row 41)
		sta	MSG_Y
MSG_ROW:
		ldx	MSG_Y			; <- $696A
		jsr	SETSCRN
		lda	#$00
		sta	MSG_X
MSG_BYTE:
		ldy	#$00			; <- $6962
		lda	(SRC),y
		ldy	MSG_X
		sta	(SCRN),y
		inc	SRC
		bne	MSG_NEXT
		inc	SRC+1
MSG_NEXT:
		inc	MSG_X			; <- $6958
		lda	MSG_X
		cmp	#$28
		bne	MSG_BYTE
		dec	MSG_Y
		lda	MSG_Y
		cmp	#$8B			; down to Y $8C (row 51): 11 rows
		bne	MSG_ROW
		bit	sys::PAGE2OFF
		ldx	#$00
FLUSH_KBD:
		sta	sys::KBDSTRB		; <- $6975
		inx
		bne	FLUSH_KBD
		plp				; C = 1: no question, side B is in already
		bcs	TO_SECTION1
WAIT_KEY:
		lda	sys::KBD		; <- $6987
		bmi	TO_SECTION1
		lda	sys::BUTN0
		bmi	WAIT_BUTN0
		lda	sys::BUTN1
		bpl	WAIT_KEY
WAIT_BUTN1:
		lda	sys::BUTN1		; <- $698C
		bmi	WAIT_BUTN1
		bpl	TO_SECTION1
WAIT_BUTN0:
		lda	sys::BUTN0		; <- $6982 $6993
		bmi	WAIT_BUTN0
TO_SECTION1:
		sta	sys::KBDSTRB		; <- $6978 $697D $698E
		bit	sys::PAGE2ON		; page 2, blank, for LOAD_SECTION's messages
; LOAD_SECTION 1 (side B): if side A is still in, it asks "PLEASE FLIP DISK AND PRESS A KEY."
		lda	#$01
		jmp	JMPDISK

; "TURN DISK OVER AND PRESS ANY KEY." in a striped frame: 11 rows x 40 bytes, the top row first
TURN_MSG:
		.db	$D5,$AA,$D5,$AA,$D5,$AA,$D5,$AA
		.db	$D5,$AA,$D5,$AA,$D5,$AA,$D5,$AA
		.db	$D5,$AA,$D5,$AA,$D5,$AA,$D5,$AA
		.db	$D5,$AA,$D5,$AA,$D5,$AA,$D5,$AA
		.db	$D5,$AA,$D5,$AA,$D5,$AA,$D5,$AA
		.db	$80,$80,$80,$80,$80,$80,$80,$80
		.db	$80,$00,$80,$80,$80,$80,$80,$80
		.db	$80,$80,$80,$00,$80,$80,$80,$80
		.db	$80,$80,$80,$80,$80,$00,$80,$80
		.db	$80,$80,$80,$80,$80,$80,$80,$00
		.db	$AA,$D5,$AA,$BF,$B3,$9F,$E3,$80
		.db	$BE,$BC,$9E,$B3,$80,$9E,$B3,$BE
		.db	$9F,$80,$8C,$E3,$BE,$80,$9F,$9F
		.db	$BE,$9E,$9E,$80,$8C,$E3,$E6,$80
		.db	$B3,$BE,$B3,$C0,$AA,$D5,$AA,$95
		.db	$AA,$D5,$AA,$8C,$B3,$B3,$E7,$80
		.db	$E6,$98,$B3,$9B,$80,$B3,$B3,$86
		.db	$B3,$80,$9E,$E7,$E6,$80,$B3,$B3
		.db	$86,$B3,$B3,$80,$9E,$E7,$E6,$80
		.db	$9B,$86,$B3,$C0,$AA,$D5,$AA,$95
		.db	$AA,$D5,$AA,$8C,$B3,$B3,$EF,$80
		.db	$E6,$98,$83,$8F,$80,$B3,$B3,$86
		.db	$B3,$80,$B3,$EF,$E6,$80,$B3,$B3
		.db	$86,$83,$83,$80,$B3,$EF,$BC,$80
		.db	$8F,$86,$9E,$C0,$AA,$D5,$AA,$95
		.db	$AA,$D5,$AA,$8C,$B3,$9F,$FB,$80
		.db	$E6,$98,$9E,$8F,$80,$B3,$92,$9E
		.db	$9F,$80,$B3,$FB,$E6,$80,$9F,$9F
		.db	$9E,$9E,$9E,$80,$B3,$FB,$98,$80
		.db	$8F,$9E,$8C,$C0,$AA,$D5,$AA,$95
		.db	$AA,$D5,$AA,$8C,$B3,$9B,$F3,$80
		.db	$E6,$98,$B0,$9B,$80,$B3,$9E,$86
		.db	$9B,$80,$BF,$F3,$E6,$80,$83,$9B
		.db	$86,$B0,$B0,$80,$BF,$F3,$98,$80
		.db	$9B,$86,$8C,$C0,$AA,$D5,$AA,$95
		.db	$AA,$D5,$AA,$8C,$B3,$B3,$E3,$80
		.db	$E6,$98,$B3,$B3,$80,$B3,$8C,$86
		.db	$B3,$80,$B3,$E3,$E6,$80,$83,$B3
		.db	$86,$B3,$B3,$80,$B3,$E3,$98,$80
		.db	$B3,$86,$8C,$CE,$AA,$D5,$AA,$95
		.db	$AA,$D5,$AA,$8C,$9E,$B3,$E3,$80
		.db	$BE,$BC,$9E,$B3,$80,$9E,$8C,$BE
		.db	$B3,$80,$B3,$E3,$BE,$80,$83,$B3
		.db	$BE,$9E,$9E,$80,$B3,$E3,$98,$80
		.db	$B3,$BE,$8C,$CE,$AA,$D5,$AA,$95
		.db	$80,$80,$80,$80,$80,$80,$80,$80
		.db	$80,$00,$80,$80,$80,$80,$80,$80
		.db	$80,$80,$80,$00,$80,$80,$80,$80
		.db	$80,$80,$80,$80,$80,$00,$80,$80
		.db	$80,$80,$80,$80,$80,$80,$80,$00
		.db	$D5,$AA,$D5,$AA,$D5,$AA,$D5,$AA
		.db	$D5,$AA,$D5,$AA,$D5,$AA,$D5,$AA
		.db	$D5,$AA,$D5,$AA,$D5,$AA,$D5,$AA
		.db	$D5,$AA,$D5,$AA,$D5,$AA,$D5,$AA
		.db	$D5,$AA,$D5,$AA,$D5,$AA,$D5,$AA
; both buttons read as down: no joystick (or a bad one). The message, and a hang
CHECK_JOYSTICK:
		lda	sys::BUTN0		; <- $6314
		bmi	CHECK_BUTN1
		rts

CHECK_BUTN1:
		lda	sys::BUTN1		; <- $6B5B
		bmi	NO_JOYSTICK
		rts

NO_JOYSTICK:
		lda	#$00			; <- $6B61
		sta	PACK_DST
		lda	#$04
		sta	PACK_DST+1
		ldy	#$00
CLEAR_TEXT:
		lda	#$A0			; <- $6B73 $6B7B
		sta	(PACK_DST),y
		iny
		bne	CLEAR_TEXT
		inc	PACK_DST+1
		lda	PACK_DST+1
		cmp	#$08
		bne	CLEAR_TEXT
		bit	sys::KBDSTRB
		lda	#$00
		sta	PACK_DST
		lda	#$05
		sta	PACK_DST+1
		ldy	#$00
		ldx	#$00
JOY_LINE1:
		lda	JOY_MSG1,x		; <- $6B95
		sta	(PACK_DST),y
		inx
		iny
		cpy	#$28
		bne	JOY_LINE1
		lda	#$06
		sta	PACK_DST+1
		ldy	#$00
		ldx	#$00
JOY_LINE2:
		lda	JOY_MSG2,x		; <- $6BA8
		sta	(PACK_DST),y
		inx
		iny
		cpy	#$28
		bne	JOY_LINE2
		bit	sys::PAGE2OFF
		bit	sys::TEXTON
		bit	sys::MIXEDOFF
HANG:
		jmp	HANG			; <- $6BB3

JOY_MSG1:
		.db	$A0,$A0,$A0,$A0,$CA,$CF,$D9,$D3,$D4,$C9,$C3,$CB,$A0,$CE,$CF,$D4,$A0,$C3,$CF,$CE,$CE,$C5,$C3,$D4,$C5,$C4,$A0,$D0,$D2,$CF,$D0,$C5,$D2,$CC,$D9,$BA,$A0,$A0,$A0,$A0	; text row 2
JOY_MSG2:
		.db	$D0,$CC,$C5,$C1,$D3,$C5,$A0,$C3,$C8,$C5,$C3,$CB,$A0,$C6,$CF,$D2,$A0,$CC,$CF,$CF,$D3,$C5,$A0,$CF,$D2,$A0,$CE,$CF,$A0,$C3,$CF,$CE,$CE,$C5,$C3,$D4,$C9,$CF,$CE,$AE	; text row 4
; rehost: $6C06-$6FFF held a leftover, a piece of a tokenized Applesoft program (a developers' tool for a
; "VIRTUAL DRIVE/TRACK OFFSET TABLE"; see out/intro.lst): nothing reads it
		.fill	$7000 - *, $00
