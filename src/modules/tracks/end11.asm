; Section 11 (END11), side A T21-T22: $6300-$82FF, the Hall of Fame. Copied from out/asm/end11/end11.asm (dis.py,
; meta/end11.meta, round-trip checked), then maintained here: the meta's listing (out/end11.lst) is the original's.
	.cpu 65C02

SLOT16 = $45
yhigh = $18EA
ylow = $19AA
DOTEXT = $1A6A
WAITING = $D000

	.org $6300
END11:
	jmp START

SECTION_MARKS:
	.db $47,$00                            ; DISK_MARK ($6303) = SECTION_MARK[11], SIDE_MARK ($6304) = 0 (side A): checked by LOAD_SECTION
OUTCOME:
	.db $00                                ; $80 at the start: 0 = no name to enter, show the Hall of Fame
FORMAT:
	.db $00                                ; 1: WRITE_HOF writes even where no D5 FF DD field is found (a new table)
; section 11's start: the Hall of Fame. Loads it (T20 at $B000); if that fails, writes a new one
START:
	ldx #$FF                               ; <- $6300
	txs
	lda $80
	sta OUTCOME
	lda sys::KBDSTRB
	lda sys::ROMIN2
	lda sys::LCBANK1
	lda sys::LCBANK1
	lda #$44
	sta $F0
	sta sys::KBDSTRB
	jsr LOAD_HOF
	bcc L6337
	jsr L67B8
	lda #$01
	sta FORMAT
	jsr WRITE_HOF
	lda #$00
	sta FORMAT
; the screen
L6337:
	lda #$0F                               ; <- $6325
	sta $0800
	lda #$68
	sta $0801
	lda #$E3
	sta $0802
	lda #$67
	sta $0803
	jsr $1CB2
	lda #$08
	sta $42
	lda #$00
	sta $0B
	lda #$20
	sta $0C
	ldy #$00
L635C:
	lda #$80                               ; <- $6361 $6369
	sta ($0B),y
	iny
	bne L635C
	inc $0C
	lda $0C
	cmp #$60
	bne L635C
	ldx #$06
L636D:
	lda ylow,x                             ; <- $638A
	sta $0B
	sta $0D
	lda yhigh,x
	sta $0C
	clc
	adc #$20
	sta $0E
	ldy #$27
	lda #$FF
L6382:
	sta ($0B),y                            ; <- $6387
	sta ($0D),y
	dey
	bpl L6382
	dex
	bpl L636D
	bit sys::PAGE2ON
	lda #$00
	sta $0F
; OUTCOME <> 0: a name to enter (ENTER_NAME), inserted at $B100,Y (INSERT_NAME), written back
L6393:
	lda OUTCOME                            ; <- $6709
	beq L63AD
	jsr L6693
	jsr L65EA
	jsr L658C
	jsr ENTER_NAME
	jsr INSERT_NAME
	jsr WRITE_HOF
	jmp L6737

; OUTCOME = 0: shows the table
L63AD:
	lda #$FF                               ; <- $6396
	sta $6692
	jsr L65F5
	ldx #$02
L63B7:
	lda #$00                               ; <- $63BD
	jsr DELAY
	dex
	bpl L63B7
	jmp L6737

INSERT_NAME:
	ldx #$00                               ; <- $63A4
	ldy $6690
L63C7:
	lda $63D5,x                            ; <- $63D1
	sta $B100,y
	inx
	iny
	cpx #$14
	bne L63C7
	rts

	.fill 33, $00
ENTER_NAME:
	lda #$00                               ; <- $63A1
	sta $65CB
	lda #$63
	sta $2F
	lda #$64
	sta $30
	jsr DOTEXT
L6405:
	lda sys::KBD                           ; <- 7 refs
	bmi L640D
	jmp L64B2

L640D:
	sta sys::KBDSTRB                       ; <- $6408
	cmp #$8D
	bne L6417
	jmp L64E9

L6417:
	cmp #$88                               ; <- $6412
	bne L641E
	jmp L6489

L641E:
	cmp #$BA                               ; <- $6419
	bcs L643E
	cmp #$B0
	bcc L642F
	sec
	sbc #$B0
	sta $63D4
	jmp L64ED

L642F:
	cmp #$A0                               ; <- $6424
	beq L6436
	jmp L6405

L6436:
	lda #$0B                               ; <- $6431
	sta $63D4
	jmp L64ED

L643E:
	cmp #$C1                               ; <- $6420
	bcs L644C
	sec
	sbc #$20
	cmp #$C1
	bcs L644C
	jmp L6405

L644C:
	cmp #$DB                               ; <- $6440 $6447
	bcc L645A
	sec
	sbc #$20
	cmp #$DB
	bcc L645A
	jmp L6405

L645A:
	sec                                    ; <- $644E $6455
	sbc #$B1
	sta $63D4
	jmp L64ED

	.db $27,$13,$18,$0F,$04,$27,$08,$0D
	.db $27,$18,$0E,$14,$11,$27,$0D,$00
	.db $0C,$04,$24,$24,$24,$11,$04,$13
	.db $14,$11,$0D,$27,$13,$0E,$27,$04
	.db $0D,$13,$04,$11,$24,$FF
L6489:
	lda $65CB                              ; <- $641B
	bne L6491
	jmp L6405

L6491:
	ldx $6692                              ; <- $648C
	lda $65CC,x
	tay
	ldx $65CB
	lda $65D6,x
	tax
	lda #$0B
	jsr L67D5
	lda #$0B
	ldx $65CB
	sta $63D5,x
	dec $65CB
	jmp L6405

L64B2:
	lda #$00                               ; <- $640A
	sta $10
	ldx $6692
	lda $65CC,x
	tay
	ldx $65CB
	lda $65D6,x
	tax
	lda #$0F
	jsr L67D5
	lda #$70
	jsr DELAY
	ldx $6692
	lda $65CC,x
	tay
	ldx $65CB
	lda $65D6,x
	tax
	lda #$0B
	jsr L67D5
	lda #$70
	jsr DELAY
	jmp L6405

