; S04E02 Paddle Controllers

; Demonstrates how to read the position and button's of all four paddle controllers over the two controller ports.

; This Episode on Youtube - https://youtu.be/CuFHfAzsTw0

; Become a Patron - https://patreon.com/8blit
; 8blit Merch - https://8blit.myspreadshop.com/
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; Follow on Facebook - https://www.facebook.com/8Blit
; Follow on Instagram - https://www.instagram.com/8blit
; Visit the Website - https://www.8blit.com 

; Email - 8blit0@gmail.com

; INPT0: Left port, first paddle
; INPT1: Left port, second paddle
; INPT2: Right port, first paddle
; INPT3: Right port, second paddle

; SWCHA 
; Triggers (fire button)
; Data Bit Paddle #
; D7 P0
; D6 P1
; D5/D4 (not used)
; D3 P2
; D2 P3
; D1/D0 (not used)

	processor 6502

	include "vcs.h"
	include "macro.h"

; compiler symbols
;--------------------------------------
VOUTLINES      = 180
SOUTLINES      = 5
VBLANKLINES    = 37 
VBLANKTIME     = (VBLANKLINES * 76) / 64
P0COL          = $2e
P1COL          = $2a
P2COL          = $9e
P3COL          = $9a
L0COL          = $26
L1COL          = $22
L2COL          = $96
L3COL          = $92
FCOL           = $44

	seg.u vars             ;        uninitialized segment
	org	$80                ;        origin set at base of ram 

pValue         ds 4        ;        value for each of the 4 paddles
bPress	       ds 4        ;        button pressed for each paddle

digitIdx1      ds 4        ;        index for digits to use within the data table
digitIdx2      ds 4        ;        index for digits to use within the data table
temp1          ds 1        ;        general temp address to swap out values
temp2          ds 1        ;        general temp address to swap out values
voutCount      ds 1        ;        number of cycles left for vout
soutCount      ds 1        ;        number of cycles left for sout (the score)

; code
;--------------------------------------
	seg	code
	org $f000

reset:
	CLEAN_START	           ;        output: all ram/registers 0

	lda #%00110101         ;        double size player, 8x missile
	sta NUSIZ0
	sta NUSIZ1

nextFrame:

	; clear players and missiles
	lda #%0000000          ; 2
	sta GRP0               ; 3
	sta GRP1               ; 3
	sta ENAM0              ; 3
	sta ENAM1              ; 3

	VERTICAL_SYNC          ;10      execute vertical sync
	ldx #VBLANKTIME        ; 2      verticl blank time
	stx TIM64T             ; 3
	lda #VOUTLINES         ; 2      scanlines for vout
	sta voutCount          ; 3
	lda #SOUTLINES         ; 2      scanlines for scoreboard
	sta soutCount          ; 3

	; check for trigger press
	lda #0                 ; 2      clear triggers
	sta bPress             ; 3      paddle 0
	sta bPress+1           ; 3      paddle 1
	sta bPress+2           ; 3      paddle 2
	sta bPress+3           ; 3      paddle 3

	ldx #2                 ; 2      #%00000010 - used to set bPress* which sets enable missile
	lda SWCHA              ; 2      read byte from input. e.g. (a) = 00110011. 0 = pressed
	rol                    ; 2      rotate left to check paddle 1 trigger. e.g. (a) = 01100110
	bcs chk_p1t            ; 3      branch if 1 was pushed into carry flag after rol
	stx bPress             ; 3      trigger on paddle 0 pressed
chk_p1t:
	rol                    ; 2      rotate left to check paddle 2 trigger. e.g. (a) = 11001100
	bcs chk_p2t            ; 3      branch if 1 was pushed into carry flag after rol
	stx bPress+1           ; 3      trigger on paddle 1 pressed
chk_p2t:
	rol                    ; 2      rotate left e.g. (a) = 10011000
	rol                    ; 2      rotate left e.g. (a) = 00110000
	rol                    ; 2      rotate left e.g. (a) = 01100000
	bcs chk_p3t            ; 3      branch if 1 was pushed into carry flag after rol
	stx bPress+2           ; 3      trigger on paddle 2 pressed
