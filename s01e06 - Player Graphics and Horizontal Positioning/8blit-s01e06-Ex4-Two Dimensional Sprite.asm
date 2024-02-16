                processor 6502		; s01e06 Ex4. Two Dimensional Sprite
                include	 "vcs.h"	;
                include  "macro.h"	; Expand our fine movement example to draw a two dimensional sprite
                                        ;
                                        ; Some snippets from examples by Andrew Davie
                                        ;
                                        ; This Episode on Youtube - https://youtu.be/GObPgosXPPs
                                        ;
										; Become a Patron - https://patreon.com/8blit
										; 8blit Merch - https://8blit.myspreadshop.com/
										; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
										; Follow on Facebook - https://www.facebook.com/8Blit
										; Follow on Instagram - https://www.instagram.com/8blit
										; Visit the Website - https://www.8blit.com 
                   	                    ;
                       	                ; Email - 8blit0@gmail.com

MIN_HPOS    equ #33

P0HEIGHT	equ	#32

MAX_VPOS	equ	#192

BKCOLOR		equ 	#$9A		; background colour (blue)
COLP0		equ	#$0E		; player 0 sprite colour (white)

                seg.u	vars		; uninitialized segment
                org	$80

player0_x	ds	#MIN_HPOS	; byte variable to hold our horizontal position
p0_y		ds		        ; byte


                seg	main		; start of main segment
                org 	$F000


reset:		CLEAN_START		; macro included in macro.h file


                lda	#BKCOLOR	; (2)
                sta	COLUBK		; (3) set the PF color

                lda	#COLP0		; (2)
                sta	COLUP0		; (3) set the player 1 sprite colour

                lda	#80		; (2) the scan line to start drawing the player 0 graphic
                sta 	p0_y	        ; (3) assign a to our vertical position memory location

                stx 	player0_x	; (3)
                jsr 	pos_x		; (6) set the initial course position of the player 0 graphic

                ldx 	#%11110000	; (2) set the horizontal movement player 0 (HMP0) register to adjust the position of
                stx	HMP0		; (3) the player graphic to the right by 1 color clock (only uses the 4 high bits)

                                        ; 0111 = left 7
                                        ; 0110 = left 6
                                        ; 0101 = left 5
                                        ; 0100 = left 4
                                        ; 0011 = left 3
                                        ; 0010 = left 2
                                        ; 0001 = left 1
                                        ; 0000 = No motion
                                        ; 1111 = right 1
                                        ; 1110 = right 2
                                        ; 1101 = right 3
                                        ; 1100 = right 4
                                        ; 1011 = right 5
                                        ; 1010 = right 6
                                        ; 1001 = right 7
                                        ; 1000 = right 8

; ---- Begin main loop

startframe:	VERTICAL_SYNC		; macro included in macro.h file

; ---- 37 scanlines vertical blank (8,436 color clocks, 2,812 machine cycles)

                ldx 	#36 		; (2)
lvblank:	sta 	WSYNC		; (3) each scanline is 228 color clocks, 76 machine cycles
                dex			; (2) decrement x by 1
                bne 	lvblank		; (2/3) branch if not equal x != 37


                        ; 76543210
                lda     #%00000000	; (2) set D1 to 0 to end VBLANK
                sta	WSYNC		; (3)
                sta     VBLANK		; (3) turn on the beam

                sta 	HMOVE		; (3) horizontal move. this will move ALL the player, missle, and ball graphics at the same time
                                        ; HMOVE needs to execute during horizontal blanking so it should be done immediatly following
                                        ; a WSYNC. Additionally, any of the horizontal movement registers should not be modified within at least
                                        ; 24 machine cycles after an HMOVE.

; ---- 192 lines of drawfield             Each scanline
                                        ; (68 color clocks, 22 machine cycles) HBLANK
                                        ; (160 color clocks, 53 machine cycles) + 1 Playfield

                ldx 	#MAX_VPOS	; (2)
drawfield:		txa		; (2) transfer x to a
                sec			; (2) set carry flag
                sbc 	p0_y		; (2) subtrack memory from accumulator
                cmp 	#P0HEIGHT	; (2) have we already drawn all the lines of the graphic?
                bcc 	p0insprite	; (2/3)
                lda	#0		; (2)
p0insprite:
                tay			; (2)
                lda	player0,y	; (4) load the byte at index y starting from the memory location of player0
                                        ; this will grab the appropriate line of the graphic for the current scanline
                sta	WSYNC		; (3)
                sta	GRP0		; (3)
                dex			; (2)
                bne 	drawfield	; (2/3)

; ---- Overscan (6,840 color clocks, 2,280 machine cycles)

                        ; 76543210
                lda     #%00000010	; set D1 = 1 to initiate VBLANK
                sta     VBLANK		; turn off the beam
                ldx 	#MIN_HPOS	; (2)
overscan:       sta 	WSYNC		; (3)
                dex			; (2)
                bne 	overscan	; (2/3)

                jmp 	startframe	; (3) jump back up to start the next frame

Divide15				; the 6502/6507 has neither a multiplication nor a division instruction so here
.POS	SET 0				; we're building a list of values for divisions of 15 and which course position
        REPEAT 160
            .byte (.POS / 15) + 1
.POS	SET .POS + 1
        REPEND

pos_x  					; (3) subroutine to position the sprite, pass the HPOS in X register.
                lda	Divide15,x	; (2) load the value location at the xth byte in the Divide15 table
                tax			; (2) Transfer the accumulator to the x register
                sta 	WSYNC

; ---- this loop takes 5 machine cycles each iteration, that's 15 color clocks.

SimpleLoop:		dex		; (2) decrement x
                bne 	SimpleLoop	; (2/3) branch if not equal
                sta 	RESP0		; (3) strobe the RESP0 register to set the course position

                rts			; (6) return to caller

player0 	.byte %00000000		; 8BLIT bitmap, one byte per line, reverse order
                .byte %01000000
                .byte %01000000
                .byte %01000000
                .byte %01000000
                .byte %11100000
                .byte %00000000
                .byte %11100000
                .byte %01000000
                .byte %01000000
                .byte %01000000
                .byte %11100000
                .byte %00000000
                .byte %11100000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %10000000
                .byte %00000000
                .byte %11000000
                .byte %10100000
                .byte %10100000
                .byte %11000000
                .byte %10100000
                .byte %11000000
                .byte %00000000
                .byte %11100000
                .byte %10100000
                .byte %10100000
                .byte %11100000
                .byte %10100000
                .byte %11100000

                org 	$FFFA

irq:
                .word reset          	; NMI  ($FFFA)
                .word reset          	; RESET ($FFFC)
                .word reset          	; IRQ ($FFFE)