L64E9:
	jsr L651D                              ; <- $6414 $6514
	rts

L64ED:
	ldx $6692                              ; <- $642C $643B $6460
	lda $65CC,x
	tay
	ldx $65CB
	lda $65D6,x
	tax
	lda $63D4
	jsr L67D5
	ldx $65CB
	lda $63D4
	sta $63D5,x
	lda $65CB
	cmp #$0D
	bne L6517
	inc $65CB
	jmp L64E9

L6517:
	inc $65CB                              ; <- $650F
	jmp L6405

L651D:
	lda #$01                               ; <- $64E9
	sta $10
	ldx $65CB
	bne L6529
	jmp L655F

L6529:
	ldx $6692                              ; <- $6524 $654C
	lda $65CC,x
	tay
	ldx $65CB
	lda $65D6,x
	tax
	lda #$0C
	jsr L67D5
	ldx $65CB
	lda #$0C
	sta $63D5,x
	inc $65CB
	lda $65CB
	cmp #$0F
	bne L6529
	rts

	.db $12,$1B,$10,$22,$22,$18,$15,$18
	.db $14,$13,$0C,$0C,$0C,$0C,$0C,$00
L655F:
	lda #$00                               ; <- $6526
	sta $655E
L6564:
	ldx $655E                              ; <- $6588
	lda $654F,x
	pha
	sta $63D5,x
	ldx $6692
	lda $65CC,x
	tay
	ldx $655E
	lda $65D6,x
	tax
	pla
	jsr L67D5
	inc $655E
	lda $655E
	cmp #$0F
	bne L6564
	rts

	.db $00
L658C:
	lda #$0F                               ; <- $639E
	sta $658B
	lda $6687
	jsr L65AB
	lda $6688
	jsr L65AB
	lda #$0A
	jsr L65AB
	lda $6689
	jsr L65AB
	lda $668A
L65AB:
	pha                                    ; <- $6594 $659A $659F $65A5
	ldx $6692
	lda $65CC,x
	tay
	ldx $658B
	lda $65D6,x
	tax
	pla
	pha
	jsr L67D5
	ldx $658B
	pla
	sta $63D5,x
	inc $658B
	rts

	.db $00,$00,$13,$20,$2D,$3A,$47,$54
	.db $61,$6E,$7B,$88,$00,$07,$0E,$15
	.db $1C,$23,$2A,$31,$38,$3F,$46,$4D
	.db $54,$5B,$62,$69,$70,$77,$7E,$85
L65EA:
	lda #$00                               ; <- $639B
	sta $E0
	lda #$B1
	sta $E1
	jmp L65FD

L65F5:
	lda #$00                               ; <- $63B2
	sta $E0
	lda #$B0
	sta $E1
L65FD:
	lda #$00                               ; <- $65F2
	sta $65CB
	lda #$09
	sta $65CA
	lda #$00
	sta $10
	ldx #$00
	ldy #$BF
	lda #$2A
	jsr L67D5
	ldx #$46
	ldy #$BF
	lda #$2B
	jsr L67D5
	bit sys::PAGE2OFF
	lda #$20
	sta $0F
	ldx #$00
	ldy #$BF
	lda #$2A
	jsr L67D5
	ldx #$46
	ldy #$BF
	lda #$2B
	jsr L67D5
	lda #$01
	sta $10
L663A:
	ldy #$00                               ; <- $6667 $6671
	lda $65CA
	cmp $6692
	beq L6677
	lda ($E0),y
	pha
	ldx $65CA
	lda $65CC,x
	tay
	ldx $65CB
	lda $65D6,x
	tax
	pla
	jsr L67D5
	inc $E0
	bne L665F
	inc $E1
L665F:
	inc $65CB                              ; <- $665B
	lda $65CB
	cmp #$14
	bne L663A
L6669:
	lda #$00                               ; <- $6684
	sta $65CB
	dec $65CA
	bpl L663A
	bit sys::PAGE2ON
	rts

L6677:
	lda $E0                                ; <- $6642
	clc
	adc #$14
	sta $E0
	lda #$00
	adc $E1
	sta $E1
	jmp L6669

	.db $00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00
L6693:
	lda #$00                               ; <- $6398
	sta $6690
	lda #$09
	sta $6692
	lda $62D5
	sta $668A
	lda $62D6
	sta $6689
	lda $62D3
	sta $6688
	lda $62D4
	sta $6687
L66B5:
	ldx $6690                              ; <- $6724
	lda $B00F,x
	sta $668C
	lda $B010,x
	sta $668B
	lda $B012,x
	sta $668E
	lda $B013,x
	sta $668D
	lda $6687
	cmp $668C
	beq L66DD
	bcs L6727
	jmp L66FF

L66DD:
	lda $6688                              ; <- $66D6
	cmp $668B
	beq L66EA
	bcs L6727
	jmp L66FF

L66EA:
	lda $6689                              ; <- $66E3
	cmp $668E
	beq L66F7
	bcs L6727
	jmp L66FF

L66F7:
	lda $668A                              ; <- $66F0
	cmp $668D
	bcs L6727
L66FF:
	dec $6692                              ; <- $66DA $66E7 $66F4
	bpl L670C
	lda #$00
	sta OUTCOME
	jmp L6393

L670C:
	lda $6690                              ; <- $6702
	tax
	clc
	adc #$14
	sta $6690
	ldy #$00
L6718:
	lda $B000,x                            ; <- $6722
	sta $B100,x
	inx
	iny
	cpy #$14
	bne L6718
	jmp L66B5

L6727:
	ldx $6690                              ; <- $66D8 $66E5 $66F2 $66FD
L672A:
	lda $B000,x                            ; <- $6733
	sta $B114,x
	inx
	cpx #$E0
	bne L672A
	rts

	.db $00
; the end: waits for a key, a button, or a while, then reboots the disk's slot
L6737:
	lda #$7E                               ; <- $63AA $63BF
	sta $2F
	lda #$67
	sta $30
	jsr $1AD2
	jsr DOTEXT
	lda #$00
	sta $6736
