;
; The tracks read at run time (tools/extract.py), a file per load. Each track is 8 blocks, at 8 * its index in
; its file: AUX_LOADER's TrackMap gives them.
;
		.MODULE	INTRO
		.segment	A_T11
		.incbin	"../../../bin/a.T11.bin"
		.segment	A_T12
		.incbin	"../../../bin/a.T12.bin"
		.segment	A_T13
		.incbin	"../../../bin/a.T13.bin"
		.segment	A_T14
		.incbin	"../../../bin/a.T14.bin"
		.segment	A_T15
		.incbin	"../../../bin/a.T15.bin"
		.segment	A_T16
		.incbin	"../../../bin/a.T16.bin"
		.segment	A_T17
		.incbin	"../../../bin/a.T17.bin"
		.segment	A_T18
		.incbin	"../../../bin/a.T18.bin"
		.segment	A_T19
		.incbin	"../../../bin/a.T19.bin"
		.segment	A_T1A
		.incbin	"../../../bin/a.T1A.bin"
		.segment	A_T1B
		.incbin	"../../../bin/a.T1B.bin"
		.segment	A_T1C
		.incbin	"../../../bin/a.T1C.bin"
		.segment	A_T1D
		.incbin	"../../../bin/a.T1D.bin"

		.MODULE	PART1
		.segment	B_T01
		.incbin	"../../../bin/b.T01.bin"
		.segment	B_T02
		.incbin	"../../../bin/b.T02.bin"
		.segment	B_T03
		.incbin	"../../../bin/b.T03.bin"
		.segment	B_T04
		.incbin	"../../../bin/b.T04.bin"
		.segment	B_T05
		.incbin	"../../../bin/b.T05.bin"

		.MODULE	PART2
		.segment	B_T06
		.incbin	"../../../bin/b.T06.bin"
		.segment	B_T07
		.incbin	"../../../bin/b.T07.bin"
		.segment	B_T08
		.incbin	"../../../bin/b.T08.bin"
		.segment	B_T09
		.incbin	"../../../bin/b.T09.bin"
		.segment	B_T0A
		.incbin	"../../../bin/b.T0A.bin"
		.segment	B_T0B
		.incbin	"../../../bin/b.T0B.bin"

		.MODULE	PART3
		.segment	B_T0C
		.incbin	"../../../bin/b.T0C.bin"
		.segment	B_T0D
		.incbin	"../../../bin/b.T0D.bin"
		.segment	B_T0E
		.incbin	"../../../bin/b.T0E.bin"
		.segment	B_T0F
		.incbin	"../../../bin/b.T0F.bin"
		.segment	B_T10
		.incbin	"../../../bin/b.T10.bin"

		.MODULE	PART4
		.segment	B_T11
		.incbin	"../../../bin/b.T11.bin"
		.segment	B_T12
		.incbin	"../../../bin/b.T12.bin"
		.segment	B_T13
		.incbin	"../../../bin/b.T13.bin"
		.segment	B_T14
		.incbin	"../../../bin/b.T14.bin"
		.segment	B_T15
		.incbin	"../../../bin/b.T15.bin"
		.segment	B_T16
		.incbin	"../../../bin/b.T16.bin"

		.MODULE	PART5
		.segment	B_T17
		.incbin	"../../../bin/b.T17.bin"
		.segment	B_T18
		.incbin	"../../../bin/b.T18.bin"
		.segment	B_T19
		.incbin	"../../../bin/b.T19.bin"
		.segment	B_T1A
		.incbin	"../../../bin/b.T1A.bin"
		.segment	B_T1B
		.incbin	"../../../bin/b.T1B.bin"
		.segment	B_T1C
		.incbin	"../../../bin/b.T1C.bin"

		.MODULE	PART6
		.segment	B_T1D
		.incbin	"../../../bin/b.T1D.bin"
		.segment	B_T1E
		.incbin	"../../../bin/b.T1E.bin"
		.segment	B_T1F
		.incbin	"../../../bin/b.T1F.bin"
		.segment	B_T20
		.incbin	"../../../bin/b.T20.bin"
		.segment	B_T21
		.incbin	"../../../bin/b.T21.bin"
		.segment	B_T22
		.incbin	"../../../bin/b.T22.bin"

		.MODULE	END9
		.segment	A_T1E
		.incbin	"../../../bin/a.T1E.bin"
		.segment	A_T1F
		.incbin	"../../../bin/a.T1F.bin"
		.segment	A_T10
		.incbin	"../../../bin/a.T10.bin"

		.MODULE	END11
		.segment	A_T21
		.incbin	"../../../bin/a.T21.bin"
		.segment	A_T22
		.incbin	"../../../bin/a.T22.bin"

		.MODULE	T20
		.segment	A_T20
		.incbin	"../../../bin/a.T20.bin"