chk_p3t:
	rol                    ; 2      rotate left e.g. (a) = 11000000
	bcs chk_end            ; 3      branch if 1 was pushed into carry flag after rol
	stx bPress+3           ; 3      trigger on paddle 3 presset
chk_end:

	; calculate digit index for the score
	;----------------------------------
	ldy #$3                ; 2      start with paddle 3 value
findIdx:
	lda pValue,y           ; 2      get the score
	pha                    ; 3      push the score to the stack 
	and #$0f               ; 2      mask the first nibble 
	sta temp1              ; 3      store the first nibble in temp
	asl                    ; 2      shift left (multiply by 2)
	asl                    ; 2      shift left (multiply by 2)
	adc temp1              ; 2      add the first nibble to the result 
	sta digitIdx1,y        ; 3      store calculated index
	pla                    ; 4      pull original score from stack
	and #$f0               ; 2      mask the second nibble 
	lsr                    ; 2      shift right (divide by 2)
	lsr                    ; 2      shift right (divide by 2)
	sta temp1              ; 3      store the result in temp
	lsr                    ; 2      shift right (divide by 2)
	lsr                    ; 2      shift right (divide by 2)
	adc temp1              ; 2      add previous result in temp to get the offset
	sta digitIdx2,y        ; 3      store index @ address digitIdx+1
	dey                    ; 2      move on to p0 score
	bpl findIdx            ; 3      check the next paddle

	lda #%00000010         ; 2      set playfield to score mode
	sta CTRLPF             ; 3

	; position graphics
	lda #22                ; 2
	ldx #0                 ; 2
	jsr PositionX          ; 6+29   position paddle 0 graphic label
	lda #102               ; 2
	ldx #1                 ; 2
	jsr PositionX          ; 6+29   position paddle 1 graphic label
	lda #44                ; 2
	ldx #2                 ; 2
	jsr PositionX          ; 6+29   position missile 0 graphic label
	lda #124               ; 2
	ldx #3                 ; 2
	jsr PositionX          ; 6+29   position missile 1 graphic label
	sta WSYNC
	; ---------------------
	sta HMOVE              ;        strobe horizontal move to set fine positions

vbTimer:
	lda INTIM              ; 2
	bne vbTimer            ; 2/3
	
	lda #%10000000
	sta VBLANK             ; 3      stop vblank, dump INPT* to ground

	ldx #FCOL              ; 2

	; 12 scanlines
	ldy #4                 ; 2
topLabel:
	sta WSYNC              ; 3
	; ---------------------
	lda #P0COL             ; 2     load p0 color
	sta COLUP0

	lda p0,y               ; 4      load p0 graphic
	sta GRP0               ; 3      set p0 graphic
	lda p1,y               ; 4      load p1 graphic
	sta GRP1               ; 3      set p1 graphic
	lda #P1COL             ; 2      load p1 color 
	sta COLUP1             ; 3      set p1 color
	lda bPress             ; 2      load if paddle 0 trigger was pressed
	sta ENAM0              ; 3      enable/disable missile 0 (p0)
	nop                    ; 2      do nothing (for playfield timing)
	stx COLUP0             ; 3      set p0 color
	lda #P1COL             ; 2
	sta COLUP1             ; 3      set p1 color
	lda #P0COL             ; 2
	sta COLUP0             ; 3      set p0 color
	lda bPress+1           ; 2      load if paddle 1 trigger was pressed
	sta ENAM1              ; 3      enable/disable missile 1 (p1)
	SLEEP 7                ; 7      do nothing (for playfield timing)
	stx COLUP1             ; 3      set p1 color
	lda #P1COL             ; 2
	sta COLUP1             ; 3      set p1 color
	sta WSYNC              ; 3
	; ---------------------
	lda #P0COL             ; 2     load p0 color
	sta COLUP0             ; 3     set p0 color
	SLEEP 14               ;14     do nothing (for playfield timing)
	lda #P0COL             ; 2     load p1 color 
	sta COLUP1             ; 3     set p1 color
	SLEEP 6                ; 6     do nothing (for playfield timing)
	stx COLUP0             ; 3
	lda #P1COL             ; 2
	sta COLUP1             ; 3     set p1 color
	lda #P0COL             ; 2
	sta COLUP0             ; 3     set p0 color
	SLEEP 15               ;15     do nothing (for playfield timing)
	stx COLUP1             ; 3     set p1 color
	lda #P1COL             ; 2
	sta COLUP1             ; 3     set p1 color
	dey                    ; 2     move to next scanline of kernel
	bpl topLabel           ; 3
	sta WSYNC              ; 3
	; ---------------------

	; clear the players, missiles, and color
	lda #0                 ; 2
	sta GRP0               ; 3
	sta GRP1               ; 3
	sta ENAM0              ; 3
	sta ENAM1              ; 3
	lda #P0COL             ; 2
	sta COLUP0             ; 3
	lda #P1COL             ; 2
	sta COLUP1             ; 3
	sta WSYNC              ; 3
	; ---------------------
	sta WSYNC              ; 3
	; ---------------------

	; get graphic from data table by index
	;-------------------------------------
	; the digit graphics are stored as doubles, but we only want to display a
	; single digit so we mask off the first nibble before writing it to the 
	; playfield

	ldx #L0COL             ; 2
	stx COLUP0             ; 3
	ldx #L1COL             ; 2
	stx COLUP1             ; 3

