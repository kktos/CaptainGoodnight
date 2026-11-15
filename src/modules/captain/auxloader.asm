;
; LOAD_TRACK's aux half, in the aux language card, bank 2 (copied there by Init). LOAD_TRACK ($D3A6, main LC
; bank 2, src/modules/game/loadtrack.asm) switches with STA SETALTZP at AUX_SWITCH: the next instruction comes from
; here, AUX_SWITCH + 3. It returns through the STA SETSTDZP at AUX_SWITCH: the next one is main's AUX_SWITCH + 3
; (PLP, RTS).
; Zero page and stack here are aux: tiny-dos uses $00-$07 and $42-$47, this $08-$09.
;
recPtr		=	$08

		.if * != AUX_SWITCH {
			.error "AUX_LOADER is at " + .hex(*) + ", not at AUX_SWITCH, " + .hex(AUX_SWITCH) + "."
		}
AuxReturn:
		sta	sys::SETSTDZP

		.if * != AUX_SWITCH + 3 {
			.error "AuxLoadTrack is at " + .hex(*) + ", not at AUX_SWITCH + 3, " + .hex(AUX_SWITCH + 3) + "."
		}
;
; A = track - 1, Y = first page, X = side (0: A, 1: B)
; loads the track's 8 blocks from its file. A track no file has: SIDE_MARK = $FF, as a read error did
; (LOAD_SECTION then asks for the disk and loads again)
;
AuxLoadTrack:
		sty	loadPage
		inc	a
		cpx	#$00
		beq	:+
		clc
		adc	#game::TRACKS
:		tax
		lda	TrackMap,x
		cmp	#$FF
		beq	noTrack

		pha
		and	#$0F			; the track's index in its file
		asl	a
		asl	a
		asl	a			; 8 blocks a track
		sta	loadBlock
		pla
		lsr	a
		lsr	a
		lsr	a
		lsr	a			; the file
		asl	a
		tax
		lda	FileRecords,x
		sta	recPtr
		lda	FileRecords+1,x
		sta	recPtr+1

		ldy	#0
		lda	loadBlock
		sta	(recPtr),y		; first block
		iny
		lda	#TRACK_BLOCKS
		sta	(recPtr),y		; count
		iny
		lda	#$00
		sta	(recPtr),y		; address
		iny
		lda	loadPage
		sta	(recPtr),y

		ldx	recPtr
		ldy	recPtr+1
		jsr	tinyDOS::LoadFromFileAt
		jmp	AuxReturn

noTrack:
		lda	#$FF
		sta	game::SIDE_MARK		; main memory
		jmp	AuxReturn

AuxRti:
		rti

loadPage:	.db	0
loadBlock:	.db	0

;
; a track -> its file (high nibble, FileRecords' index) and its index in it (low nibble); $FF: none.
; Side A's T00-T22, then side B's. As the segments of src/segments.asm, which tools/check.py verifies.
;
TrackMap:
		.db	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; A T00-T07
		.db	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; A T08-T0F
		.db	$72					; A T10: END9
		.db	$00, $01, $02, $03, $04, $05, $06	; A T11-T17: INTRO
		.db	$07, $08, $09, $0A, $0B, $0C		; A T18-T1D: INTRO
		.db	$70, $71				; A T1E-T1F: END9
		.db	$90					; A T20: T20
		.db	$80, $81				; A T21-T22: END11

		.db	$FF					; B T00
		.db	$10, $11, $12, $13, $14			; B T01-T05: PART1
		.db	$20, $21, $22, $23, $24, $25		; B T06-T0B: PART2
		.db	$30, $31, $32, $33, $34			; B T0C-T10: PART3
		.db	$40, $41, $42, $43, $44, $45		; B T11-T16: PART4
		.db	$50, $51, $52, $53, $54, $55		; B T17-T1C: PART5
		.db	$60, $61, $62, $63, $64, $65		; B T1D-T22: PART6

		.if * - TrackMap != 2 * game::TRACKS {
			.error "TrackMap has " + .str(* - TrackMap) + " entries, not 2 x " + .str(game::TRACKS) + "."
		}

FileRecords:
		.dw	recIntro, recPart1, recPart2, recPart3, recPart4, recPart5, recPart6, recEnd9, recEnd11, recT20

; LoadFromFileAt records: first block, count and address set by AuxLoadTrack
recIntro:	.db	0, 0
		.dw	0
		.pstr	"INTRO"
recPart1:	.db	0, 0
		.dw	0
		.pstr	"PART1"
recPart2:	.db	0, 0
		.dw	0
		.pstr	"PART2"
recPart3:	.db	0, 0
		.dw	0
		.pstr	"PART3"
recPart4:	.db	0, 0
		.dw	0
		.pstr	"PART4"
recPart5:	.db	0, 0
		.dw	0
		.pstr	"PART5"
recPart6:	.db	0, 0
		.dw	0
		.pstr	"PART6"
recEnd9:	.db	0, 0
		.dw	0
		.pstr	"END9"
recEnd11:	.db	0, 0
		.dw	0
		.pstr	"END11"
recT20:		.db	0, 0
		.dw	0
		.pstr	"T20"

AuxLoaderEnd:

		.if * > tinyDOS::BUFFER {
			.error "AUX_LOADER ends at " + .hex(*) + ": past tiny-dos' buffer, at " + .hex(tinyDOS::BUFFER) + "."
		}
