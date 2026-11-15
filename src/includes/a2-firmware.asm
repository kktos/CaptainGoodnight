		.namespace	sys

KBD		=	$C000
CLR80STORE	=	$C000		; write
KBDSTRB		=	$C010
SETSTDZP	=	$C008		; write: main zero page, stack and language card
SETALTZP	=	$C009		; write: aux zero page, stack and language card
CLR80VID	=	$C00C		; write: 40 columns

TEXTOFF		=	$C050
TEXTON		=	$C051
MIXEDOFF	=	$C052
PAGE2OFF	=	$C054
PAGE2ON		=	$C055
HIRESON		=	$C057
DHIRESOFF	=	$C05F		; AN3 on

; RR: LC bank 2 / bank 1 read, write enabled (read it twice)
LCBANK2		=	$C083
LCBANK1		=	$C08B

HOME		=	$FC58

		.namespace
