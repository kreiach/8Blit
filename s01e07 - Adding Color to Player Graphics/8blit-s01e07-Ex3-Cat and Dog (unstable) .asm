                processor 6502				; s01e07 Ex3. Unstable relationship
                include	 "vcs.h"			;
                include  "macro.h"			; Draw a colorful cat and dog, but it's unstable
                                            ;
                                            ; This Episode on Youtube - https://youtu.be/T-6WY-JdjFo
                                            ;
											; Become a Patron - https://patreon.com/8blit
											; 8blit Merch - https://8blit.myspreadshop.com/
											; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
											; Follow on Facebook - https://www.facebook.com/8Blit
											; Follow on Instagram - https://www.instagram.com/8blit
											; Visit the Website - https://www.8blit.com 
                   		                    ;
                        	                ; Email - 8blit0@gmail.com

pf_h            equ     #192                ; playfield height
os_h            equ     #34                 ; overscan height
vb_h            equ     #37                 ; vertical blank height

cat_h           equ     #10                 ; cat sprite height
dog_h		    equ		#11                 ; dog sprite height

bnd_y_t         equ     #0                  ; top y bound of the screen
cat_bnd_y_b     equ     #bnd_y_t-#pf_h+#cat_h ; bottom y bound of the screen for cat
dog_bnd_y_b     equ     #bnd_y_t-#pf_h+#dog_h ; bottom y bound of the screen for dog

                seg.u	vars				; uninitialized segment
                org		$80

p0_y			ds      1	 				; 1 byte - player 0 y pos
grp0            ds      1                   ; temporary holder of GRP0
colup0          ds      1                   ; temporary holder of COLUP0
colup1          ds      1                   ; temporary holder of COLUP1
p1_y			ds      1		 			; 1 byte - player 1 y pos
tp0_y           ds      1                   ; 1 byte - temporary player 0 y pos
tp1_y           ds      1
scanline        ds      1                   ; 1 byte - current scanline

                seg		main				; start of main segment
                org 	$F000


reset:			CLEAN_START					; macro included in macro.h file

                lda		#$9A			    ; (2)
                sta		COLUBK				; (3) set the PF color

                lda		#168		        ; (2) 
                sta 	p0_y				; (3) initial y pos of p0

                lda     #168                ; (2)
                sta     p1_y                ; (3)

                lda     #70                 ; (2) a = hpos
                ldx 	#0			        ; (2) x = object 0-1 player, 2-3 missiles, 4 ball
                jsr 	pos_x				; (6) set the initial course position of the player 0 graphic

                lda     #90                 ; (2) a = hpos
                ldx 	#1			        ; (2) x = object 0-1 player, 2-3 missiles, 4 ball
                jsr 	pos_x				; (6) set the initial course position of the player 1 graphic

nextframe:		VERTICAL_SYNC				; macro included in macro.h file

                ldx 	#vb_h 				; (2)
lvblank:		sta 	WSYNC				; (3) each scanline is 228 color clocks, 76 machine cycles
                dex							; (2) decrement x by 1
                bne 	lvblank				; (2/3) branch if not equal x != 37

                lda     #%00000000			; (2) set D1 to 0 to end VBLANK
                sta		WSYNC				; (3)
                sta     VBLANK				; (3) turn on the beam

                lda     p0_y                ; (2)
                sta     tp0_y               ; (3)

                lda     p1_y                ; (2)
                sta     tp1_y               ; (3)

                lda 	#pf_h			    ; (2)
                sta     scanline            ; (3)

kernel:

                lda     #cat_h              ; (2) load height of sprite
                sec                         ; (2) set carry flag
                isb     tp0_y               ; (5) increase tp0_y subtract accumulator
                bcs     draw_p0             ; (3)
                lda     #0                  ; (2)
draw_p0:
                tay                         ; (2)
                lda     cat_col,y           ; (4)
                sta     colup0              ; (3)
                lda     cat_a,y             ; (4)
                tax                         ; (3)

                lda     #dog_h              ; (2) load height of sprite
                sec                         ; (2) set carry flag
                isb     tp1_y               ; (5) increase tp0_y subtract accumulator
                bcs     draw_p1             ; (3)
                lda     #0                  ; (2)
draw_p1:
                tay                         ; (2)
                lda     dog_col,y           ; (4)
                sta     colup1              ; (3)
                lda     dog_a,y             ; (4)

                ldy     colup0              ; (2)
;59    
                sta     WSYNC               ; (3) 
                stx     GRP0                ; (3)
                sta     GRP1                ; (3)
                sty     COLUP0              ; (3)
                lda     colup1              ; (2)
                sta     COLUP1              ; (3)

                dec		scanline			; (5)
                bne 	kernel			    ; (2/3)

                sta     WSYNC               ; (3)
;94
                lda     #%00000010			; set D1 = 1 to initiate VBLANK
                sta     VBLANK				; turn off the beam
                ldx 	#os_h			    ; (2)
overscan:       sta 	WSYNC				; (3)
                dex							; (2)
                bne 	overscan			; (2/3)

                jmp 	nextframe			; (3) jump back up to start the next frame

; SetHorizPos routine
; A = X coordinate
; X = player number (0 or 1)
pos_x
                sta     WSYNC	            ; (3) start a new line
	            sec		                    ; (2) set carry flag
loop
	            sbc     #15		            ; (2) subtract 15
	            bcs     loop	            ; (2/3) branch until negative
	            eor     #7		            ; (2) calculate fine offset
	            asl                         ; (2)
	            asl                         ; (2)
	            asl                         ; (2)
	            asl                         ; (2)
	            sta     RESP0,x	            ; (3) fix coarse position
	            sta     HMP0,x	            ; (3) set fine offset
	            rts		                    ; (6) return to caller

; cat sprite bottom->top, left->right
cat_a                                       ; 11 bytes
                .byte #0
                .byte %00010010
                .byte %00010010
                .byte %00011110
                .byte %00011110
                .byte %00111110
                .byte %00111110
                .byte %00110010
                .byte %00000100
                .byte %00000100
                .byte %00000010             

; cat color bottom->top
cat_col         .byte #0                    ; 11 bytes
                .byte #$0E 
                .byte #$2A 
                .byte #$2A 
                .byte #$2A 
                .byte #$2A 
                .byte #$2A 
                .byte #$2A 
                .byte #$2A 
                .byte #$2A 
                .byte #$0E 

; dog sprite bottom->top, left->right
dog_a                                       ; 11 bytes
                .byte #0
                .byte %00010010
                .byte %00010010
                .byte %00011110
                .byte %01111110
                .byte %11111110
                .byte %11111110
                .byte %10100010
                .byte %11100010
                .byte %00100000
                .byte %00100000

; dog color bottom->top
dog_col         .byte #0                    ; 11 bytes
                .byte #$F2 
                .byte #$F4 
                .byte #$F4 
                .byte #$F4 
                .byte #$F4 
                .byte #$F4 
                .byte #$F4 
                .byte #$F4 
                .byte #$F2 
                .byte #$0E

                org 	$FFFA


irq:
                .word reset          		; NMI  ($FFFA)
                .word reset          		; RESET ($FFFC)
                .word reset          		; IRQ ($FFFE)


