; Section 1 (PART1), side B T01: $6300-$72FF. Copied from out/asm/part1/part1.asm (dis.py, meta/part1.meta,
; round-trip checked), then maintained here: the meta's listing (out/part1.lst) is the original's.

RND		=	$29
SLOT16		=	$45
yhigh		=	$18EA
ylow		=	$19AA
DOTEXT		=	$1A6A
JMPDISK		=	$1D17
JMPTIME		=	$1D2B
JMPGOVER	=	$1D3B
WAIT		=	$6225
DISK_SLOT16	=	$D009
DRAWGOOD	=	$D023
CERASE		=	$D19C
INITCAPT	=	$D32E

		.org	$6300
PART1:
		jmp	START

SECTION_MARKS:
		.db	$B4,$01			; DISK_MARK ($6303) = SECTION_MARK[1], SIDE_MARK ($6304) = 1 (side B): checked by LOAD_SECTION
; section 1's start: a new stack
START:
		ldx	#$FF			; <- $6300
		txs
		sta	sys::KBDSTRB
; rehost: the original, in LC bank 2 (ROMIN2, LCBANK2 x 2), copied DISK_SLOT16 to SLOT16 ($45) for section 11's
; reboot, which now uses page 3's REBOOT; and seeded RND from the Disk II data latch (TAX / LDA DRV_Q6L,X /
; EOR $80 / STA RND), the drive still spinning after LOAD_SECTION's motor off: no Disk II, RND keeps what the
; intro's RANDOM calls left in it. Then back to bank 1 (LCBANK1 x 2), where JMPDISK left it anyway.
		.fill	$6327 - *, $EA
		lda	#$E8
		sta	$0800
		lda	#$7A
		sta	$0801
		lda	#$2A
		sta	$0802
		lda	#$7B
		sta	$0803
		jsr	$1CB2
		jsr	INITCAPT
		jsr	$7998
		jsr	$62D9
		jmp	RESTART

; variables and animation tables: shape numbers for $0807 ($21), at X $20 / Y $1F
OBJ_X:
		.db	$00			; X of the five-part thing drawn at $65F2 (what it is: not seen yet)
OBJ_Y:
		.db	$00
OBJ_STATE:
		.db	$00			; 0, 1, 2: picks how PART3 / PART4 animate ($667D, $66DA)
PART1_SHAPES:
		.db	$01,$05,$06,$07		; drawn at OBJ_X+$10, OBJ_Y+9
PART1_FRAME:
		.db	$00			; 0-3
PART4_SHAPES:
		.db	$03,$03,$03,$03,$03,$03,$03,$08	; drawn at OBJ_X+$46, OBJ_Y-$0A
		.db	$09,$09,$09,$09,$09,$08,$03,$03
		.db	$03,$03,$03,$03,$03,$08,$08,$03
		.db	$03,$03,$03,$03
PART4_FRAME:
		.db	$00			; 0-$1A; 8 in OBJ_STATE 1
PART4_SHAPES_ALT:
		.db	$09,$09,$0A,$0B,$35,$36,$36,$36	; instead of PART4_SHAPES while OBJ_TIMER is $16-$21, indexed by OBJ_TIMER-$16
		.db	$35,$0B,$0A,$09
PART3_SHAPES:
		.db	$02,$02,$02,$0C,$0D,$0E,$0F,$10	; drawn at OBJ_X+$38, OBJ_Y-9
		.db	$11
PART3_FRAME:
		.db	$00			; up to 8 (then stays), down in OBJ_STATE 2
OBJ_TIMER:
		.db	$00			; counts up and down with OBJ_STATE ($6559-$65A2); $50 and over: PART3 frame 0
PART2_SHAPES:
		.db	$12,$15,$13,$14		; drawn at OBJ_X+4, OBJ_Y-$0B
PART2_FRAME:
		.db	$00			; 0-3
VAR_638B:
		.db	$00
VAR_638C:
		.db	$00
VAR_638D:
		.db	$00			; $47 at the start
UNUSED_638E:
		.db	$00
RESTARTED:
		.db	$00			; 1: Y at T02's prompt ($7ACE), which jumps to RESTART: the opening animation is skipped ($64B0)
L6390:
		.db	$00			; FIXED_SHAPES-1: FIXED_FRAME 0 draws nothing
FIXED_SHAPES:
		.db	$37,$38,$39,$3A,$3B,$3B,$3B,$3C	; drawn at X $3F, Y $2B, indexed from 1 by FIXED_FRAME
		.db	$39,$38,$37,$3D,$3D,$3D
FIXED_FRAME:
		.db	$00			; 1-$0E
SHAPES_63A0:
		.db	$00,$1D,$1E,$1F,$20,$20,$1B,$1C	; indexed by $39, drawn through $1BC0
		.db	$21
VAR_63A9:
		.db	$00			; a count down ($6914)
; the section's (re)start: its variables to 0
RESTART:
		lda	#$00			; <- $6347
		sta	$33
		lda	RESTARTED
		bne	L63B8
		lda	#$00
		sta	$71D2
L63B8:
		lda	#$00			; <- $63B1
		sta	$624C
		sta	VAR_63A9
		sta	$684D
		sta	$0F
		sta	FIXED_FRAME
		sta	OBJ_STATE
		sta	PART1_FRAME
		sta	PART4_FRAME
		sta	PART3_FRAME
		sta	OBJ_TIMER
		sta	PART2_FRAME
		sta	VAR_638B
		sta	$39
		sta	$14
		sta	$11
		lda	#$02
		sta	$41
		lda	#$46
		sta	$12
		lda	#$47
		sta	VAR_638D
		lda	#$32
		sta	$34
		lda	#$20
		sta	$37
		lda	#$00
		sta	$0B
		lda	#$20
		sta	$0C
		ldy	#$00
		tya
L6403:
		sta	($0B),y			; <- $6406 $640E
		iny
		bne	L6403
		inc	$0C
		ldx	$0C
		cpx	#$60
		bne	L6403
		bit	sys::TEXTOFF
		bit	sys::HIRESON
		ldx	#$08
L6418:
		lda	yhigh,x			; <- $6440
		sta	$0C
		clc
		adc	#$20
		sta	$0E
		lda	ylow,x
		sta	$0B
		sta	$0D
		ldy	#$00