voutscore1:
 
	ldx digitIdx1          ; 3      get the index of the 1's position for p0
	lda digits,x           ; 4      load the digit graphic for this scanline
	and #$0f               ; 2      mask off first nibble so only see one number
	sta temp1              ; 3      store in temp to combine later
	ldx digitIdx2          ; 3      get the index of the 10's position for p0
	lda digits,x           ; 4      load the digit graphic for this scanline
	and #$f0               ; 2      mask off second nibble so only see one number
	ora temp1              ; 3      'or' it with the 1's graphic we saved earlier
	sta WSYNC              ; 3/2    end scanline
	; ---------------------

	sta PF1                ; 3    3 draw the the p0 score
	sta temp1              ; 3      save p0 graphic for the next scanline
	ldx digitIdx1+1        ; 3      get the index of the 1's position for p1
	lda digits,x           ; 4      load the digit graphic for this scanline
	and #$0f               ; 2      mask off first nibble so only see one number
	sta temp2              ; 3
	ldx digitIdx2+1        ; 3
	lda digits,x           ; 4
	and #$f0               ; 2
	ora temp2              ; 3
	nop                    ; 2      we need to be past cycle 38 to rewrite pf1
	nop                    ; 2
	nop                    ; 2
	sta PF1                ; 3   39
	sta temp2              ; 3      save p1 graphic for the next scanline
	sta WSYNC              ; 3
	; ---------------------
	inc digitIdx1          ; 5      increase the offset for the p0 1's digit
	inc digitIdx1+1        ; 5      increase the offset for the p1 1's digit

	lda temp1              ; 3      get previous saved p0 graphic
	sta PF1                ; 3   16 write to pf1
	inc digitIdx2          ; 5      increase the offset for the p0 10's digit
	inc digitIdx2+1        ; 5      increase the offset for the p1 10's digit
	lda temp2              ; 3      get the previous saved p1 graphic
	nop                    ; 2      we need to be past cycle 38 to rewrite pf1
	nop                    ; 2
	nop                    ; 2
	nop                    ; 2
	sta PF1                ; 3   40 write to pf1
        
	dec soutCount          ; 5      counting down 5 cycles at 2 scanlines per
	bne voutscore1         ; 2/3

	sta WSYNC              ; 3
	; ---------------------

	; clear graphics, missiles, and color
	lda #0                 ; 2
	sta GRP0               ; 3 
	sta GRP1               ; 3
	sta PF1                ; 3
	sta ENAM0              ; 3
	sta ENAM1              ; 3
	lda #P0COL             ; 2
	sta COLUP0             ; 3
	lda #P1COL             ; 2
	sta COLUP1             ; 3
	

	sta WSYNC              ; 3
	; ---------------------
	sta WSYNC              ; 3
	; ---------------------
	sta WSYNC              ; 3
	; ---------------------
	sta WSYNC              ; 3
	; ---------------------
	sta WSYNC              ; 3
	; ---------------------	

	lda #$0                ; 2
	sta PF1                ; 3

	ldx #FCOL              ; 2

	; 12 scanlines
	ldy #4                 ; 2
