                processor 6502				; s01e07 Ex7. Demonstration of drawing two full color sprites, moving missiles and the
                include	 "vcs.h"			; various cloning and sizes for the players and missles Number-size player-missle (MUSIZ#)
                include  "macro.h"			; 
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

pf_h            equ     #96                 ; playfield height
os_h            equ     #34                 ; overscan height
vb_h            equ     #37                 ; vertical blank height

cat_h           equ     #10                 ; cat sprite height
dog_h		    equ		#10                 ; dog sprite height

mis_life        equ     #60                 ; lifespan of a missle

bnd_y_t         equ     #255                  ; top y bound of the screen
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
tp1_y           ds      1                   ; 1 byte - temporary player 1 y pos
m0_x            ds      1                   ; 1 byte - missile 0 x pos
m0_y            ds      1                   ; 1 byte - missile 0 y pos
tm0_y           ds      1                   ; 1 byte - temp missile 0 y pos
tmis0           ds      1                   ; 1 byte - temp missile 0 life
enam0           ds      1                   ; 1 byte - temporary holder of ENAM0
m1_x            ds      1                   ; 1 byte - missile 1 x pos
m1_y            ds      1                   ; 1 byte - missile 1 y pos
enam1           ds      1                   ; 1 byte - temporary holder of ENAM1
tm1_y           ds      1                   ; 1 byte - temp missile 1 y pos
tmis1           ds      1                   ; 1 byte - temp missile 1 life
scanline        ds      1                   ; 1 byte - current scanline



                seg		main				; start of main segment
                org 	$F000


reset:			CLEAN_START					; macro included in macro.h file

                lda		#$9A			    ; (2)
                sta		COLUBK				; (3) set the PF color

                lda		#215		        ; (2) 
                sta 	p0_y				; (3) initial y pos of p0
                sta     p1_y                ; (3)

                lda     #210                ; (2)
                sta     m0_y                ; (3)
                sta     m1_y                ; (3)

                lda     #50                 ; (2) a = hpos
                ldx 	#0			        ; (2) x = object 0-1 player, 2-3 missiles, 4 ball
                jsr 	pos_x				; (6) set the initial course position of the player 0 graphic

                lda     #%00001000          ; (2)
                sta     REFP0               ; (3) Reflect P0 to face to the right

                lda     #120               ; (2) a = hpos
                ldx 	#1			        ; (2) x = object 0-1 player, 2-3 missiles, 4 ball
                jsr 	pos_x				; (6) set the initial course position of the player 1 graphic

                lda     #mis_life           ; (2) lifespan of a missle
                sta     tmis0               ; (3)
                sta     tmis1               ; (3)

                lda     #%0000010           ; (2) Instead of positioning missles seperatly, lets reset them to the player graphis positions
                sta     RESMP1              ; (3)
                sta     RESMP0              ; (3)

                lda     #%00000001          ; (2) or could be #1
                sta     VDELP0              ; (3) Delay player 0 (GRP0 until writing to GRP1)

                lda     #%11110000          ; (2) Move missile player 0 +1 to the right
                sta     HMM0                ; (3)

                lda     #%00010000          ; (2) Move missile player 1 -1 to the left
                sta     HMM1                ; (3)

                                            ; list credit goes to member SeaGtGruff of AtariAge.com
                lda     #%00000000           ; one copy of player & missile 0, single width
                ;lda     #%00000101          ; one copy of player & missile 0, double width
                ;lda     #%00000111          ; one copy of player & missile 0, quadruple width
                ;lda     #%00000001          ; two copies of player close-spaced & missile, single width
                ;lda     #%00000010          ; two copies of player medium-spaced & missile, single width
                ;lda     #%00000100          ; two copies of player wide-spaced & missile, single width
                ;lda     #%00000011          ; three copies of player close-spaced & missile, single width
                ;lda     #%00000110          ; three copies of player medium-spaced & missile, single width
                ;lda     #%00010000          ; double width missile 
                ;lda     #%00100000          ; quadruple width missile 
                ;lda     #%00110000          ; octuple width missile 

                                            ; combine them!
                ;lda     #%00110110          ; one copy of player $ missile, quadruple width, octuple width missile 

                sta     NUSIZ0              ; apply to player 0

                ldx     #0                  ; (2)
                stx     HMP1                ; (3) Set player graphics 0 & 1 to stationary
                stx     HMP0                ; (3)                

nextframe:		VERTICAL_SYNC				; macro included in macro.h file

                sta     WSYNC               ; (3) 
                sta     HMOVE               ; (3) Move all our player missle graphics

                ldx 	#vb_h-1				; (2) -1 because we're using a wsync above to set hmove and avoid black lines on the left of our playfield
lvblank:		sta 	WSYNC				; (3) each scanline is 228 color clocks, 76 machine cycles
                dex							; (2) decrement x by 1
                bne 	lvblank				; (2/3) branch if not equal x != 37

                lda     #%00000000			; (2) set D1 to 0 to end VBLANK
                sta		WSYNC				; (3)
                sta     VBLANK				; (3) turn on the beam

                lda     p0_y                ; (2)
                sta     tp0_y               ; (3) make a copy of p0_y to use for drawing on the screen

                lda     p1_y                ; (2)
                sta     tp1_y               ; (3) make a copy of p1_y to use for drawing on the screen

                lda     m0_y                ; (2) 
                sta     tm0_y               ; (3) make a copy of m0_y to use for drawing on the screen

                lda     m1_y                ; (2)
                sta     tm1_y               ; (3) make a copy of m1_y to use for drawing on the screen

                lda 	#pf_h			    ; (2)
                sta     scanline            ; (3) set the total hight for the playfield

                ldx     #mis_life           ; the the max life for the missiles

                dec     tmis0               ; decrease the temporary life span
                bne     m0_lives            ; branch if greater than 0
                stx     tmis0               ; reset the temporary life span to the max life

                ldy     #%00000010
                sty     RESMP0              ; reset the position of missile 0 to the center of player 0
m0_lives:
                dec     tmis1               ; decrease the temporary life span 
                bne     m1_lives            ; branch if greater than 0
                stx     tmis1               ; reset the temporary life span to the max life
                sty     RESMP1              ; reset the position of missile 0 to the center of player 0
m1_lives:
                lda     #%00000000
                sta     RESMP0
                sta     RESMP1

                sta     WSYNC

kernel:

                ldx     #%00000010          ; (2) value to enable missle
                ldy     #%00000000          ; (2) value to disable missle

                stx     enam0               ; (3) default to enable missle
                stx     enam1               ; (3) default to enable missle

                inc     tm0_y               ; (5)
                beq     draw_m0             ; (2/3) branch 
                sty     enam0               ; (3)   
draw_m0:
               
                inc     tm1_y               ; (5)
                beq     draw_m1             ; (2) branch 
                sty     enam1               ; (3)
draw_m1:

                lda     #cat_h              ; (2) load height of sprite
                sec                         ; (2) set carry flag
                isb     tp0_y               ; (5) increase tp0_y subtract accumulator
                bcs     draw_p0             ; (3)
                lda     #0                  ; (2)
draw_p0:

                tay                         ; (2)
                lda     cat_col,y           ; (4)
                tax                         ; (2)
                lda     cat_a,y             ; (4)
                sta     GRP0                ; (3) Delayed by VDELP0 so it wont be written until GRP1 

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

                ldy     colup1              ; (2)   
                sta     WSYNC               ; (3)   
                sta     GRP1                ; (3)
                stx     COLUP0              ; (3)
                sty     COLUP1              ; (3)
                lda     enam0               ; (2)
                sta     ENAM0               ; (3)
                lda     enam1               ; (2)
                sta     ENAM1               ; (3)


                dec		scanline			; (5)
                bne 	kernel			    ; (2/3)


                sta     WSYNC               ; (3)
                lda     #%00000010			; set D1 = 1 to initiate VBLANK
                sta     VBLANK				; turn off the beam
                ldx 	#os_h			    ; (2)
overscan:       sta 	WSYNC				; (3)
                dex							; (2)
                bne 	overscan			; (2/3)

                jmp 	nextframe			; (3) jump back up to start the next frame


; A = X coordinate
; X = P0 = 0, P1 = 1, M0 = 2, M1 = 3, B = 4
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
                sta     WSYNC               ; (2) HMOVE should alway occur after a WSYNC
                sta     HMOVE               ; (3) Apply the fine positioning to all the graphics                
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