L642B:
		lda	#$2A			; <- $643B
		sta	($0B),y
		sta	($0D),y
		iny
		lda	#$55
		sta	($0B),y
		sta	($0D),y
		iny
		cpy	#$28
		bne	L642B
		inx
		cpx	#$16
		bne	L6418
		ldx	#$06
L6444:
		lda	ylow,x			; <- $6461
		sta	$0B
		sta	$0D
		lda	yhigh,x
		sta	$0C
		clc
		adc	#$20
		sta	$0E
		ldy	#$27
		lda	#$FF
L6459:
		sta	($0B),y			; <- $645E
		sta	($0D),y
		dey
		bpl	L6459
		dex
		bpl	L6444
		jmp	L646F

		.db	$00,$74,$00,$7B,$C9,$2A,$36,$04
		.db	$16
L646F:
		ldx	#$00			; <- $6463 $64A7
		stx	$6466
L6474:
		ldx	$6466			; <- $649D
		lda	$33
		bne	L6481
		lda	$6467,x
		jmp	L6484

L6481:
		lda	$6469,x			; <- $6479
L6484:
		sta	$20			; <- $647E
		beq	L6495
		lda	$646B,x
		sta	$1F
		lda	$646D,x
		sta	$21
		jsr	$0807
L6495:
		inc	$6466			; <- $6486
		lda	$6466
		cmp	#$02
		bne	L6474
		lda	$0F
		bne	L64AA
		lda	#$20
		sta	$0F
		jmp	L646F

L64AA:
		jsr	$60EA			; <- $64A1
		bit	sys::PAGE2OFF
		lda	RESTARTED
		beq	L64B8
		jmp	L6850

L64B8:
		lda	#$BE			; <- $64B3
		sta	OBJ_Y
		lda	#$A0
		sta	OBJ_X
L64C2:
		lda	$39			; <- 5 refs
		beq	L64C9
		jsr	CERASE
L64C9:
		jsr	L65EE			; <- $64C4
		jsr	$6000
		jsr	$61D8
		jsr	$7AA5
		jsr	$6183
		jsr	$621C
		ldx	OBJ_X
		lda	$1F00,x
		sta	$03
		bpl	L64E9
		lda	#$00
		sta	$03
L64E9:
		clc				; <- $64E3
		adc	#$1B
		sta	$02
		cmp	#$28
		bcc	L64F6
		lda	#$27
		sta	$02
L64F6:
		lda	OBJ_Y			; <- $64F0
		clc
		adc	#$0A
		cmp	#$C0
		bcc	L6502
		lda	#$BF
L6502:
		sta	$08			; <- $64FE
		sec
		sbc	#$29
		sta	$1F
L6509:
		ldy	$03			; <- $652A
		ldx	$1F
		lda	yhigh,x
		clc
		adc	$0F
		sta	$0C
		lda	ylow,x
		sta	$0B
		lda	#$00
		ldy	$03
		sta	($0B),y
		ldy	$02
		sta	($0B),y
		inc	$1F
		lda	$1F
		cmp	$08
		bne	L6509
		jsr	$621C
		lda	OBJ_STATE
		beq	L653B
		cmp	#$01
		beq	L659D
		jmp	L65C7

L653B:
		lda	OBJ_X			; <- $6532
		cmp	#$09
		beq	L6545
		inc	OBJ_X
L6545:
		lda	OBJ_X			; <- $6540
		cmp	#$09
		bcc	L6556
		lda	OBJ_Y
		cmp	#$36
		beq	L6559
		dec	OBJ_Y
L6556:
		jmp	L64C2			; <- $654A

L6559:
		lda	VAR_638B		; <- $6551
		bne	L6567
		inc	VAR_638B
		inc	OBJ_Y
		jmp	L64C2

L6567:
		lda	#$38			; <- $655C
		sta	OBJ_TIMER
		inc	OBJ_STATE
		lda	#$65
		sta	$30
		lda	#$7D
		sta	$2F
		jsr	DOTEXT
		jmp	L659D

		.db	$27,$02,$00,$0F,$13,$00,$08,$0D
		.db	$27,$06,$0E,$0E,$03,$0D,$08,$06
		.db	$07,$13,$27,$07,$00,$12,$27,$00
		.db	$11,$11,$08,$15,$04,$03,$25,$FF
L659D:
		dec	OBJ_TIMER		; <- $6536 $657A
		beq	L65C1
		lda	OBJ_TIMER
		cmp	#$30
		bcs	L65B9
		cmp	#$28
		bcs	L65B5
		cmp	#$18
		bcc	L65B9
		lda	#$90
		bne	L65BB
L65B5:
		lda	#$70			; <- $65AB
		bne	L65BB
L65B9:
		lda	#$50			; <- $65A7 $65AF
L65BB:
		jsr	WAIT			; <- $65B3 $65B7
		jmp	L64C2

L65C1:
		inc	OBJ_STATE		; <- $65A0
		jmp	L64C2

L65C7:
		lda	OBJ_Y			; <- $6538
		cmp	#$78
		beq	L65D1
		inc	OBJ_Y
L65D1:
		lda	OBJ_Y			; <- $65CC
		cmp	#$5A
		bcc	L65E5
		lda	OBJ_X
		cmp	#$8D
		beq	L65E8
		inc	OBJ_X
		inc	FIXED_FRAME
L65E5:
		jmp	L64C2			; <- $65D6

L65E8:
		jsr	$1AD2			; <- $65DD
		jmp	L6850

L65EE:
		lda	#$00			; <- $64C9
		sta	$10
		lda	OBJ_X
		sta	$20
		lda	OBJ_Y
		sta	$1F
		cmp	#$36
		bne	L6607
		lda	#$21
		sta	$7B6D
		bne	L660C
L6607:
		lda	#$22			; <- $65FE
		sta	$7B6D
L660C:
		lda	#$00			; <- $6605
		sta	$21
		jsr	$0807
		lda	OBJ_X
		clc
		adc	#$10
		sta	$20
		lda	OBJ_Y
		clc
		adc	#$09
		sta	$1F
		inc	PART1_FRAME
		lda	PART1_FRAME
		cmp	#$04
		bne	L6632
		lda	#$00
		sta	PART1_FRAME