L674A:
	lda #$00                               ; <- $6766
	jsr DELAY
	lda sys::KBD
	bmi L6768
	lda sys::BUTN1
	bmi L6768
	lda sys::BUTN0
	bmi L6768
	inc $6736
	lda $6736
	cmp #$C8
	bne L674A
L6768:
	sta sys::KBDSTRB                       ; <- $6752 $6757 $675C
	lda sys::ROMIN2
; rehost: the original built JMP $Cn00 from SLOT16 (section 1's start: LDA SLOT16 / ROR x 4 / AND #$0F / ORA #$C0 /
; STA $677D / JMP $C000). Page 3's REBOOT jumps to the boot slot, set by Init: section 1 doesn't keep the slot.
	jmp game::REBOOT
	.fill	$677E - *, $EA

	.db $27,$0F,$11,$04,$12,$12,$27,$00
	.db $0D,$18,$27,$0A,$04,$18,$27,$0E
	.db $11,$27,$01,$14,$13,$13,$0E,$0D
	.db $27,$13,$0E,$27,$02,$0E,$0D,$13
	.db $08,$0D,$14,$04,$24,$FF,$0B,$0B
	.db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
	.db $0B,$0B,$0B,$0B,$0B,$00,$00,$0A
	.db $00,$00
L67B8:
	ldx #$00                               ; <- $6327
	ldy #$00
L67BC:
	lda $67A4,x                            ; <- $67C9 $67D1
	sta $B000,y
	sta $B100,y
	inx
	iny
	cpx #$14
	bne L67BC
	cpy #$F0
	bcs L67D4
	ldx #$00
	jmp L67BC

L67D4:
	rts                                    ; <- $67CD

L67D5:
	cmp #$2C                               ; <- 12 refs
	bcs L67E2
	sta $21
	stx $20
	sty $1F
	jmp $0807

