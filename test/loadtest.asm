; Load test harness: see tools/loadtest.py
		.cpu	"65C02"
		.segment CODE { start: $3F00, end: $3FFF }
		.segment CODE
;
; for each case of CASES ($3C00, 12 bytes: A, X, Y, SECTION, 8 first pages of 16-page ranges, 0 ends;
; SECTION $FE ends the table): SECTION, LOAD_SECTION ($D000) with A / X / Y, then a 16-bit sum of each range
; to RESULTS ($3D80, 16 bytes a case)
;
CASES		=	$3C00
RESULTS		=	$3D80
casePtr		=	$F0
resPtr		=	$F2
ptr		=	$F4
sum		=	$F6
pages		=	$F8
rng		=	$F9

Harness:
		lda	#<CASES
		sta	casePtr
		lda	#>CASES
		sta	casePtr+1
		lda	#<RESULTS
		sta	resPtr
		lda	#>RESULTS
		sta	resPtr+1
nextCase:
		lda	$C083
		lda	$C083
		ldy	#3
		lda	(casePtr),y
		cmp	#$FE
		beq	done
		sta	$D501			; SECTION: the side LOAD_TRACK reads
		ldy	#2
		lda	(casePtr),y
		pha
		dey
		lda	(casePtr),y
		tax
		dey
		lda	(casePtr),y
		ply
		jsr	$D000			; LOAD_SECTION
		lda	#4
		sta	rng
nextRange:
		ldy	rng
		lda	(casePtr),y
		beq	caseDone
		sta	ptr+1
		stz	ptr
		stz	sum
		stz	sum+1
		lda	#16
		sta	pages
		ldy	#0
loop:		lda	(ptr),y
		clc
		adc	sum
		sta	sum
		bcc	:+
		inc	sum+1
:		iny
		bne	loop
		inc	ptr+1
		dec	pages
		bne	loop
		lda	rng
		sec
		sbc	#4
		asl	a
		tay
		lda	sum
		sta	(resPtr),y
		iny
		lda	sum+1
		sta	(resPtr),y
		inc	rng
		lda	rng
		cmp	#12
		bne	nextRange
caseDone:
		clc
		lda	casePtr
		adc	#12
		sta	casePtr
		bcc	:+
		inc	casePtr+1
:		clc
		lda	resPtr
		adc	#16
		sta	resPtr
		bcc	:+
		inc	resPtr+1
:		bra	nextCase
done:		nop
		bra	done