L6632:
		tax				; <- $662B
		lda	PART1_SHAPES,x
		sta	$21
		jsr	$0807
		jsr	$621C
		jsr	$60FD
		lda	#$01
		sta	$10
		lda	OBJ_X
		clc
		adc	#$04
		sta	$20
		lda	OBJ_Y
		sec
		sbc	#$0B
		sta	$1F
		inc	PART2_FRAME
		lda	PART2_FRAME
		cmp	#$04
		bne	L6664
		lda	#$00
		sta	PART2_FRAME
L6664:
		tax				; <- $665D
		lda	PART2_SHAPES,x
		sta	$21
		jsr	$0807
		lda	OBJ_X
		clc
		adc	#$38
		sta	$20
		lda	OBJ_Y
		sec
		sbc	#$09
		sta	$1F
		lda	OBJ_STATE
		bne	L6686
		lda	#$02
		bne	L66C2
L6686:
		lda	OBJ_STATE		; <- $6680
		cmp	#$02
		bne	L669C
		dec	PART3_FRAME
		lda	PART3_FRAME
		bpl	L66BE
		lda	#$00
		sta	PART3_FRAME
		beq	L66BE
L669C:
		lda	OBJ_TIMER		; <- $668B
		cmp	#$50
		bcc	L66A7
		lda	#$00
		beq	L66BE
L66A7:
		inc	PART3_FRAME		; <- $66A1
		lda	PART3_FRAME
		cmp	#$09
		bne	L66BE
		lda	$39
		bne	L66B9
		lda	#$01
		sta	$39
L66B9:
		lda	#$08			; <- $66B3
		sta	PART3_FRAME
L66BE:
		tax				; <- $6693 $669A $66A5 $66AF
		lda	PART3_SHAPES,x
L66C2:
		sta	$21			; <- $6684
		jsr	$0807
		jsr	$621C
		lda	OBJ_X
		clc
		adc	#$46
		sta	$20
		lda	OBJ_Y
		sec
		sbc	#$0A
		sta	$1F
		lda	OBJ_STATE
		cmp	#$01
		bne	L66E8
		lda	#$08
		sta	PART4_FRAME
		beq	L66F7
L66E8:
		inc	PART4_FRAME		; <- $66DF
		lda	PART4_FRAME
		cmp	#$1B
		bne	L66F7
		lda	#$00
		sta	PART4_FRAME
L66F7:
		tax				; <- $66E6 $66F0
		lda	PART4_SHAPES,x
		sta	$21
		lda	OBJ_TIMER
		cmp	#$16
		bcc	L6711
		cmp	#$22
		bcs	L6711
		sec
		sbc	#$16
		tax
		lda	PART4_SHAPES_ALT,x
		sta	$21
L6711:
		jsr	$0807			; <- $6702 $6706
		lda	$39
		bne	L671B
		jmp	L674A

L671B:
		lda	FIXED_FRAME		; <- $6716
		beq	L6738
		cmp	#$0F
		bcs	L6738
		tax
		lda	FIXED_SHAPES-1,x
		sta	$21
		lda	#$3F
		sta	$20
		lda	#$2B
		sta	$1F
		jsr	$0807
		jmp	L674A

L6738:
		ldx	$39			; <- $671E $6722
		lda	SHAPES_63A0,x
		sta	$21
		jsr	$1BC0
		lda	$39
		cmp	#$08
		beq	L674A
		inc	$39
L674A:
		lda	#$00			; <- 6 refs
		sta	$10
		inc	$14
		ldy	$14
		ldx	#$5F
L6754:
		lda	($11),y			; <- $6760
		bmi	L675B
		nop
		bpl	L675E
L675B:
		jsr	$621C			; <- $6756
L675E:
		iny				; <- $6759
		dex
		bpl	L6754
		rts

		.db	$40,$01,$C0,$0D,$98,$01,$7B,$00
		.db	$E0,$A0,$A0,$E0,$70,$F0,$24,$00
		.db	$01,$02,$05,$0D,$0D,$0E,$0E,$02
		.db	$04,$1B,$2A,$2B,$22,$27,$28,$29
		.db	$2B,$2A,$22,$1D,$1D,$1D,$22,$22
		.db	$22,$1D,$50,$01,$C9,$FF,$03,$03
		.db	$03,$03,$04,$04,$04,$04,$05,$05
		.db	$00,$40,$80,$C0,$00,$40,$80,$C0
		.db	$00,$40,$05,$06,$06,$06,$06,$07
		.db	$07,$07,$07,$08,$08,$08,$08,$09
		.db	$09,$09,$09,$0A,$0A,$0A,$0A,$0B
		.db	$0B,$0B,$0B,$0C,$0C,$0C,$0C,$0D
		.db	$0D,$0D,$C0,$00,$40,$80,$C0,$00
		.db	$40,$80,$C0,$00,$40,$80,$C0,$00
		.db	$40,$80,$C0,$00,$40,$80,$C0,$00
		.db	$40,$80,$C0,$00,$40,$80,$C0,$00
		.db	$40,$80,$00,$00,$00,$00,$00,$00
		.db	$00,$17,$2C,$2D,$2E,$2F,$30,$31
		.db	$00,$2C,$2C,$2C,$2F,$2F,$2F,$32
		.db	$32,$32,$34,$34,$38,$38,$38,$31
		.db	$31,$31,$31,$31,$31,$31,$00,$21
		.db	$21,$21,$22,$22,$22,$23,$23,$23
		.db	$22,$22,$34,$34,$34,$33,$33,$33
		.db	$33,$33,$33,$33,$00,$00,$00,$00
		.fill	16, $00
		.db	$01,$02,$03,$04,$00,$00,$00,$00
		.db	$00,$00,$7E,$7D,$7A,$75,$6A,$55
		.db	$2A,$2B,$57,$2F,$5F,$3F,$7F,$7F
		.db	$00,$00,$00,$00,$00
L6850:
		lda	$33			; <- $64B5 $65EB
		beq	L6858
		lda	#$00
		beq	L685A
L6858:
		lda	#$07			; <- $6852
L685A:
		sta	$35			; <- $6856
		lda	RESTARTED
		beq	L686C
		lda	#$20
		sta	$37
		lda	#$01
		sta	$39
		jsr	$1BC0
