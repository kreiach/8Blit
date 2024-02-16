                processor 6502				; s01e07 Ex8. Demonstration of drawing two full color sprites, moving ball and the
                include	 "vcs.h"			; various size modifies you can apply to the ball. Controls the ball color by modifing 
                include  "macro.h"			; the playfield color
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

ball_life        equ    #50                 ; lifespan of a missle

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
b_x             ds      1                   ; 1 byte - ball x pos
b_y             ds      1                   ; 1 byte - ball y pos
tb_y            ds      1                   ; 1 byte - ball 0 y pos
tball           ds      1                   ; 1 byte - ball 0 life
enabl           ds      1                   ; 1 byte - temporary holder of ENABL
hmbl            ds      1                   ; 1 byte - temporary holder of HMBL
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
                sta     b_y                 ; (3)

                lda     #50                 ; (2) a = hpos
                ldx 	#0			        ; (2) x = object 0-1 player, 2-3 missiles, 4 ball
                jsr 	pos_x				; (6) set the initial course position of the player 0 graphic

                lda     #%00001000          ; (2)
                sta     REFP0               ; (3) Reflect P0 to face to the right

                lda     #120               ; (2) a = hpos
                ldx 	#1			        ; (2) x = object 0-1 player, 2-3 missiles, 4 ball
                jsr 	pos_x				; (6) set the initial course position of the player 1 graphic

                lda     #60                 ; (2) a = hpos
                ldx 	#4			        ; (2) x = object 0-1 player, 2-3 missiles, 4 ball
                jsr 	pos_x				; (6) set the initial course position of the player 1 graphic                

                lda     #ball_life           ; (2) lifespan of a missle
                sta     tball               ; (3)

                lda     #%00000001          ; (2) or could be #1
                sta     VDELP0              ; (3) Delay player 0 (GRP0 until writing to GRP1)

                lda     #%00110000          ; (2) D4, D5 - 8 pixel width
                ;lda     #%00100000          ; (2) D4, D5 - 4 pixel width
                ;lda     #%00010000          ; (2) D4, D5 - 2 pixel width
                ;lda     #%00000000          ; (2) D4, D5 - 1 pixel width
                sta     CTRLPF              ; (3) ball size

                lda     #$0E                 ; (2) white
                sta     COLUPF              ; (3) Playfield color, also affects ball color

                lda     #%11110000          ; (2) Move ball 0 +1 to the right
                sta     hmbl
                sta     HMBL                ; (3) horizontal move ball

                ldx     #0                  ; (2)
                stx     HMP1                ; (3) Set player graphics 0 & 1 to stationary
                stx     HMP0                ; (3)                

nextframe:		VERTICAL_SYNC				; macro included in macro.h file

                sta     WSYNC               ; (3) 
                sta     HMOVE               ; (3) Move all our graphics

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

                lda     b_y                 ; (2) 
                sta     tb_y                ; (3) make a copy of m0_y to use for drawing on the screen

                lda 	#pf_h			    ; (2)
                sta     scanline            ; (3) set the total hight for the playfield

                ldx     #ball_life          ; (2) the the max life for the ball

                dec     tball               ; (5) decrease the temporary life span
                bne     b_lives             ; (2/3) branch if greater than 0

                stx     tball               ; (3) reset the ball life

                lda     hmbl                ; (2) EOR/XOR the temp hmbl value with 1110 which will invert the value and 
                eor     #%11100000          ; (2) change the direction of the ball

                sta     hmbl                ; (3)
                sta     HMBL                ; (3)

             
b_lives:
               

                sta     WSYNC               ; (3)


kernel:
                ldx     #%00000010          ; (2) value to enable missle
                ldy     #%00000000          ; (2)
                stx     enabl               ; (3)

                inc     tb_y                ; (5)
                beq     draw_b              ; (2/3) branch 
                sty     enabl               ; (3)   
draw_b:
               
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
                lda     enabl               ; (2)
                sta     ENABL               ; (3)


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