L67E2:
	rts                                    ; <- $67D7

	.db $68,$68,$68,$68,$68,$68,$68,$68
	.db $68,$69,$69,$69,$69,$69,$69,$69
	.db $69,$69,$69,$6A,$6A,$6A,$6A,$6A
	.db $6A,$6A,$6A,$6A,$6A,$6A,$6B,$6B
	.db $6B,$6B,$6B,$6B,$6B,$6B,$6B,$6B
	.db $6B,$6C,$6C,$70,$3B,$53,$6B,$83
	.db $9B,$B3,$CB,$E3,$FB,$13,$2B,$43
	.db $5B,$73,$8B,$A3,$BB,$D3,$EB,$03
	.db $1B,$33,$4B,$63,$7B,$93,$AB,$C3
	.db $DB,$F3,$0B,$23,$3B,$53,$6B,$83
	.db $9B,$B3,$CB,$E3,$FB,$13,$2B,$3D
	.db $02,$0B,$FE,$9F,$87,$BC,$87,$BE
	.db $87,$BB,$C7,$B9,$E7,$B8,$B7,$B8
	.db $9F,$BC,$8F,$BC,$87,$BC,$FE,$9F
	.db $02,$0B,$E0,$81,$F0,$81,$F0,$81
	.db $E0,$81,$E0,$81,$E0,$81,$E0,$81
	.db $F0,$83,$F0,$83,$F0,$83,$F0,$83
	.db $02,$0B,$FF,$9F,$80,$B8,$80,$B8
	.db $80,$B8,$FE,$9F,$87,$80,$87,$80
	.db $8F,$80,$8F,$80,$8F,$80,$FF,$BF
	.db $02,$0B,$FF,$8F,$80,$9C,$80,$9C
	.db $80,$9C,$FC,$9F,$80,$BC,$80,$BC
	.db $80,$BE,$80,$BE,$80,$BE,$FF,$9F
	.db $02,$0B,$87,$B8,$87,$B8,$87,$B8
	.db $87,$B8,$FF,$BF,$80,$B8,$80,$B8
	.db $80,$BC,$80,$BC,$80,$BC,$80,$BC
	.db $02,$0B,$FF,$9F,$87,$80,$87,$80
	.db $87,$80,$FF,$9F,$80,$B8,$80,$B8
	.db $80,$BC,$80,$BC,$80,$BC,$FF,$9F
	.db $02,$0B,$FE,$9F,$87,$80,$87,$80
	.db $87,$80,$FF,$9F,$87,$B8,$87,$B8
	.db $8F,$BC,$8F,$BC,$8F,$BC,$FE,$9F
	.db $02,$0B,$FF,$BF,$8F,$B8,$80,$9C
	.db $80,$8E,$80,$87,$C0,$83,$E0,$81
	.db $F0,$83,$F0,$83,$F0,$83,$F0,$83
	.db $02,$0B,$FE,$9F,$87,$B8,$87,$B8
	.db $87,$B8,$FE,$9F,$87,$B8,$87,$B8
	.db $87,$B8,$87,$B8,$87,$B8,$FE,$9F
	.db $02,$0B,$FE,$9F,$87,$B8,$87,$B8
	.db $87,$B8,$FE,$BF,$80,$B8,$80,$B8
	.db $80,$BC,$80,$BC,$80,$BC,$FF,$9F
	.db $02,$0B,$80,$80,$E0,$83,$E0,$83
	.db $E0,$83,$80,$80,$80,$80,$80,$80
	.db $E0,$83,$E0,$83,$E0,$83,$80,$80
	.db $02,$0B,$80,$80,$80,$80,$80,$80
	.fill 16, $80
	.db $02,$0B,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $80,$80,$E0,$83,$E0,$83,$E0,$83
	.db $02,$0B,$80,$80,$80,$80,$80,$80
	.db $B0,$80,$9C,$80,$FF,$BF,$9C,$80
	.db $B0,$80,$80,$80,$80,$80,$80,$80
	.db $02,$0B,$9E,$83,$B3,$83,$B3,$83
	.db $B3,$B3,$B3,$B3,$B3,$9B,$B3,$8F
	.db $B3,$9B,$B3,$B3,$B3,$B3,$9E,$B3
	.db $02,$0B,$FF,$BF,$FF,$BF,$FF,$BF
	.db $FF,$BF,$FF,$BF,$FF,$BF,$FF,$BF
	.db $FF,$BF,$FF,$BF,$FF,$BF,$FF,$BF
	.db $02,$0B,$FE,$9F,$FF,$BF,$87,$B8
	.db $87,$B8,$FF,$BF,$87,$B8,$87,$B8
	.db $8F,$BC,$8F,$BC,$8F,$BC,$8F,$BC
	.db $02,$0B,$FF,$8F,$87,$9C,$87,$9C
	.db $87,$9C,$FF,$8F,$87,$9C,$87,$BC
	.db $8F,$BE,$8F,$BE,$8F,$BE,$FF,$9F
	.db $02,$0B,$FE,$9F,$87,$B8,$87,$80
	.db $87,$80,$87,$80,$87,$80,$87,$80
	.db $8F,$B8,$8F,$B8,$8F,$B8,$FE,$9F
	.db $02,$0B,$FF,$9F,$87,$B8,$87,$B8
	.db $87,$B8,$87,$B8,$87,$B8,$87,$B8
	.db $8F,$BC,$8F,$BC,$8F,$BC,$FF,$9F
	.db $02,$0B,$FF,$BF,$87,$80,$87,$80
	.db $87,$80,$FF,$81,$87,$80,$87,$80
	.db $8F,$80,$8F,$80,$8F,$80,$FF,$BF
	.db $02,$0B,$FF,$BF,$87,$80,$87,$80
	.db $87,$80,$FF,$81,$87,$80,$87,$80
	.db $8F,$80,$8F,$80,$8F,$80,$8F,$80
	.db $02,$0B,$FE,$BF,$87,$80,$87,$80
	.db $87,$80,$87,$BE,$87,$B8,$87,$B8
	.db $8F,$BC,$8F,$BC,$8F,$BC,$FE,$BF
	.db $02,$0B,$87,$B8,$87,$B8,$87,$B8
	.db $87,$B8,$FF,$BF,$87,$B8,$87,$B8
	.db $8F,$BC,$8F,$BC,$8F,$BC,$8F,$BC
	.db $02,$0B,$E0,$81,$E0,$81,$E0,$81
	.db $E0,$81,$E0,$81,$E0,$81,$E0,$81
	.db $F0,$83,$F0,$83,$F0,$83,$F0,$83
	.db $02,$0B,$80,$B8,$80,$B8,$80,$B8
	.db $80,$B8,$80,$B8,$80,$B8,$80,$B8
	.db $87,$BC,$87,$BC,$87,$BC,$FE,$9F
	.db $02,$0B,$87,$8E,$87,$87,$C7,$83
	.db $E7,$81,$FF,$83,$87,$87,$87,$8E
	.db $8F,$9C,$8F,$B8,$8F,$B8,$8F,$B8
	.db $02,$0B,$87,$80,$87,$80,$87,$80
	.db $87,$80,$87,$80,$87,$80,$87,$80
	.db $8F,$80,$8F,$80,$8F,$80,$FF,$BF
	.db $02,$0B,$87,$B8,$8F,$BC,$9F,$BE
	.db $BF,$BF,$F7,$BB,$E7,$B9,$87,$B8
	.db $8F,$BC,$8F,$BC,$8F,$BC,$8F,$BC
	.db $02,$0B,$8F,$B8,$9F,$B8,$BF,$B8
	.db $F7,$B8,$E7,$B9,$C7,$BB,$87,$BF
	.db $8F,$BE,$8F,$BC,$8F,$B8,$8F,$B8
	.db $02,$0B,$FE,$9F,$87,$B8,$87,$B8
	.db $87,$B8,$87,$B8,$87,$B8,$87,$B8
	.db $8F,$BC,$8F,$BC,$8F,$BC,$FE,$9F
	.db $02,$0B,$FF,$9F,$87,$B8,$87,$B8
	.db $87,$B8,$FF,$9F,$87,$80,$87,$80
	.db $8F,$80,$8F,$80,$8F,$80,$8F,$80
	.db $02,$0B,$FE,$9F,$87,$B8,$87,$B8
	.db $87,$B8,$87,$B8,$87,$B8,$C7,$B9
	.db $8F,$BB,$8F,$BE,$8F,$9C,$FE,$BB
	.db $02,$0B,$FF,$9F,$87,$B8,$87,$B8
	.db $87,$B8,$FF,$9F,$87,$8E,$87,$9C
	.db $8F,$B8,$8F,$B8,$8F,$B8,$8F,$B8
	.db $02,$0B,$FE,$9F,$87,$B8,$87,$B8
	.db $87,$80,$FE,$9F,$80,$B8,$80,$B8
	.db $87,$BC,$87,$BC,$87,$BC,$FE,$9F
	.db $02,$0B,$FF,$BF,$E0,$81,$E0,$81
	.db $E0,$81,$E0,$81,$E0,$81,$E0,$81
	.db $F0,$83,$F0,$83,$F0,$83,$F0,$83
	.db $02,$0B,$87,$B8,$87,$B8,$87,$B8
	.db $87,$B8,$87,$B8,$87,$B8,$87,$B8
	.db $8F,$BC,$8F,$BC,$8F,$BC,$FE,$9F
	.db $02,$0B,$87,$B8,$87,$B8,$87,$B8
	.db $87,$B8,$87,$B8,$87,$B8,$8E,$9C
	.db $9C,$8E,$B8,$87,$F0,$83,$E0,$81
	.db $02,$0B,$87,$B8,$87,$B8,$87,$B8
	.db $87,$B8,$87,$B8,$E7,$B9,$F7,$BB
	.db $BF,$BF,$9F,$BE,$8F,$BC,$87,$B8
	.db $02,$0B,$87,$B8,$8E,$9C,$9C,$8E
	.db $B8,$87,$F8,$87,$9C,$8E,$8E,$9C
	.db $87,$B8,$87,$B8,$87,$B8,$87,$B8
	.db $02,$0B,$87,$B8,$87,$B8,$87,$B8
	.db $87,$B8,$FE,$9F,$E0,$81,$E0,$81
	.db $F0,$83,$F0,$83,$F0,$83,$F0,$83
	.db $02,$0B,$FF,$BF,$80,$9E,$80,$8F
	.db $C0,$87,$E0,$83,$F0,$81,$F8,$80
	.db $BC,$B8,$9E,$B8,$8F,$B8,$FF,$BF
	.db $14,$34,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$F8,$E3,$CF,$BF
	.db $FE,$F3,$C7,$9F,$C3,$81,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $FC,$F7,$DF,$FF,$FE,$FB,$CF,$9F
	.db $C7,$81,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$8C,$B6,$D8,$E1
	.db $B0,$98,$8C,$86,$CF,$81,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $8C,$B0,$D8,$E1,$B0,$98,$8C,$86
	.db $DB,$81,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$8C,$B0,$D8,$E1
	.db $B0,$98,$8C,$86,$F3,$81,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $8C,$B0,$D8,$E1,$B0,$98,$8C,$86
	.db $E3,$81,$AA,$D5,$AA,$D5,$AA,$FE
	.db $E6,$FE,$A8,$D5,$8C,$B0,$D8,$E1
	.db $B0,$98,$8C,$86,$C3,$D5,$82,$80
	.db $80,$80,$80,$98,$E6,$86,$80,$80
	.db $8C,$B0,$D8,$E1,$B0,$F8,$8F,$86
	.db $C3,$81,$E2,$FF,$FF,$FF,$BF,$98
	.db $FE,$9E,$FC,$FF,$8C,$F0,$DF,$FF
	.db $B0,$F8,$8F,$86,$C3,$FD,$E2,$80
	.db $80,$80,$80,$98,$E6,$86,$80,$80
	.db $8C,$F0,$DF,$BF,$B0,$98,$8C,$86
	.db $C3,$81,$E2,$A8,$D5,$AA,$D5,$98
	.db $E6,$FE,$D4,$AA,$8C,$B0,$D8,$81
	.db $B0,$98,$8C,$86,$C3,$A9,$E2,$88
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $8C,$B0,$D8,$81,$B0,$98,$8C,$86
	.db $C3,$81,$E2,$88,$80,$80,$80,$80
	.db $80,$80,$80,$80,$8C,$B0,$D8,$81
	.db $B0,$98,$8C,$86,$C3,$81,$E2,$88
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $8C,$B0,$D8,$81,$B0,$98,$8C,$86
	.db $C3,$81,$E2,$88,$80,$80,$80,$80
	.db $80,$80,$80,$80,$8C,$B0,$D8,$81
	.db $B0,$98,$8C,$86,$C3,$81,$E2,$88
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $8C,$B0,$D8,$81,$B0,$98,$8C,$86
	.db $C3,$81,$E2,$88,$80,$80,$80,$80
	.db $80,$80,$80,$80,$8C,$B6,$D8,$81
	.db $B0,$98,$8C,$86,$C3,$81,$E2,$88
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $FC,$B7,$D8,$81,$B0,$98,$CC,$9F
	.db $C3,$81,$E2,$88,$80,$80,$80,$80
	.db $80,$80,$80,$80,$F8,$B3,$D8,$81
	.db $B0,$98,$CC,$9F,$C3,$81,$E2,$88
	.fill 18, $80
	.db $E2,$88,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$E2,$88,$80,$80
	.fill 16, $80
	.db $E2,$88,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$E2,$88,$80,$80
	.fill 16, $80
	.db $E2,$88,$80,$BF,$F0,$87,$FC,$83
	.db $FE,$80,$E0,$8F,$80,$80,$80,$FE
	.db $87,$FE,$FF,$8F,$E2,$88,$80,$9E
	.db $E0,$83,$8F,$8F,$BC,$80,$C0,$87
	.db $80,$80,$C0,$87,$9E,$BC,$80,$8E
	.db $E2,$88,$80,$9E,$E0,$C3,$87,$9E
	.db $BC,$80,$C0,$87,$80,$80,$E0,$83
	.db $BC,$BC,$80,$8C,$E2,$88,$80,$9E
	.db $E0,$E3,$83,$BC,$BC,$80,$C0,$87
	.db $80,$80,$F0,$81,$F8,$BC,$80,$80
	.db $E2,$88,$80,$9E,$E0,$E3,$83,$BC
	.db $BC,$80,$C0,$87,$80,$80,$F0,$81
	.db $F8,$BC,$80,$80,$E2,$88,$80,$9E
	.db $E0,$E3,$83,$BC,$BC,$80,$C0,$87
	.db $80,$80,$F0,$81,$F8,$BC,$80,$80
	.db $E2,$88,$80,$9E,$E0,$E3,$83,$BC
	.db $BC,$80,$C0,$87,$80,$80,$F0,$81
	.db $F8,$BC,$80,$80,$E2,$88,$80,$9E
	.db $E0,$E3,$83,$BC,$BC,$80,$C0,$87
	.db $80,$80,$F0,$81,$F8,$BC,$98,$80
	.db $E2,$88,$80,$FE,$FF,$E3,$FF,$BF
	.db $BC,$80,$C0,$87,$80,$80,$F0,$81
	.db $F8,$FC,$9F,$80,$E2,$88,$80,$9E
	.db $E0,$E3,$83,$BC,$BC,$80,$C0,$87
	.db $80,$80,$F0,$81,$F8,$BC,$98,$80
	.db $E2,$88,$80,$9E,$E0,$E3,$83,$BC
	.db $BC,$80,$C0,$87,$80,$80,$F0,$81
	.db $F8,$BC,$80,$80,$E2,$88,$80,$9E
	.db $E0,$E3,$83,$BC,$BC,$80,$C0,$87
	.db $80,$80,$F0,$81,$F8,$BC,$80,$80
	.db $E2,$88,$80,$9E,$E0,$E3,$83,$BC
	.db $BC,$80,$C0,$87,$80,$80,$F0,$81
	.db $F8,$BC,$80,$80,$E2,$88,$80,$9E
	.db $E0,$E3,$83,$BC,$BC,$80,$C0,$87
	.db $80,$80,$F0,$81,$F8,$BC,$80,$80
	.db $E2,$88,$80,$9E,$E0,$E3,$83,$BC
	.db $BC,$80,$C0,$87,$80,$80,$F0,$81
	.db $F8,$BC,$80,$80,$E2,$88,$80,$9E
	.db $E0,$E3,$83,$BC,$BC,$80,$C0,$87
	.db $80,$80,$F0,$81,$F8,$BC,$80,$80
	.db $E2,$88,$80,$9E,$E0,$E3,$83,$BC
	.db $BC,$80,$CC,$87,$C0,$81,$E0,$83
	.db $BC,$BC,$80,$80,$E2,$88,$80,$9E
	.db $E0,$E3,$83,$BC,$BC,$80,$CE,$87
	.db $E0,$81,$C0,$87,$9E,$BC,$80,$80
	.db $E2,$88,$80,$BF,$F0,$F7,$87,$FE
	.db $FE,$FF,$EF,$FF,$FF,$81,$80,$FE
	.db $87,$FE,$80,$80,$E2,$88,$80,$80
	.fill 16, $80
	.db $E2,$88,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$E2,$88,$80,$80
	.fill 16, $80
	.db $E2,$88,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$E2,$A8,$D5,$AA
	.db $D5,$98,$F3,$99,$EC,$8F,$D5,$AA
	.db $D5,$AA,$D5,$AA,$D5,$AA,$D5,$AA
	.db $E2,$80,$80,$80,$80,$B8,$9B,$BB
	.db $EE,$80,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$E2,$FF,$FF,$FF
	.db $FF,$F9,$FB,$FB,$EF,$C3,$FF,$FF
	.db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	.db $82,$80,$80,$80,$80,$D8,$9B,$DB
	.db $ED,$80,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$AA,$D5,$AA,$D5
	.db $AA,$99,$9B,$9B,$EC,$CF,$AA,$D5
	.db $AA,$D5,$AA,$D5,$AA,$D5,$AA,$D5
	.db $14,$34,$E0,$8F,$BF,$FC,$F9,$E7
	.db $B0,$FE,$F8,$B3,$D8,$FF,$80,$80
	.db $80,$80,$80,$80,$80,$80,$F0,$DF
	.db $FF,$FE,$FB,$EF,$B1,$FE,$FC,$B7
	.db $98,$8C,$80,$80,$80,$80,$80,$80
	.db $80,$80,$B0,$D8,$E1,$86,$B3,$EC
	.db $B3,$98,$8C,$B6,$98,$8C,$80,$80
	.db $80,$80,$80,$80,$80,$80,$B0,$C0
	.db $E1,$86,$B3,$EC,$B6,$98,$8C,$B0
	.db $98,$8C,$80,$80,$80,$80,$80,$80
	.db $80,$80,$B0,$C0,$E1,$86,$B3,$EC
	.db $BC,$98,$8C,$B0,$98,$8C,$80,$80
	.db $80,$80,$80,$80,$80,$80,$B0,$C0
	.db $E1,$86,$B3,$EC,$B8,$98,$8C,$B0
	.db $98,$8C,$80,$80,$80,$80,$80,$80
	.db $80,$80,$B2,$C0,$E1,$86,$B3,$EC
	.db $B0,$98,$8C,$B0,$98,$CC,$AA,$D5
	.db $AA,$D5,$AA,$D5,$AA,$95,$B0,$DE
	.db $E1,$86,$B3,$EC,$B0,$98,$CC,$F7
	.db $9F,$8C,$80,$80,$80,$80,$80,$80
	.db $80,$90,$B3,$DE,$E1,$86,$B3,$EC
	.db $B0,$98,$CC,$F7,$9F,$CC,$FF,$FF
	.db $FF,$FF,$FF,$FF,$FF,$91,$B0,$D8
	.db $E1,$86,$B3,$EC,$B0,$98,$8C,$B6
	.db $98,$8C,$80,$80,$80,$80,$80,$80
	.db $C0,$91,$B5,$D8,$E1,$86,$B3,$EC
	.db $B0,$98,$8C,$B6,$98,$8C,$D5,$AA
	.db $D5,$AA,$D5,$AA,$C5,$91,$B0,$D8
	.db $E1,$86,$B3,$EC,$B0,$98,$8C,$B6
	.db $98,$8C,$80,$80,$80,$80,$80,$80
	.db $C4,$91,$B0,$D8,$E1,$86,$B3,$EC
	.db $B0,$98,$8C,$B6,$98,$8C,$80,$80
	.db $80,$80,$80,$80,$C4,$91,$B0,$D8
	.db $E1,$86,$B3,$EC,$B0,$98,$8C,$B6
	.db $98,$8C,$80,$80,$80,$80,$80,$80
	.db $C4,$91,$B0,$D8,$E1,$86,$B3,$EC
	.db $B0,$98,$8C,$B6,$98,$8C,$80,$80
	.db $80,$80,$80,$80,$C4,$91,$B0,$D8
	.db $E1,$86,$B3,$EC,$B0,$98,$8C,$B6
	.db $98,$8C,$80,$80,$80,$80,$80,$80
	.db $C4,$91,$B0,$D8,$E1,$86,$B3,$EC
	.db $B0,$98,$8C,$B6,$98,$8C,$80,$80
	.db $80,$80,$80,$80,$C4,$91,$F0,$DF
	.db $FF,$FE,$FB,$EF,$B0,$FE,$FC,$B7
	.db $98,$8C,$80,$80,$80,$80,$80,$80
	.db $C4,$91,$E0,$8F,$BF,$FC,$F9,$E7
	.db $B0,$FE,$F8,$B3,$98,$8C,$80,$80
	.db $80,$80,$80,$80,$C4,$91,$80,$80
	.fill 16, $80
	.db $C4,$91,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$C4,$91,$80,$80
	.fill 16, $80
	.db $C4,$91,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$C4,$91,$80,$80
	.fill 16, $80
	.db $C4,$91,$80,$BF,$F0,$F7,$FF,$FF
	.db $FE,$FF,$80,$FC,$8F,$FC,$FF,$9F
	.db $F8,$9F,$80,$80,$C4,$91,$80,$9E
	.db $E0,$E3,$83,$F0,$BC,$E0,$83,$8F
	.db $BC,$F8,$80,$9C,$BE,$F0,$80,$80
	.db $C4,$91,$80,$9E,$E0,$E3,$83,$E0
	.db $BC,$C0,$C7,$87,$F8,$F8,$80,$98
	.db $8F,$E0,$80,$80,$C4,$91,$80,$9E
	.db $E0,$E3,$83,$80,$BC,$C0,$E7,$83
	.db $F0,$F9,$80,$C0,$87,$80,$80,$80
	.db $C4,$91,$80,$9E,$E0,$E3,$83,$80
	.db $BC,$C0,$E7,$83,$F0,$F9,$80,$C0
	.db $87,$80,$80,$80,$C4,$91,$80,$9E
	.db $E0,$E3,$83,$80,$BC,$C0,$E7,$83
	.db $F0,$F9,$80,$C0,$87,$80,$80,$80
	.db $C4,$91,$80,$9E,$E0,$E3,$83,$80
	.db $BC,$C0,$E7,$83,$F0,$F9,$80,$80
	.db $8F,$80,$80,$80,$C4,$91,$80,$9E
	.db $E0,$E3,$C3,$81,$BC,$E0,$E3,$83
	.db $F0,$F9,$B0,$80,$BE,$80,$80,$80
	.db $C4,$91,$80,$FE,$FF,$E3,$FF,$81
	.db $FC,$FF,$E0,$83,$F0,$F9,$BF,$80
	.db $F8,$BF,$80,$80,$C4,$91,$80,$9E
	.db $E0,$E3,$C3,$81,$BC,$BC,$E0,$83
	.db $F0,$F9,$B0,$80,$00,$F8,$81,$80
	.db $C4,$91,$80,$9E,$E0,$E3,$83,$80
	.db $BC,$F0,$E1,$83,$F0,$F9,$80,$80
	.db $00,$E0,$83,$80,$C4,$91,$80,$9E
	.db $E0,$E3,$83