L686C:
		jsr	JMPTIME			; <- $685F
		lda	#$00
		sta	$684F
		sta	$6838
		sta	$67EA
		sta	$684C
		sta	$684B
		sta	$36
		sta	$6837
		sta	$67E5
		sta	$67E6
		sta	$67E7
		sta	$67E8
		sta	$67E9
		sta	$67EB
		sta	VAR_638C
		sta	$683C
		lda	#$96
		sta	$6767
		lda	#$01
		sta	$6768
		sta	$39
		lda	RESTARTED
		bne	L68B6
		lda	#$68
		sta	$30
		lda	#$C5
		sta	$2F
L68B6:
		lda	#$00			; <- $68AC
		sta	$683B
		lda	$33
		bne	L68E7
		jsr	DOTEXT
		jmp	L68E7

		.db	$27,$13,$07,$04,$27,$01,$00,$12
		.db	$04,$27,$02,$0E,$0C,$0C,$00,$0D
		.db	$03,$04,$11,$27,$08,$12,$27,$16
		.db	$00,$08,$13,$08,$0D,$06,$24,$24
		.db	$24,$FF
L68E7:
		inc	$684E			; <- 7 refs
		lda	$684E
		and	#$1F
		bne	L68FE
		lda	#$00
		sta	$1CDD
		lda	#$01
		sta	$1CDE
		jsr	$1CDF
L68FE:
		jsr	L71BA			; <- $68EF
		lda	$684D
		beq	L6914
		cmp	#$01
		beq	L690F
		dec	$684D
		bne	L6914
L690F:
		lda	#$00			; <- $6908
		jmp	JMPGOVER

L6914:
		lda	VAR_63A9		; <- $6904 $690D
		beq	L6921
		dec	VAR_63A9
		bne	L6921
		jsr	$1AD2
L6921:
		lda	$684B			; <- $6917 $691C
		beq	L6929
		jsr	L674A
L6929:
		lda	$683C			; <- $6924
		beq	L6940
		inc	$683C
		lda	$683C
		cmp	#$40
		bne	L6940
		jsr	$1AD2
		lda	#$00
		sta	$683C
L6940:
		jsr	$6183			; <- $692C $6936
		lda	$683B
		cmp	#$40
		beq	L695B
		cmp	#$3F
		bne	L6958
		jsr	$1AD2
		lda	#$40
		sta	$683B
		bne	L695B
L6958:
		inc	$683B			; <- $694C
L695B:
		lda	$67E6			; <- $6948 $6956
		cmp	#$17
		bne	L6982
		lda	$6838
		bne	L6974
		lda	#$01
		sta	$67EA
		lda	$684F
		bne	L6974
		jsr	$7A7F
L6974:
		lda	VAR_638C		; <- $6965 $696F
		cmp	#$8B
		bcc	L6982
		cmp	#$8F
		bcs	L6982
		jmp	L70DE

L6982:
		jsr	$61D8			; <- $6960 $6979 $697D
		jsr	L71BA
		lda	$67E6
		beq	L69D9
		cmp	#$15
		bne	L69C6
		lda	#$69
		sta	$30
		lda	#$A2
		sta	$2F
		jsr	DOTEXT
		inc	$683C
		jmp	L69C6

		.db	$27,$02,$0B,$04,$00,$11,$04,$03
		.db	$27,$05,$0E,$11,$27,$13,$00,$0A
		.db	$04,$0E,$05,$05,$27,$0E,$0D,$27
		.db	$11,$14,$0D,$16,$00,$18,$27,$1A
		.db	$1B,$23,$24,$FF
L69C6:
		cmp	#$17			; <- $698F $699F
		beq	L69F1
		inc	$67E6
		ldx	$67E6
		lda	$681F,x
		sta	$67E5
		jmp	L69F1

L69D9:
		lda	sys::BUTN1		; <- $698B
		bpl	L69F1
		lda	$35
		cmp	#$97
		bcc	L69F1
		cmp	#$99
		bcs	L69F1
		lda	$36
		cmp	#$01
		bne	L69F1
		inc	$67E6
L69F1:
		lda	$67E6			; <- 6 refs
		cmp	#$17
		bne	L6A5A
		lda	$0F
		beq	L6A2C
		lda	#$00
		ldx	#$27
L6A00:
		sta	$46D0,x			; <- $6A28
		sta	$42D0,x
		sta	$5E50,x
		sta	$5A50,x
		sta	$5650,x
		sta	$5250,x
		sta	$4E50,x
		sta	$4A50,x
		sta	$4650,x
		sta	$4250,x
		sta	$5DD0,x
		sta	$59D0,x
		sta	$55D0,x
		dex
		bpl	L6A00
		bmi	L6A5A
L6A2C:
		lda	#$00			; <- $69FA
		ldx	#$27
L6A30:
		sta	$26D0,x			; <- $6A58
		sta	$22D0,x
		sta	$3E50,x
		sta	$3A50,x
		sta	$3650,x
		sta	$3250,x
		sta	$2E50,x
		sta	$2A50,x
		sta	$2650,x
		sta	$2250,x
		sta	$3DD0,x
		sta	$39D0,x
		sta	$35D0,x
		dex
		bpl	L6A30
L6A5A:
		lda	#$00			; <- $69F6 $6A2A
		sta	$10
		jsr	CERASE
		jsr	L71BA
		lda	$684B
		beq	L6A6C
		jsr	L674A
L6A6C:
		lda	VAR_638C		; <- $6A67
		sec
		sbc	#$0D
		sta	$20
		lda	VAR_638D
		sta	$1F
		lda	#$24
		sta	$21
		jsr	$0807
		lda	$6767
		sta	$22
		lda	$6768
		sta	$23
		jsr	$606D
		lda	$26
		beq	L6A98
		cmp	#$FF
		beq	L6AA9
		jmp	L6B17

L6A98:
		lda	$27			; <- $6A8F
		cmp	#$8D
		bcc	L6AA1
		jmp	L6B17

L6AA1:
		sta	$20			; <- $6A9C
		sta	VAR_638C
		jmp	L6AB7

L6AA9:
		lda	$27			; <- $6A93
		cmp	#$8B
		bcs	L6AB2
		jmp	L6B17

L6AB2:
		sta	$20			; <- $6AAD
		sta	VAR_638C
