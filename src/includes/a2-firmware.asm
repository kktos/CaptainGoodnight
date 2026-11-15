		.namespace	sys

KBD		=	$C000
CLR80STORE	=	$C000		; write
KBDSTRB		=	$C010
SETSTDZP	=	$C008		; write: main zero page, stack and language card
SETALTZP	=	$C009		; write: aux zero page, stack and language card
CLR80VID	=	$C00C		; write: 40 columns
SPKR		=	$C030

TEXTOFF		=	$C050
TEXTON		=	$C051
MIXEDOFF	=	$C052
PAGE2OFF	=	$C054
PAGE2ON		=	$C055
HIRESON		=	$C057
DHIRESOFF	=	$C05F		; AN3 on
BUTN0		=	$C061		; bit 7: open-apple / button 0
BUTN1		=	$C062		; bit 7: solid-apple / button 1

ROMIN2		=	$C082		; ROM read, LC write disabled
; RR: LC bank 2 / bank 1 read, write enabled (read it twice)
LCBANK2		=	$C083
LCBANK1		=	$C08B

HOME		=	$FC58

		.namespace
