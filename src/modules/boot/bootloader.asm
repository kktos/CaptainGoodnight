tmpPtr		=	$00
srcPtr		=	$02
dstPtr		=	$04
sizePtr		=	$06
LINE10		=	$528
		.db	1
Start:
		sei				; as the original boot: no interrupts (tiny-dos runs with aux vectors)
		stx	smartport::unit
		stx	bootUnit

	; the boot slot's block device entry: $Cn00 + ($CnFF)
		txa
		and	#$70
		lsr	a
		lsr	a
		lsr	a
		lsr	a
		ora	#$C0
		sta	tmpPtr+1
		sta	callSP+2

		lda	#$FF
		sta	tmpPtr
		lda	(tmpPtr)
		sta	tmpPtr
		sta	callSP+1

	; block 1 -> $0A00: the rest of tiny-dos (the ROM left command = read, buffer = $0800, block = 0)
		inc	smartport::bloklo
		inc	smartport::adrhi
		inc	smartport::adrhi
callSP:
		jsr	$FFFF

		jsr	sys::HOME

	; tiny-dos -> the aux language card, bank 2. From here, zero page, stack and $D000-$FFFF are aux:
	; what was in main zero page ($43, tmpPtr) is read from main memory (bootUnit, callSP)
		lda	sys::LCBANK2
		lda	sys::LCBANK2
		sta	sys::SETALTZP

		lda	bootUnit
		sta	smartport::unit

		lda	#<(.segment.start+.segment.size)
		sta	srcPtr
		lda	#>(.segment.start+.segment.size)
		sta	srcPtr+1

dosSegment	=	.segment("TINY_DOS")
		lda	#<dosSegment.start
		sta	dstPtr
		lda	#>dosSegment.start
		sta	dstPtr+1

		lda	#<dosSegment.size
		sta	sizePtr
		lda	#>dosSegment.size
		sta	sizePtr+1

		ldy	#0
RelocateLoop:
		lda	(srcPtr),y
		sta	(dstPtr),y
		inc	srcPtr
		bne	:+
		inc	srcPtr+1
:
		inc	dstPtr
		bne	:+
		inc	dstPtr+1
:
		lda	sizePtr
		bne	:+
		dec	sizePtr+1
:
		dec	sizePtr
		lda	sizePtr
		ora	sizePtr+1
		bne	RelocateLoop

		lda	callSP+1
		sta	tinyDOS::SmartPortEntry+1
		lda	callSP+2
		sta	tinyDOS::SmartPortEntry+2

		addMemRegion	regionname, dosSegment.start, dosSegment.size, $0000

	; CAPTAIN, at its aux type ($7000), then run it with the main zero page, stack and language card
		ldx	#<captainName
		ldy	#>captainName
		jsr	tinyDOS::LoadFile
		sta	sys::SETSTDZP
		jmp	.segment("INIT").start

bootUnit:	.db	0
captainName:	.pstr	"CAPTAIN"
regionname:
		.cstr	"tiny_dos"