L6AB7:
		lda	VAR_638D		; <- $6AA6
		sta	$1F
		lda	#$23
		sta	$21
		jsr	$0807
		lda	VAR_638D
		sec
		sbc	#$12
		sta	$1F
		lda	#$19
		sta	$21
		jsr	$0807
		lda	VAR_638D
		sec
		sbc	#$1F
		sta	$1F
		ldx	$67E9
		lda	$67EC,x
		sta	$21
		jsr	$0807
		lda	#$01
		sta	$10
		lda	VAR_638D
		sec
		sbc	#$13
		sta	$1F
		lda	$20
		clc
		adc	#$3B
		sta	$20
		lda	$67E5
		beq	L6B09
		cmp	#$04
		beq	L6B13
		lda	#$1E
		clc
		adc	$67E5
		bne	L6B0B
L6B09:
		lda	#$1E			; <- $6AFB
L6B0B:
		sta	$21			; <- $6B07 $6B15
		jsr	$0807
		jmp	L6B36

L6B13:
		lda	#$26			; <- $6AFF
		bne	L6B0B
L6B17:
		lda	$33			; <- $6A95 $6A9E $6AAF
		beq	L6B23
		lda	#$20
		jsr	WAIT
		jmp	L6B36

L6B23:
		lda	$36			; <- $6B19
		cmp	#$FF
		bne	L6B31
		lda	#$20
		jsr	WAIT
		jmp	L6B36

L6B31:
		lda	#$80			; <- $6B27
		jsr	WAIT
L6B36:
		jsr	L71BA			; <- $6B10 $6B20 $6B2E
		lda	$67E6
		cmp	#$17
		beq	L6B44
		lda	#$00
		sta	$10
L6B44:
		ldx	#$08			; <- $6B3E
		stx	$28
L6B48:
		ldx	$28			; <- $6B81
		lda	$6769,x
		sta	$22
		lda	$6772,x
		sta	$23
		jsr	$606D
		lda	$26
		beq	L6B6A
		cmp	#$FF
		bne	L6B7F
		lda	$27
		cmp	#$D0
		bcc	L6B7F
		sta	$20
		jmp	L6B72

L6B6A:
		lda	$27			; <- $6B59
		cmp	#$8D
		bcs	L6B7F
		sta	$20
L6B72:
		lda	$6784,x			; <- $6B67
		sta	$1F
		lda	$677B,x
		sta	$21
		jsr	$0807
L6B7F:
		dec	$28			; <- $6B5D $6B63 $6B6E
		bpl	L6B48
		lda	$678F
		sta	$22
		lda	$6790
		sta	$23
		jsr	$606D
		lda	$26
		beq	L6BA3
		cmp	#$FF
		bne	L6BB6
		lda	$27
		cmp	#$B0
		bcc	L6BB6
		sta	$20
		jmp	L6BAB

L6BA3:
		lda	$27			; <- $6B92
		cmp	#$8D
		bcs	L6BB6
		sta	$20
L6BAB:
		lda	#$36			; <- $6BA0
		sta	$1F
		lda	#$16
		sta	$21
		jsr	$0807
L6BB6:
		lda	$678D			; <- $6B96 $6B9C $6BA7
		sta	$22
		lda	$678E
		sta	$23
		jsr	$606D
		lda	$26
		beq	L6BCD
		cmp	#$FF
		bne	L6BEB
		beq	L6BD8
L6BCD:
		lda	$27			; <- $6BC5
		cmp	#$8D
		bcs	L6BEB
		sta	$20
		jmp	L6BE0

L6BD8:
		lda	$27			; <- $6BCB
		cmp	#$B0
		bcc	L6BEB
		sta	$20
L6BE0:
		lda	#$3B			; <- $6BD5
		sta	$1F
		lda	#$1A
		sta	$21
		jsr	$0807
L6BEB:
		jsr	L71BA			; <- $6BC9 $6BD1 $6BDC
		lda	#$D0
		sta	$0B
		sta	$0D
		lda	#$2A
		clc
		adc	$0F
		sta	$0C
		lda	#$2E
		clc
		adc	$0F
		sta	$0E
		lda	$6763
		sta	$22
		lda	$6764
		sta	$23
		jsr	$606D
		lda	$26
		beq	L6C19
		cmp	#$FF
		beq	L6C5E
		bne	L6C76
L6C19:
		lda	$27			; <- $6C11
		cmp	#$8C
		bcs	L6C70
		tax
		lda	$1F00,x
		tay
		lda	$17EA,x
		tax
		lda	$683D,x
		sta	($0B),y
		sta	($0D),y
		iny
		cpy	#$28
		bcs	L6C46
		lda	#$7F
		sta	($0B),y
		sta	($0D),y
		iny
		cpy	#$28
		bcs	L6C45
		lda	#$7F
		sta	($0B),y
		sta	($0D),y
L6C45:
		dey				; <- $6C3D
L6C46:
		dey				; <- $6C32
		dey
		bmi	L6C76
		tya
		ror	a
		bcc	L6C56
		lda	#$55
		sta	($0B),y
		sta	($0D),y
		bne	L6C76
L6C56:
		lda	#$2A			; <- $6C4C
		sta	($0B),y
		sta	($0D),y
		bne	L6C76
L6C5E:
		ldx	#$00			; <- $6C15
		lda	#$7F
L6C62:
		sta	$2ED0,x			; <- $6C74
		sta	$2AD0,x
		sta	$4ED0,x
		sta	$4AD0,x
		bne	L6C76
L6C70:
		ldx	#$27			; <- $6C1D
		lda	#$55
		bne	L6C62
L6C76:
		lda	$6765			; <- 5 refs
		sta	$22
		lda	$6766
		sta	$23
		jsr	$606D
		lda	$26
		beq	L6C8D
		cmp	#$FF
		beq	L6CD9
		bne	L6CF4
L6C8D:
		lda	$27			; <- $6C85
		cmp	#$8C
		bcc	L6CA6
		ldx	#$27
		lda	#$7F
		sta	$2ED0,x
		sta	$4ED0,x
		sta	$2AD0,x
		sta	$4AD0,x
		jmp	L6CF4

L6CA6:
		tax				; <- $6C91
		lda	$1F00,x
		tay
		lda	$17EA,x
		tax
		lda	$6844,x
		sta	($0B),y
		sta	($0D),y
		dey
		bmi	L6CBF
		lda	#$7F
		sta	($0B),y
		sta	($0D),y
L6CBF:
		iny				; <- $6CB7