bottomLabel:
	sta WSYNC              ; 3
	; ---------------------
	lda #P2COL             ; 2      load p0 color
	sta COLUP0
	lda p0,y               ; 4
	sta GRP0               ; 3
	lda p1,y               ; 4
	sta GRP1               ; 3
	lda #P3COL             ; 2      load p1 color 
	sta COLUP1             ; 3      set p1 color
	lda bPress+2           ; 2      load paddle 2 trigger value
	sta ENAM0              ; 3      set p0 missile
	nop                    ; 2      kill a couple cycles for playfield timing
	stx COLUP0             ; 3
	lda #P3COL             ; 2
	sta COLUP1             ; 3
	lda #P2COL             ; 2
	sta COLUP0             ; 3
	lda bPress+3           ; 2      load paddle 3 trigger value
	sta ENAM1              ; 3      set p1 missile
	SLEEP 7                ; 7      kill some cycles for playfield timing
	stx COLUP1             ; 3      set p1 color
	lda #P3COL             ; 2
	sta COLUP1             ; 3      set p1 color
	sta WSYNC              ; 3
	; ---------------------
	lda #P2COL             ; 2      load p0 color
	sta COLUP0             ; 3      set p0 color
	SLEEP 14               ;14
	lda #P2COL             ; 2      load p1 color 
	sta COLUP1             ; 3      set p1 color
	SLEEP 6                ; 6
	stx COLUP0             ; 3
	lda #P3COL             ; 2
	sta COLUP1             ; 3      set p1 color
	lda #P2COL             ; 2
	sta COLUP0             ; 3      set p0 color
	SLEEP 15               ;15
	stx COLUP1             ; 3
	lda #P3COL             ; 2
	sta COLUP1             ; 3
	dey                    ; 2
	bpl bottomLabel        ; 2/3    next scanline

	sta WSYNC              ; 3
	; ---------------------

	; clear graphics, missiles, and color
	lda #0                 ; 2
	sta GRP0               ; 3 
	sta GRP1               ; 3
	sta ENAM0              ; 3
	sta ENAM1              ; 3
	lda #P0COL             ; 2
	sta COLUP0             ; 3
	lda #P1COL             ; 2
	sta COLUP1             ; 3

	sta WSYNC              ; 3
	; ---------------------
	sta WSYNC              ; 3
	; ---------------------

	ldx #L2COL             ; 2
	stx COLUP0             ; 3
	ldx #L3COL             ; 2
	stx COLUP1             ; 3	

	lda #SOUTLINES         ; 2
	sta soutCount          ; 3

