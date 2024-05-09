; Purrballs 0.3
; all rights reserved.

; Implementing a scoreboard in a game context

; This Episode on Youtube - https://youtu.be/CuFHfAzsTw0

; Become a Patron - https://patreon.com/8blit
; 8blit Merch - https://8blit.myspreadshop.com/
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; Follow on Facebook - https://www.facebook.com/8Blit
; Follow on Instagram - https://www.instagram.com/8blit
; Visit the Website - https://www.8blit.com 

; Email - 8blit0@gmail.com

	processor 6502

	include "vcs.h"
	include "macro.h"
	include "build.h"

; compiler symbols
;--------------------------------------
PADDLE_POS     = 5
SOUTLINES      = 15 
MISSILE_YPOS   = 75
MISSILE0_XPOS  = 43
MISSILE1_XPOS  = 116
SHOWEARS_LEN   = 30

        seg.u vars         ;        uninitialized segment
        org	$80            ;        origin set at base of ram 

; define variables
pf_segment     ds 1
pf_segindex    ds 1
m_y            ds 2        ;        missile y pos
p_x            ds 1
mBearing       ds 2        ;        (0-15) 16 angles 22.5 deg apart
mBearingOld    ds 2        ;        org bearing of ball before bounce
collisionCnt   ds 2        ;        collision count
pfCnt          ds 1        ;        playfield index
scoreCnt       ds 1        ;
mCollision     ds 1        ;        current players collision register value
r_seed         ds 1        ;        random seed
snd_on         ds 2        ;        1 byte per channel - >0 if sound is playing
score          ds 1        ;        value to display
digitIdx       ds 2        ;        index for digit to use within the data table
temp           ds 1        ;        general temp address to swap out values
voutCount      ds 1        ;        number of cycles left for vout
soutCount      ds 1        ;        number of cycles left for sount (the score)
showEarsCnt    ds 1        ;        the number of frames left to show the ears

pValue         ds 1        ;        the horizontal position of the paddle

; code
;--------------------------------------
	seg main               ;        start of main segment
	org $F000

reset:
	CLEAN_START	           ;        ouput: all ram/registers 0

	; generate a random seed from the interval timer
	lda INTIM              ;        unknown value to use as an initial random seed
	sta r_seed 

	lda #%00010111         ;        missiles and player double wide
	sta NUSIZ0             ;        p0+m0
	sta NUSIZ1             ;        p1+m1

	; set area values
	lda #%00010101         ;        playfield to reflect 
	sta CTRLPF  

softReset:


	lda #0 
	sta score              ;        reset the score
	sta showEarsCnt

	lda #MISSILE_YPOS
	sta m_y
	sta m_y+1

	ldx #0
	lda #MISSILE0_XPOS     ;        m0 horizontal position pulling 0 from x
	jsr initObject         ;        m0 starting position

	ldx #1
	lda #MISSILE1_XPOS     ;        m1 horizontal position
	jsr initObject         ;        m1 starting position

	lda #60                ;        middle screen
	ldx #0                 ;        p0
	jsr PositionX          ;        set horizontal position

	; lock the graphic object positions
	sta WSYNC
	; ---------------------

	sta HMOVE              ;        strobe horizontal move to set fine positions  

	lda #0
	sta HMP0               ;        clear p0 h movement
	sta HMP1               ;        clear p1 h movement
	sta pf_segindex        ;        first index of current playfield segment

	lda #YELLOW
	sta COLUP0
	lda #BLUE
	sta COLUP1

nextFrame:
	VERTICAL_SYNC          ;        output: a = 0; 3 scanlines