L6CC0:
		iny				; <- $6CCF $6CD7
		cpy	#$28
		bcs	L6CF4
		tya
		ror	a
		bcc	L6CD1
		lda	#$55
		sta	($0B),y
		sta	($0D),y
		bne	L6CC0
L6CD1:
		lda	#$2A			; <- $6CC7
		sta	($0B),y
		sta	($0D),y
		bne	L6CC0
L6CD9:
		ldx	#$0E			; <- $6C89
L6CDB:
		txa				; <- $6CF2
		ror	a
		bcc	L6CE3
		lda	#$55
		bne	L6CE5
L6CE3:
		lda	#$2A			; <- $6CDD
L6CE5:
		sta	$2ED0,x			; <- $6CE1
		sta	$2AD0,x
		sta	$4ED0,x
		sta	$4AD0,x
		dex
		bpl	L6CDB
L6CF4:
		jsr	L71BA			; <- $6C8B $6CA3 $6CC3
		lda	$36
		beq	L6D00
		bmi	L6D00
		jmp	L6D03

L6D00:
		jmp	L6D89			; <- $6CF9 $6CFB

L6D03:
		lda	#$0A			; <- $6CFD
		sta	$28
L6D07:
		ldx	$28			; <- $6D3E
		lda	$679B,x
		sta	$22
		lda	$6791,x
		sta	$23
		jsr	$606D
		lda	$26
		beq	L6D29
		cmp	#$FF
		bne	L6D3C
		lda	$27
		cmp	#$F0
		bcc	L6D3C
		sta	$20
		jmp	L6D31

L6D29:
		lda	$27			; <- $6D18
		cmp	#$8D
		bcs	L6D3C
		sta	$20
L6D31:
		lda	#$1D			; <- $6D26
		sta	$1F
		lda	#$1C
		sta	$21
		jsr	$0807
L6D3C:
		dec	$28			; <- $6D1C $6D22 $6D2D
		bpl	L6D07
		lda	#$1F
		sta	$28
L6D44:
		ldx	$28			; <- $6D7B
		lda	$67C5,x
		sta	$22
		lda	$67A5,x
		sta	$23
		jsr	$606D
		lda	$26
		beq	L6D66
		cmp	#$FF
		bne	L6D79
		lda	$27
		cmp	#$F0
		bcc	L6D79
		sta	$20
		jmp	L6D6E

L6D66:
		lda	$27			; <- $6D55
		cmp	#$8D
		bcs	L6D79
		sta	$20
L6D6E:
		lda	#$1D			; <- $6D63
		sta	$1F
		lda	#$1D
		sta	$21
		jsr	$0807
L6D79:
		dec	$28			; <- $6D59 $6D5F $6D6A
		bpl	L6D44
		jmp	L6D89

		.db	$00,$3F,$3F,$40,$40,$41,$41,$FF
		.db	$FF
L6D89:
		jsr	$6018			; <- $6D00 $6D7D
		lda	$67E6
		beq	L6D94
		jmp	L6E22

L6D94:
		lda	$36			; <- $6D8F
		cmp	#$0F
		bne	L6DB4
		lda	$35
		cmp	#$80
		bcc	L6DB4
		lda	#$40
		sta	$35
		lda	#$08
		sta	$37
		lda	#$00
		sta	$38
		lda	#$01
		sta	$684B
		jsr	L710B
L6DB4:
		lda	$684B			; <- $6D98 $6D9E
		beq	L6E1C
		cmp	#$09
		bne	L6DDA
		lda	#$00
		sta	$684B
		lda	$684C
		cmp	#$03
		beq	L6DD7
		sta	$1CDE
		lda	#$01
		sta	$1CDD
		jsr	$1CDF
		jsr	JMPTIME
L6DD7:
		jmp	L6E1C			; <- $6DC7

L6DDA:
		tax				; <- $6DBB
		lda	$6D80,x
		sta	$21
		bpl	L6E07
		ldx	#$1F
L6DE4:
		lda	ylow,x			; <- $6DFF
		sta	$0B
		lda	yhigh,x
		clc
		adc	$0F
		sta	$0C
		lda	#$80
		ldy	#$0F
L6DF5:
		sta	($0B),y			; <- $6DFA
		iny
		cpy	#$18
		bne	L6DF5
		dex
		cpx	#$15
		bne	L6DE4
		inc	$684B
		jmp	L6E1C

L6E07:
		lda	#$1F			; <- $6DE0
		sta	$1F
		lda	#$3C
		sta	$20
		lda	#$00
		sta	$10
		jsr	$0807
		inc	$684B
		jsr	L674A
L6E1C:
		jsr	DRAWGOOD		; <- $6DB7 $6DD7 $6E04
		jmp	L6E69

L6E22:
		cmp	#$16			; <- $6D91
		bcs	L6E69
		ldx	$67E6
		lda	$67F3,x
		sta	$1F
		lda	$6809,x
		sta	$21
		cmp	#$33
		bcs	L6E45
		lda	#$01
		sta	$1E
		jsr	$1BC0
		lda	#$00
		sta	$1E
		jmp	L6E69

L6E45:
		lda	#$41			; <- $6E35
		sta	$20
		lda	#$01
		sta	$10
		jsr	$0807
		lda	#$00
		sta	$10
		lda	$21
		cmp	#$33
		bne	L6E69
		lda	#$41
		sta	$20
		lda	#$3B
		sta	$1F
		lda	#$24
		sta	$21
		jsr	$0807
L6E69:
		jsr	$60FD			; <- $6E1F $6E24 $6E42 $6E58
		jsr	L71BA
		jsr	$6000
		lda	$67E6
		cmp	#$17
		bne	L6E7C
		jmp	L6F1A

L6E7C:
		lda	$67E6			; <- $6E77
		beq	L6E84
		jmp	L68E7

L6E84:
		lda	$3C			; <- $6E7F
		beq	L6E8B
		jmp	L68E7

L6E8B:
		lda	$6015			; <- $6E86
		sta	RND
		cmp	#$5F
		bcs	L6EB9
		cmp	#$4B
		bcc	L6EA2
		lda	$3D
		bne	L6EA2
		lda	#$00
		sta	$3A
		beq	L6F08
L6EA2:
		lda	#$01			; <- $6E96 $6E9A
		sta	$3A
		inc	$35
		bne	L6EAC
		inc	$36