voutscore2:

	ldx digitIdx1+2        ; 3      get the index of the 1's position for p0
	lda digits,x           ; 4      load the digit graphic for this scanline
	and #$0f               ; 2      mask off first nibble so only see one number
	sta temp1              ; 3      store in temp to combine later
	ldx digitIdx2+2        ; 3      get the index of the 10's position for p0
	lda digits,x           ; 4      load the digit graphic for this scanline
	and #$f0               ; 2      mask off second nibble so only see one number
	ora temp1              ; 3      'or' it with the 1's graphic we saved earlier
	sta WSYNC              ; 3/2    end scanline
	; ---------------------

	sta PF1                ; 3    3 draw the the p0 score
	sta temp1              ; 3      save p0 graphic for the next scanline
	ldx digitIdx1+3        ; 3      get the index of the 1's position for p1
	lda digits,x           ; 4      load the digit graphic for this scanline     
	and #$0f               ; 2      mask off first nibble so only see one number
	sta temp2              ; 3
	ldx digitIdx2+3        ; 3
	lda digits,x           ; 4
	and #$f0               ; 2
	ora temp2              ; 3
	nop                    ; 2      we need to be past cycle 38 to rewrite pf1
	nop                    ; 2
	nop                    ; 2
	sta PF1                ; 3   39           
	sta temp2              ; 3      save p1 graphic for the next scanline
	sta WSYNC              ; 3
	; ---------------------
	inc digitIdx1+2        ; 5      increase the offset for the p0 1's digit
	inc digitIdx1+3        ; 5      increase the offset for the p1 1's digit
                
	lda temp1              ; 3      get previous saved p0 graphic
	sta PF1                ; 3   16 write to pf1
	inc digitIdx2+2        ; 5      increase the offset for the p0 10's digit
	inc digitIdx2+3        ; 5      increase the offset for the p1 10's digit
	lda temp2              ; 3      get the previous saved p1 graphic
	nop                    ; 2      we need to be past cycle 38 to rewrite pf1
	nop                    ; 2
	nop                    ; 2
	nop                    ; 2
	sta PF1                ; 3   40 write to pf1
        
	dec soutCount          ; 5      counting down 5 cycles at 2 scanlines per
	bne voutscore2         ; 2/3

	sta WSYNC              ; 3
	; ---------------------
	lda #$0                ; 2
	sta PF1                ; 3

	lda #%00000010         ; 2      start vblank, charge paddle capacitors
	sta VBLANK             ; 3

	; start loop to read paddles (max 180 scanlines)
	ldx #0                 ; 2
midBand:
	sta WSYNC              ; 3
	; ---------------------
	; check if paddle caps are charged. 
	lda INPT0              ; 2      check paddle 0
	bpl donep0             ; 2/3    0=charging, 1=charged
	.byte $2c              ; 4      jumps 2 bytes ahead (bypassing the stx pValue)
donep0:
	stx pValue             ; 3      store current scanline value

	lda INPT1              ; 2      check paddle 1
	bpl donep1             ; 2/3    0=charging, 1=charged
	.byte $2c              ; 4      jumps 2 bytes ahead (bypassing the stx pValue)
donep1:
	stx pValue+1           ; 3      store current scanline value

	lda INPT2              ; 2      check paddle 2
	bpl donep2             ; 2/3    0=charging, 1=charged
	.byte $2c              ; 4      jumps 2 bytes ahead (bypassing the stx pValue)
donep2:
	stx pValue+2           ; 3      store current scanline value

	lda INPT3              ; 2      check paddle 3
	bpl donep3             ; 2/3    0=charging, 1=charged
	.byte $2c              ; 4      jumps 2 bytes ahead (bypassing the stx pValue)
donep3:
	stx pValue+3           ; 3      store current scanline value

	inx                    ; 2
	cpx voutCount          ; 2
	bne midBand            ; 2/3    nextscanline

	jmp nextFrame          ; 3      jump to start new frame

	include "digits.h"     ;        external file defining the digit graphics

; -----------------------------------------------------------------------------
; PositionX
; A - Horizontal position of the object
; X - Object to position
;   0 - Player 0
;   1 - Player 1
;   2 - Missile 0
;   3 - Missile 1
;   4 - Ball
; -----------------------------------------------------------------------------

PositionX subroutine
	sec                    ; 2    2 set the carry flag
	sta WSYNC              ; 3    5 start a new line
	; ---------------------
.divide
	sbc #15                ; 2    2 subtract 15
	bcs .divide            ; 2    4 branch until negative
	eor #7                 ; 2    6 calculate fine offset
	asl                    ; 2    8 shift left
	asl                    ; 2   10
	asl                    ; 2   12
	asl                    ; 2   14
	sta HMP0,x             ; 5   19 set fine offset
	sta RESP0,x            ; 4   23 set coarse position
	rts                    ; 6   29 return	   

	org $fffa              ;        pad to last 6 bytes

	.word reset            ;        nmi ($fffa)
	.word reset            ;        reset ($fffc)
	.word reset            ;        irq ($fffe)









	