verticalBlank
	ldx #VBLANKTIME        ;        defined/precalculated in build.h
	stx TIM64T             ;        set 64-clock for 43 intervals. 

	lda pValue             ;        number of scanlines before paddle charged
	adc #1                 ;        wall thickness
	cmp #126               ;        farthest hpos for paddle
	bpl pos                ;        check if we're at the end
	.byte $2c              ;        jump forward 2 bytes  (skips lda #126)
pos:
	lda #126
	ldx #0
	jsr PositionX          ;        set paddle position

	; calculate the score
	lda score              ; 2      get the score   
	clc                    ; 2      clear the carry bit so it's not added in adc 
	pha                    ; 3      push the score to the stack 
	and #$0f               ; 2      mask the first nibble 
	sta temp               ; 3      store the first nibble in temp
	asl                    ; 2      shift left (multiply by 2)
	asl                    ; 2      shift left (multiply by 2)
	adc temp               ; 2      add the first nibble to the result 
	sta digitIdx           ; 3      store calculated index
	pla                    ; 4      pull original score from stack
	and #$f0               ; 2      mask the second nibble
	lsr                    ; 2      shift right (divide by 2)
	lsr                    ; 2      shift right (divide by 2)
	sta temp               ; 3      store calculated index
	lsr                    ; 2      shift right (divide by 2)
	lsr                    ; 2      shift right (divide by 2)
	adc temp               ; 2      add 
	sta digitIdx+1         ; 3      store the index in the address digitIdx+1.  

	; process the sound channels to turn off volume when counter runs out
	jsr snd_process

	; we're checking the collision between m0+pf, m1+pf, and m1+m2
	ldx #1                 ;        start with m1 and work down to m0
nextCollObject

	; collision detection
	lda CXM0P,X            ;        missile collision with player 
	ora CXM0FB,x           ;        missile collision with playfield?
	sta mCollision 
	lda #%11000000
	and mCollision
	bne collision
	lda #0                 ;        no collision, set collision count to 0
	sta collisionCnt,x
	jmp no_collision       ;        bypass collision handling

; when a collision occures we try to reflect to a vertical bearing. If on the
; next frame we're still registering a collision then we try a horizontal 
; bearing. If it's STILL registering a collision then we reflect it back 180
; degrees from the original pre-bounce bearing.

collision:
	; a collision occured
	lda collisionCnt,x     ;        times collision occured consecutively
	bne col_on             ;        branch if collisions are already ongoing

	lda CXM0FB,x
	and #%11000000
	beq doneM0FB
	jsr sndPlayBounce      ;        missile collision with pf
doneM0FB
	lda CXM0P,X            ;        missile collision with player
	and #%11000000
	beq doneM0P
	sed                    ;        set decimal flag
	clc
	lda score
	adc #1
	sta score
	cld                   ;        clear decimal flag
	jsr sndPlayPaddle
doneM0P
	lda mBearing,x         ;        get the current bearing
	sta mBearingOld,x      ;        store current mBearing
	eor #$FF               ;        reverse our bearings 
	sta mBearing,x
	inc mBearing,x         ;        additive reverse
	lda mBearing,x
	and #$03               ;        is bearing N,S,E,W?
	bne col_no_adj
	inc mBearing,x         ;        inc bearing offset to prevent cont reflection

col_no_adj: 
	jmp collision_done

col_on: 
	cmp #$01               ;        check collisionCnt
	beq revBearing         ;        first collision in series
	cmp #$03               ;        check collisionCnt
	bcc collision_done     ;        second/third collision in series
	bne collision_done     ;        more than three collisions in series
	lda mBearingOld,x      ;        retrieve pre-bounce bearing
	jmp revOrgBearing      ;        reverse bearing it 180 degrees

revBearing:                ;        reverse altered bearing
	lda mBearing,x
revOrgBearing:             ;        reverse original bearing
	clc                    ;        clear carry so not included in adc
	adc #$08               ;        reverse bearing by 180 degrees
	sta mBearing,x

collision_done:
	inc collisionCnt,x     ;        increment the number of consecutive collisions
no_collision:

	jsr moveBall

	dex                    ;        check next object
	bpl nextCollObject     ;        when result is positive move on to p0

	ldy #255               ;        prime for first playfield segment 
	sty pf_segment
	ldx #VOUTLINES         ;        defined in build.h
	stx pfCnt              ;        2 line kernel (2lk) so count is 1/2 pf height

	sta WSYNC
	; ---------------------

	sta HMOVE              ;        set fine horizontal positioning
	sta CXCLR              ;        clear all the collision registers

	lda #SOUTLINES         ; 2    
	sta soutCount          ; 3          

checktimer:
	lda INTIM              ;        time remaining (or past)
	bne checktimer         ;        burn remaining cycles

	sta WSYNC
	; ---------------------
	lda #%10000000         ; 2      dump paddle + vertical blank off
	sta VBLANK             ; 3


	lda showEarsCnt
	beq showScore
	ldx #$4
	lda #RED
	sta COLUPF 
showEars:
	lda ears,x
	sta PF1
	sta WSYNC
	; ---------------------

	sta WSYNC
	; ---------------------

	sta WSYNC
	; ---------------------

	dex
	bpl showEars
	dec showEarsCnt

	sta WSYNC
	; ---------------------

	jmp charge


showScore:
	ldy #$3
	lda #WHITE
	sta COLUPF
voutscore:
	ldx digitIdx           ; 2
	lda digits,x           ; 2      load the digit graphic for this scanline     
	and #$0f               ; 2      mask off first nibble so only see one number
	sta temp               ; 3
	ldx digitIdx+1         ; 2
	lda digits,x           ; 2
	and #$f0               ; 2
	ora temp               ; 2
	ldx #$0                ; 2      PF1 is displayed. clear before it repeats
	stx PF1                ; 3
	dey                    ; 2
	sta WSYNC              ; 3
	; ---------------------

	bne cont               ; 2/3
	ldy #3                 ; 2
	inc digitIdx           ; 2      inc digit offset to get next line of graphic
	inc digitIdx+1         ; 2
cont:
	sta PF1                ; 3      write the digit graphic to the playfield
	dec soutCount          ; 5
	bne voutscore          ; 2/3         

	SLEEP 20               ; 20     we need some padding before clearing PF1         

	lda #$0                ; 2
	sta PF1                ; 3      clear PF1  

	lda #RED
	sta COLUPF 
	sta WSYNC              ; 3
	; ---------------------

charge:
	lda #%00000000         ; 2      charge paddle
	sta VBLANK             ; 3
vout:    
	
	ldx pfCnt
	rol
	tax
	lda INPT1              ; 2      check paddle 0
	bpl donep0             ; 2/3    0=charging, 1=charged
	.byte $2c              ; 4      jumps 2 bytes ahead (bypassing the stx pValue)
donep0:
	stx pValue             ; 3      store current scanline value

	lsr pf_segindex        ; 5    5 
	bne skipx              ; 3    8 
	inc pf_segment         ; 5   13
	ldx #PFSEGHEIGHT       ; 2   15      
	stx pf_segindex        ; 3   18
skipx:     
	ldy pf_segment         ; 2   20
	lda PF0_data_cat,y     ; 4   24 
	sta WSYNC              ; 3   27           
	; ---------------------



	; draw playfield
	sta PF0                ; 3   29
	lda PF1_data_cat,y     ; 4   34
	sta PF1                ; 3   37
	lda PF2_data_cat,y     ; 4   41
	sta PF2                ; 3   44
	lda #ORANGE            ; 2   46 defined in build.h 
	sta COLUBK             ; 3   49

	ldy #0                 ; 2   51
	ldx #0
	lda m_y,y              ; 4   57 load ball y pos
	cmp pfCnt              ; 2   59 compare y pos to playfield counter
	bne noM1               ; 3   62 if not same continue with blank player graphic
	ldx #%00000010
noM1 
	stx ENAM0,y            ; 4   70 enable missile
	ldx #0
	iny 
	lda m_y,y              ; 4   57 load ball y pos
	cmp pfCnt              ; 2   59 compare y pos to playfield counter
	bne noM0               ; 3   62 if not same continue with blank player graphic
	ldx #%00000010
noM0 
	stx ENAM0,y            ; 4   70 enable missile
	sta WSYNC              ; 3  149
	; ---------------------


	ldx #0                 ; 2  151
	lda pfCnt              ; 3  154
	cmp #PADDLE_POS        ; 2  156
	bpl noP0               ;2/3 159
	ldx paddle             ; 3  162
noP0
	stx GRP0               ; 3  165

	dec pfCnt              ; 5  170
	bne vout               ;2/3 173

	sta WSYNC              ;        end kernel with a clean scan line
	; ---------------------

	lda #$2                ;        set D1 = 1 to initiate VBLANK
	sta VBLANK             ;        turn off the beam

	lda #$0
	sta PF0
	sta PF1
	sta PF2
	sta COLUBK
	sta ENAM0
	sta ENAM1
	sta GRP0

; ---- overscan (30 scanlines)
	ldx #OVERSCANTIME      ;        
	stx TIM64T             ;        Set a count of 35 with 64-clock interval

	; overscan remainder timer -----------
overscan_timer          
	ldx INTIM
	bne overscan_timer
	jmp nextFrame          ;        jump back up to start the next frame

moveBall subroutine
	; move the ball
	lda mBearing,x
	and #$0F               ;        strip the high nibble
	tay
	lda bearingOffset,y    ;        load x/y offsets based on the current bearing
	sta HMM0,x             ;        horizontally move the current missile object
                           ;        update balls horizontal motion register which
                           ;        uses the high nibble where the x offset is
                           ;        stored.
	and #$0F               ;        strip out high nibble which leave only offset
	sec                    ;        set the carry flag
	sbc #$08               ;        subtract 8 for 4bit 2's completment +/-
	clc                    ;        clear carry flag so it's not used in adc
	adc m_y,x              ;        add y offset to current y position
	cmp #128
	bcc ballactive         ;        is the ball still in the playfield?
	jsr sndPlayRespawn     ;        use the p0/p1 value in x for channel
	jsr initObject         ;        respawn the missile

	lda #MISSILE_YPOS
ballactive:
	sta m_y,x              ;        store the new y position

	rts 

initObject subroutine

	; 'randomly' select an initial bearing (direction)
	jsr galoisLfsrRand     ;        no need to store the seed for this one
	and #$0F               ;        limit the value to 0-15
	sta mBearing,x
	lda #SHOWEARS_LEN
	sta showEarsCnt
	lda #0
	sta score              ;        reset score
	rts

; Galois 8-bit Linear Feedback Shift Registers
; https://samiam.org/blog/20130617.html
galoisLfsrRand subroutine
	lda r_seed             ;        keep calling funtion to for better entropy
	lsr                    ;        shift right
	bcc .noeor0            ;        if carry 1, then exclusive OR the bits
	eor #$D4               ;        d4 tap (11010100)
.noeor0: 
	sta r_seed
	rts

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

; cues a sound to play. sets audio registers based on table lookup sndbank.
; parameters: x = channel (0|1), y = sound to play
sndPlayBounce
	lda #$0C
	sta AUDC0              ;        audio control   
	lda #$05
	sta AUDV0              ;        audio volume
	lda #$0F
	sta AUDF0              ;        audio frequence
	lda #01
	sta snd_on             ;        len of audio in frames (>0 = sound on)
	rts

sndPlayRespawn
	lda #$02
	sta AUDC1              ;        audio control   
	lda #$14
	sta AUDV1              ;        audio volume
	lda #$05
	sta AUDF1              ;        audio frequence
	lda #20
	sta snd_on+1           ;        len of audio in frames (>0 = sound on)
	rts  

sndPlayPaddle
	lda #$0E
	sta AUDC0              ;        audio control   
	lda #$05
	sta AUDV0              ;        audio volume
	lda #$03
	sta AUDF0              ;        audio frequence
	lda #04
	sta snd_on             ;        len of audio in frames (>0 = sound on)
	rts

; process sound channels to turn off volume when sound length counter runs out
snd_process:
	ldx #1                 ;        channel to process, start with channel 1
snd_ch     
	lda snd_on,x           ;        get sound length counter for this channel
	beq snd_done           ;        are we playing a sound? a>1 
	dec snd_on,x           ;        yes, decrese the sound length counter for channel
	bne snd_cont           ;        did we reach the end of the sound length?
	lda #0                 ;        yes
	sta AUDV0,x            ;        turn off the volume for this channel 
snd_done
snd_cont
	dex                    ;        do it again for channel 0
	beq snd_ch
	rts

	align $100             ;        align data

paddle
	.byte #%11111111
 
bearingOffset              ;        index  x-move  y-move
	.byte #%11100000       ;          0     -2       0    
	.byte #%11100111       ;          1     -2      -2    
	.byte #%11100110       ;          2     -2      -4    
	.byte #%11110110       ;          3     -1      -4    
	.byte #%00000110       ;          4      0      -4    
	.byte #%00010110       ;          5     +1      -4    
	.byte #%00100110       ;          6     +2      -4    
	.byte #%00100111       ;          7     +2      -2    
	.byte #%00101000       ;          8     +2       0    
 	.byte #%00101001       ;          9     +2      +2    
	.byte #%00101010       ;         10     +2      +4    
  	.byte #%00011010       ;         11     +1      +4    
	.byte #%00001001       ;         12      0      +2    
	.byte #%11111010       ;         13     -1      +4    
	.byte #%11101010       ;         14     -2      +4    
	.byte #%11101001       ;         15     -2      +2  

ears    
	.byte %11111001
	.byte %11111010
	.byte %01110100
	.byte %00101000
	.byte %00011000

	include "playfields/pf_cat.h"
	include "digits.h"

	org $fffa

	.word reset            ;        nmi ($fffa)
	.word reset            ;        reset ($fffc)
	.word reset            ;        irq ($fffe)