L6EAC:
		lda	$3B			; <- $6EA8
		beq	L6F08
		inc	$35
		bne	L6F08
		inc	$36
		jmp	L68E7

L6EB9:
		lda	#$FF			; <- $6E92
		sta	$3A
		lda	$36
		cmp	#$FF
		bne	L6ED0
		lda	$35
		cmp	#$C8
		bcs	L6ED0
		lda	#$C8
		sta	$35
		jmp	L6F08

L6ED0:
		dec	$35			; <- $6EC1 $6EC7
		lda	$35
		cmp	#$FF
		bne	L6EDA
		dec	$36
L6EDA:
		lda	$36			; <- $6ED6
		cmp	#$FF
		bne	L6EEA
		lda	$35
		cmp	#$C8
		bcs	L6EEA
		lda	#$C8
		sta	$35
L6EEA:
		lda	$3B			; <- $6EDE $6EE4
		beq	L6F08
		dec	$35
		lda	$35
		cmp	#$FF
		bne	L6EF8
		dec	$36
L6EF8:
		lda	$36			; <- $6EF4
		cmp	#$FF
		bne	L6F08
		lda	$35
		cmp	#$C8
		bcs	L6F08
		lda	#$C8
		sta	$35
L6F08:
		lda	$36			; <- 7 refs
		cmp	#$FF
		bne	L6F17
		lda	$35
		cmp	#$C8
		bne	L6F17
		jsr	L71D3
L6F17:
		jmp	L68E7			; <- $6F0C $6F12

L6F1A:
		inc	$683A			; <- $6E79
		jsr	L71BA
		lda	$6838
		bne	L6F5F
		lda	$6837
		bne	L6F5F
		lda	$67E9
		bne	L6F5F
		lda	$36
		cmp	#$0D
		bcc	L6F5F
		lda	#$01
		sta	$6838
		lda	#$00
		sta	$6837
		sta	$67EA
		lda	$70C1
		bne	L6F5F
		lda	#$A5
		sta	$2F
		lda	#$70
		sta	$30
		jsr	$1AD2
		jsr	DOTEXT
		lda	#$01
		sta	$70C1
		lda	#$FF
		sta	VAR_63A9
L6F5F:
		lda	$67E9			; <- 5 refs
		bne	L6F6B
		lda	VAR_638D
		cmp	#$4B
		bcc	L6F81
L6F6B:
		lda	$67E9			; <- $6F62
		cmp	#$06
		beq	L6F81
		inc	$67E9
		lda	$67E9
		cmp	#$06
		bne	L6F81
		lda	#$01
		sta	$6837
L6F81:
		lda	$36			; <- $6F69 $6F70 $6F7A
		cmp	#$03
		bne	L6F90
		lda	$35
		cmp	#$0A
		bcs	L6F90
		jsr	$1AD2
L6F90:
		lda	$36			; <- $6F85 $6F8B
		cmp	#$05
		bcs	L6FA2
		lda	$67E7
		cmp	#$0A
		bcc	L6FA2
		lda	#$09
		sta	$67E7
L6FA2:
		lda	$6837			; <- $6F94 $6F9B
		bne	L6FCC
		lda	$6838
		bne	L6FBA
		lda	$6015
		cmp	#$46
		bcc	L6FCC
		cmp	#$5A
		bcs	L6FBA
		jmp	L6FD6

L6FBA:
		lda	$67E7			; <- $6FAA $6FB5
		beq	L6FD6
		dec	$67E7
		lda	$67E7
		cmp	#$13
		bcc	L701C
		jmp	L6FD6

L6FCC:
		lda	$67E7			; <- $6FA5 $6FB1
		cmp	#$19
		beq	L6FD6
		inc	$67E7
L6FD6:
		lda	$6837			; <- $6FB7 $6FBD $6FC9 $6FD1
		bne	L700D
		lda	$6838
		bne	L701C
		lda	$6014
		cmp	#$46
		bcc	L701C
		cmp	#$5A
		bcs	L6FEE
		jmp	L702C

L6FEE:
		lda	$67E7			; <- $6FE9
		cmp	#$13
		bcc	L702C
		lda	$36
		cmp	#$08
		bcc	L702C
		lda	$67E9
		cmp	#$06
		beq	L700D
		lda	$683A
		ror	a
		bcc	L702C
		inc	VAR_638D
		bne	L702C
L700D:
		inc	VAR_638D		; <- $6FD9 $7000
		bne	L702C
		lda	#$01
		sta	$6837
		lda	#$00
		sta	$6838
L701C:
		lda	VAR_638D		; <- $6FC7 $6FDE $6FE5
		cmp	#$47
		beq	L702C
		lda	$683A
		ror	a
		bcc	L702C
		dec	VAR_638D
L702C:
		lda	VAR_638D		; <- 8 refs
		cmp	#$9C
		bne	L7036
		dec	VAR_638D
L7036:
		lda	$6767			; <- $7031
		clc
		adc	$67E7
		sta	$6767
		lda	#$00
		adc	$6768
		sta	$6768
		lda	$35
		clc
		adc	$67E7
		sta	$35
		lda	#$00
		adc	$36
		sta	$36
		lda	$67E7
		cmp	#$19
		bne	L707A
		lda	$67E9
		cmp	#$06
		bne	L707A
		lda	$6767
		clc
		adc	#$02
		sta	$6767
		lda	#$00
		adc	$6768
		sta	$6768
		lda	#$01
		sta	$67E8
L707A:
		lda	$6838			; <- $705B $7062
		beq	L70A2
		lda	$6839
		bne	L70A2
		lda	$67E7
		bne	L70A2
		lda	#$C2
		sta	$2F
		lda	#$70
		sta	$30
		jsr	$1AD2
		jsr	DOTEXT
		inc	$6839
		lda	#$3C
		sta	VAR_63A9
		sta	$684D
L70A2:
		jmp	L68E7			; <- $707D $7082 $7087

		.db	$27,$04,$0C,$04,$11,$06,$04,$0D
		.db	$02,$18,$27,$04,$0D,$06,$08,$0D
		.db	$04,$27,$12,$07,$14,$13,$03,$0E
		.db	$16,$0D,$25,$FF,$00,$27,$13,$11
		.db	$18,$27,$13,$00,$0A,$08,$0D,$06
		.db	$27,$0E,$05,$05,$17,$27,$06,$0E
		.db	$0E,$03,$0D,$08,$06,$07,$13,$25
		.db	$FF
