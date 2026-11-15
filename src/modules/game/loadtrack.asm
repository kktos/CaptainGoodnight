;
; In place of LOAD_TRACK, $D3A6-$D3C5 (main LC bank 2). Called by LOAD_SECTION ($D514: A = $FF, any track;
; $D549: a section's tracks), with LC bank 2 read/write.
;
; in:  A = track - 1, Y = first page (16 pages)
; out: the track loaded from the side of the last section asked for, SECTION_SIDE[SECTION]: the disk the
;      original would have in the drive (the intro: section 0, side A). A, X, Y changed, zero page unchanged
;      (the original swapped $00-$1F with $D400 for its RWTS; here the aux zero page is tiny-dos').
;      A track no file has: SIDE_MARK = $FF.
;
; The loading is in the aux language card (src/modules/captain/auxloader.asm): STA SETALTZP at AUX_SWITCH switches to
; it, and the next instruction is aux's AUX_SWITCH + 3. It comes back with STA SETSTDZP at aux's AUX_SWITCH, to
; AUX_SWITCH + 3 here.
;
		.if * != game::LOAD_TRACK {
			.error "LOAD_TRACK is at " + .hex(*) + ", not at " + .hex(game::LOAD_TRACK) + "."
		}
LoadTrack:
		phy
		ldy	game::SECTION
		ldx	game::SECTION_SIDE,y
		ply
		php
		sei				; with ALTZP, the interrupt vectors would be aux's

		.if * != AUX_SWITCH {
			.error "LoadTrack's switch to aux is at " + .hex(*) + ", not at AUX_SWITCH, " + .hex(AUX_SWITCH) + "."
		}
		sta	sys::SETALTZP
	; back from aux
		plp
		rts

		.if * > $D3C6 {
			.error "LoadTrack ends at " + .hex(*) + ": past $D3C5, it overwrites SWAP_ZP."
		}
		.fill	$D3C6 - *, $00