; side A T22 ($7300-$82FF)
	.segment A_T22
	.db $80,$BC,$E0,$E3,$83,$F0,$F9,$80
	.db $80,$00,$C0,$87,$80,$C4,$91,$80
	.db $9E,$E0,$E3,$83,$80,$BC,$C0,$E3
	.db $83,$F0,$F9,$80,$80,$00,$C0,$87
	.db $80,$C4,$91,$80,$9E,$E0,$E3,$83
	.db $80,$BC,$C0,$E7,$83,$F0,$F9,$80
	.db $80,$00,$C0,$87,$80,$C4,$91,$80
	.db $9E,$E0,$E3,$83,$80,$BC,$C0,$E7
	.db $83,$F0,$F9,$80,$80,$00,$C0,$87
	.db $80,$C4,$91,$80,$9E,$E0,$E3,$83
	.db $80,$BC,$C0,$E7,$83,$F0,$F9,$80
	.db $C0,$81,$C0,$87,$80,$C4,$91,$80
	.db $9E,$E0,$E3,$83,$E0,$BC,$C0,$C7
	.db $87,$F8,$F8,$80,$D8,$83,$E0,$83
	.db $80,$C4,$91,$80,$9E,$E0,$E3,$83
	.db $F0,$BC,$C0,$87,$8F,$BC,$F8,$80
	.db $DC,$8F,$F8,$81,$80,$C4,$91,$80
	.db $BF,$F0,$F7,$FF,$FF,$FE,$E0,$8F
	.db $FC,$8F,$FC,$FF,$DF,$F9,$BF,$80
	.db $80,$C4,$91,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$80,$C4,$91,$80
	.fill 17, $80
	.db $C4,$91,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $80,$80,$80,$80,$C4,$91,$80,$80
	.fill 16, $80
	.db $C4,$91,$D5,$AA,$D5,$AA,$D5,$AA
	.db $D5,$AA,$D5,$AA,$FE,$B6,$D8,$9F
	.db $8C,$FE,$FE,$FE,$C4,$91,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $98,$F6,$DC,$81,$8C,$86,$86,$98
	.db $C0,$91,$FF,$FF,$FF,$FF,$FF,$FF
	.db $FF,$FF,$FF,$FF,$98,$F6,$DF,$87
	.db $8C,$BE,$BE,$98,$FE,$91,$80,$80
	.db $80,$80,$80,$80,$80,$80,$80,$80
	.db $98,$B6,$DB,$81,$8C,$86,$86,$98
	.db $80,$90,$AA,$D5,$AA,$D5,$AA,$D5
	.db $AA,$D5,$AA,$D5,$98,$B6,$D8,$9F
	.db $FC,$FE,$86,$98,$AA,$95