L70DE:
		lda	#$70			; <- $697F
		sta	$30
		lda	#$F5
		sta	$2F
		jsr	$1AD2
		jsr	DOTEXT
		lda	#$BB
		sta	$90
		lda	#$02
		jmp	JMPDISK

		.db	$27,$06,$0E,$0E,$03,$27,$0B,$14
		.db	$02,$0A,$27,$02,$00,$0F,$13,$00
		.db	$08,$0D,$24,$24,$24,$FF
L710B:
		ldx	$684C			; <- $6DB1
		lda	$7133,x
		sta	$2F
		lda	$7137,x
		sta	$30
		jsr	$1AD2
		jsr	DOTEXT
		lda	#$32
		sta	VAR_63A9
		inc	$684C
		lda	$684C
		cmp	#$04
		bne	L7132
		lda	#$46
		sta	$684D
L7132:
		rts				; <- $712B

		.db	$3B,$59,$6A,$92,$71,$71,$71,$71
		.db	$27,$03,$08,$03,$0D,$26,$13,$27
		.db	$18,$0E,$14,$27,$11,$04,$00,$03
		.db	$27,$13,$07,$04,$27,$12,$08,$06
		.db	$0D,$12,$24,$24,$24,$FF,$27,$07
		.db	$00,$15,$08,$0D,$06,$27,$05,$14
		.db	$0D,$27,$18,$04,$13,$19,$FF,$27
		.db	$16,$04,$27,$03,$0E,$0D,$26,$13
		.db	$27,$00,$0F,$0F,$04,$00,$11,$27
		.db	$13,$0E,$27,$01,$04,$27,$0C,$00
		.db	$0A,$08,$0D,$06,$27,$0F,$11,$0E
		.db	$06,$11,$04,$12,$12,$25,$FF,$27
		.db	$0C,$08,$12,$12,$08,$0E,$0D,$27
		.db	$00,$01,$0E,$11,$13,$04,$03,$25
		.db	$27,$27,$0C,$00,$18,$01,$04,$27
		.db	$1A,$1A,$21,$27,$08,$12,$27,$05
		.db	$11,$04,$04,$24,$24,$24,$FF
L71BA:
		lda	$67EA			; <- 8 refs
		beq	L71C7
		lda	$6837
		beq	L71C8
		jsr	$621C
L71C7:
		rts				; <- $71BD $71CC

L71C8:
		lda	$683A			; <- $71C2
		ror	a
		bcc	L71C7
		jsr	$621C
		rts

		.db	$00
L71D3:
		lda	#$00			; <- $6F14
		sta	$0B
		lda	#$04
		sta	$0C
		ldy	#$00
L71DD:
		lda	#$A0			; <- $71EA
L71DF:
		sta	($0B),y			; <- $71E2
		iny
		bne	L71DF
		inc	$0C
		lda	$0C
		cmp	#$08
		bne	L71DD
		lda	#$01
		sta	$624C
		bit	sys::TEXTON
		bit	sys::PAGE2OFF
		jmp	L71FD

		.db	$00,$00,$00
L71FD:
		lda	$71D2			; <- $71F7
		beq	L7224
		cmp	#$02
		bcs	L7215
		lda	#$70
		sta	$0D
		lda	#$78
		sta	$0E
		lda	#$00
		sta	$71FC
		beq	L7231
L7215:
		lda	#$CB			; <- $7204
		sta	$0D
		lda	#$78
		sta	$0E
		lda	#$00
		sta	$71FC
		beq	L7231
L7224:
		lda	#$3E			; <- $7200
		sta	$0D
		lda	#$73
		sta	$0E
		lda	#$00
		sta	$71FC
L7231:
		ldy	#$00			; <- $7213 $7222 $7279
		lda	($0D),y
		cmp	#$FF
		beq	L727C
		cmp	#$AB
		bne	L7267
		jsr	L72E7
		lda	#$00
		sta	$71FC
		lda	sys::BUTN0
		bmi	L7273
		ldx	#$14
L724C:
		jsr	$621C			; <- $725D
		lda	#$0C
		jsr	WAIT
		jsr	$621C
		lda	#$08
		jsr	WAIT
		dex
		bpl	L724C
		lda	#$00
		jsr	WAIT
		jmp	L7273

L7267:
		cmp	#$AA			; <- $723B
		bne	L726D
		lda	#$20
L726D:
		jsr	L728F			; <- $7269
		inc	$71FC
L7273:
		inc	$0D			; <- $7248 $7264
		bne	L7279
		inc	$0E
L7279:
		jmp	L7231			; <- $7275

L727C:
		lda	$71D2			; <- $7237
		cmp	#$02
		bcc	L7286
		jmp	$7A51

L7286:
		jsr	$7A43			; <- $7281
		inc	$71D2
		jmp	L72B8

L728F:
		ldx	$71FC			; <- $726D
		sta	$07D0,x
		jsr	$621C
		lda	sys::BUTN0
		bmi	L72A2
		lda	#$90
		jsr	WAIT
L72A2:
		lda	sys::KBD		; <- $729B
		cmp	#$D4
		beq	L72B4
		cmp	#$F4
		beq	L72B4
		cmp	#$92
		beq	L72B4
		jsr	$61D8
L72B4:
		sta	sys::KBDSTRB		; <- $72A7 $72AB $72AF
		rts

L72B8:
		lda	sys::BUTN1		; <- $728C $72BB
		bpl	L72B8
		lda	$0F
		beq	L72C7
		bit	sys::PAGE2OFF
		jmp	L72CA

L72C7:
		bit	sys::PAGE2ON		; <- $72BF
L72CA:
		bit	sys::TEXTOFF		; <- $72C4
		bit	sys::HIRESON
		lda	#$00
		sta	$3A
		sta	$624C
		lda	#$1C
		sta	$37
		lda	#$06
		sta	$38
		inc	$35
		jsr	$1AD2
		rts

		.db	$00,$00
L72E7:
		lda	$0D			; <- $723D
		sta	$71FA
		lda	$0E
		sta	$71FB
		lda	#$17
		sta	$72E6
		lda	#$16
		sta	$72E5
		ldx	$72E5
		.db	$BD,$7E			; LDA $7E??,X: the instruction ends in T02 ($7300)