; LOAD_SECTION A = $FF: LOAD_TRACK T20 to $B000-$BFFF (the crack's: the original read it at $7465). C = 1: failed
LOAD_HOF:
	lda sys::LCBANK2                       ; <- $6322
	lda sys::LCBANK2
	lda #$FF
	ldx #$1F
	ldy #$B0
	jsr WAITING
	lda sys::LCBANK1
L7461:
	lda sys::LCBANK1                       ; <- $7470 $74A2
	rts

; the original's reader, dead since the crack: a D5 FF DD field, 4-and-4, to $B000 (SLOT16 in X)
OLD_READ_HOF:
	dec $02                                ; the crack wrote LOAD_HOF over the reader's start: its BNEs back to $7461 now land in LOAD_HOF
	beq OLD_READ_ERR
L7469:
	lda $C08C,x                            ; DRV_Q6L | <- $746C
	bpl L7469
L746E:
	cmp #$D5                               ; <- $7479
	bne L7461
L7472:
	lda $C08C,x                            ; DRV_Q6L | <- $7475
	bpl L7472
L7477:
	cmp #$FF                               ; <- $7482
	bne L746E
L747B:
	lda $C08C,x                            ; DRV_Q6L | <- $747E
	bpl L747B
	cmp #$DD
	bne L7477
L7484:
	lda $C08C,x                            ; DRV_Q6L | <- $7487 $7497
	bpl L7484
	rol a
	sta $03
L748C:
	lda $C08C,x                            ; DRV_Q6L | <- $748F
	bpl L748C
	and $03
	sta $B000,y
	iny
	bne L7484
	nop
	nop
L749B:
	lda $C08C,x                            ; DRV_Q6L | <- $749E
	bpl L749B
	cmp #$D5
	bne L7461
	clc
	.db $24                                ; BIT zp: skips the SEC (C = 0, read)
OLD_READ_ERR:
	sec                                    ; <- $7467
	lda $C088,x                            ; DRV_MOTOROFF
	rts

	.fill 85, $00
WRITE_HOF:
	jmp $B500                              ; the crack's: its writer in T20 ($B500, slot 6) | <- $632F $63A7

	.db $89,$C0                            ; what is left of the original's first instruction (LDA $C089,X?: motor on)
; the original's writer, dead since the crack: seeks T20, finds its D5 FF DD field (any, with FORMAT), writes $B100 4-and-4
OLD_WRITE_HOF:
	lda #$00
	jsr DELAY
	lda #$40
	jsr OLD_SEEK
	lda #$40
	sta $01
L7513:
	dey                                    ; <- $7529
	bne L7522
	dec $01
	bne L7522
	lda FORMAT
	bne L753D
	jmp L75AF

L7522:
	lda $C08C,x                            ; DRV_Q6L | <- $7514 $7518 $7525
	bpl L7522
L7527:
	cmp #$D5                               ; <- $7532
	bne L7513
L752B:
	lda $C08C,x                            ; DRV_Q6L | <- $752E
	bpl L752B
L7530:
	cmp #$FF                               ; <- $753B
	bne L7527
L7534:
	lda $C08C,x                            ; DRV_Q6L | <- $7537
	bpl L7534
	cmp #$DD
	bne L7530
L753D:
	ldy #$FF                               ; <- $751D
	lda $C08D,x                            ; DRV_Q6H
	lda $C08E,x                            ; DRV_Q7L
	sta $C08F,x                            ; DRV_Q7H
	ora $C08C,x                            ; DRV_Q6L
	lda #$80
	jsr DELAY
	jsr DELAY
	lda $C08D,x                            ; DRV_Q6H
	lda $C08E,x                            ; DRV_Q7L
	tya
	sta $C08F,x                            ; DRV_Q7H
	ora $C08C,x                            ; DRV_Q6L
	pha
	pla
L7562:
	cmp ($00,x)                            ; <- $7571
	cmp ($00,x)
	nop
	iny
	sta $C08D,x                            ; DRV_Q6H
	ora $C08C,x                            ; DRV_Q6L
	lda $75B3,y
	bne L7562
	tay
	nop
	nop
L7576:
	lda $B100,y                            ; <- $7596
	pha
	lsr a
	ora #$AA
	sta $C08D,x                            ; DRV_Q6H
	cmp $C08C,x                            ; DRV_Q6L
	nop
	nop
	nop
	nop
	nop
	pha
	pla
	pla
	ora #$AA
	sta $C08D,x                            ; DRV_Q6H
	cmp $C08C,x                            ; DRV_Q6L
	pha
	pla
	iny
	bne L7576
	lda #$D5
	cmp ($00,x)
	nop
	nop
	sta $C08D,x                            ; DRV_Q6H
	ora $C08C,x                            ; DRV_Q6L
	lda #$08
	jsr DELAY
	lda $C08E,x                            ; DRV_Q7L
	lda $C08C,x                            ; DRV_Q6L
L75AF:
	lda $C088,x                            ; DRV_MOTOROFF | <- $751F
	rts

	.db $FF,$3F,$CF,$F3,$FC,$FF,$3F,$CF
	.db $F3,$FC,$FF,$D5,$FF,$DD,$00
; the original's seek: A = half track, $F0 = the head's
OLD_SEEK:
	sta $26                                ; <- $750C
L75C4:
	lda $F0                                ; <- $75E9
	sta $27
	sec
	sbc $26
	beq L75F9
	bcs L75D3
	inc $F0
	bcc L75D5
L75D3:
	dec $F0                                ; <- $75CD
L75D5:
	jsr L75EE                              ; <- $75D1
	jsr L75FA
	lda $27
	and #$03
	asl a
	ora SLOT16
	tay
	lda $C080,y                            ; DRV_PH0OFF
	jsr L75FA
	beq L75C4
	jsr L75FA
L75EE:
	lda $F0                                ; <- $75D5
	and #$03
	asl a
	ora SLOT16
	tay
	lda $C081,y                            ; DRV_PH0ON
L75F9:
	rts                                    ; <- $75CB

L75FA:
	lda #$28                               ; <- $75D8 $75E6 $75EB
	jmp DELAY

; A: the ROM's WAIT
DELAY:
	sec                                    ; <- 9 refs
L7600:
	pha                                    ; <- $7608
L7601:
	sbc #$01                               ; <- $7603
	bne L7601
	pla
	sbc #$01
	bne L7600
	rts

; the developers' leftover source text, to the end of T22 (notes/srcfrag_A.txt): theirs, not in git,
; extracted from the disk by tools/extract.py
	.incbin "../../../bin/a.T22.760B-82FF.bin"
