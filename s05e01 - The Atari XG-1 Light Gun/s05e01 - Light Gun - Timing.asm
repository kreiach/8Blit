; S05E01 Atari XG-1 Light Gun Example #1

; Demonstrates how to read the trigger and detect light using polling, timing, and collision detection

; Create two bars with 1 active bot per bar. The spawning, direction, and speed of each bot is
; randomized. When the trigger is pulled on the light gun, the next frame fill the screen with a
; solid background and then using an intricate timing mechanism and counter to determine the x/y
; coordinates where the gun detects light. It will then draw the next frame with the ball positioned
; at that x/y coordinates. If a collision between the ball and player graphic is detected, the bot
; that was hit will be respawned off screen and reactivated

; Note: As far as I know, this is the way that ALL Atari 2600 games and examples that us the light gun
; work, and the only way it will work in all existing Atari 2600 emulators. I'm not a big fan of that
; so check out example two... but on real hardware!

; This Episode on Youtube - https://youtu.be/2Uy3hhwdqqs

; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; Donate with PayPal - https://www.paypal.com/paypalme/8Blit
; Become a Patron - https://patreon.com/8blit
; 8blit Merch - https://8blit.myspreadshop.com
; Follow on Facebook - https://www.facebook.com/8Blit
; Follow on Instagram - https://www.instagram.com/8blit
; Visit the Website - https://www.8blit.com

                 processor 6502

                 include "vcs.h"
                 include "macro.h"
                 include "build.h"

; bot parameters
BOTS             equ #2-1               ; 2 bots, adjusted for a 0 index
BOTSHEIGHT       equ #30                ; bot sprite height

                 seg.u vars
                 org $80

r_seed           ds 1                   ; rnd num used for spawn, direction, speed
botPtr           ds 4                   ; pointers to the 2 frames of bot graphics
botFrame         ds 2                   ; frame of bot animation
botFrameIdx      ds 2                   ; count of frames per cell animation
botSpeed         ds 2                   ; speed 1-3 for each bot
botSpawnWait     ds 2                   ; 0=active, >0 count down to respawn
botMove          ds 2                   ; direction and speed to move (using hmove)
botHm            ds 2                   ; hmove value for each bot
trigger          ds 1                   ; was the trigger pressed?
botHitCheck      ds 1                   ; should we check for a hit?
snd_on           ds 2                   ; 1 byte per audio channel - greater than 0 if sound is playing
shotX            ds 1                   ; x position where light was detected
shotY            ds 1                   ; y position where light was detected
temp             ds 1                   ; reusable temp var
line             ds 1                   ; temp var

                 seg main               ; start of main segment
                 org $F000

reset:           CLEAN_START            ; ouput: all ram registers 0

                 ; generate a random seed from the interval timer
                 lda INTIM              ; unknown value to use as an initial random seed
                 sta r_seed             ; random seed

                 ldx #1
initBot          jsr resetBot           ; initialize the bots
                 dex
                 bpl initBot

                 lda #%00000101         ; double size the bots
                 sta NUSIZ0
                 sta NUSIZ0+1
                                        ; split for learning purposes
                 eor #%00000100         ; playfield above graphics
                 eor #%00110000         ; ball is 8 clocks wide
                 sta CTRLPF             ; set playfield parameters

                 lda #$00               ; black
                 sta COLUBK             ; set the background color

                 lda #%00010000         ; prime trigger as not pulled
                 sta trigger            ; current status of the trigger
                 lda #0                 ; prime negative hit check
                 sta botHitCheck        ; are we checking for light? 1 = yes

nextframe:       jsr snd_process        ; do the sounds

                 VERTICAL_SYNC

verticalBlank
                 ldx #VBLANKTIME        ; defined/precalculated in build.h
                 stx TIM64T             ; set 64-clock for 43 intervals.

                 lda botHitCheck        ; check if we should check for light
                 beq showBots           ; 1 = yes
                 jmp checkHit           ; check for light

showBots
                 sta WSYNC              ; position ball horizontally
                 ;------------------------
                 ldx shotX
                 lda HorzTable,x
                 sta HMBL
                 and #$0f
                 tax
PosDelay         dex
                 bpl PosDelay
                 sta RESBL
                 sta WSYNC
                 ;------------------------
                 sta HMOVE

; select and set move direction
; output: set the movement for a bot that is not yet active
                 ldx #1                 ; start with second bot
bot:             lda botSpawnWait,x     ; was rnd generated in resetBot()
                 beq botActive          ; 0=active, >0 waiting to spawn
                 ldy botMove,x          ; get bot movement settings
                 bne noMove             ; 0=movement not yet set
                 and #%00000111         ; reduce to 0..8
                 tay
                 lda botSpeeds,y
                 sta botSpeed,x
                 sta botFrameIdx,x
                 lda botMovements,y     ; check the list of movement values
                 sta botMove,x          ; set the bots movement
                 sta botHm,x            ; store it's hmove value for later
                 ldy #0                 ; spawn position left
                 sty temp
                 ldy #%00001000         ; reflect
                 rol                    ; d7 tells if bot facing left or right
                 bcs reflect
                 ldy #155               ; spawn position right
                 sty temp
                 ldy #%00000000         ; no reflect
reflect:         sty REFP0,x
                 lda temp
                 jsr pos_x
noMove:          dec botSpawnWait,x     ; bot is not active
                 jsr randomLfsr         ; add a little entropy
botActive:       dec botFrameIdx,x      ; dec frame index counter
                 bne br                 ; do we move to the next cell
                 lda botSpeed,x         ; yes
                 sta botFrameIdx,x
                 lda botFrame,x
                 eor #%00000001
                 sta botFrame,x
br:              lda botFrame,x
                 tay
                 lda bot_pLSB,y
                 sta botPtr,x
                 lda bot_pMSB,y
                 sta botPtr+1,x
                 dex
                 bpl bot                ; move to the first bot

checktimer:      lda INTIM              ; time remaining (or past)
                 bne checktimer         ; burn remaining cycles

                 lda #%00000000         ; D6 to latch inpt4, D1 to 0 to end VBLANK
                 sta WSYNC              ; when xg-1 detects light, we want inpt4 to hold that
                 ;------------------------
                 sta VBLANK             ; turn on the beam
                 ldy #VOUTLINES-1

                 ; 50 sl
pad1             sta WSYNC
                 ;------------------------
                 dey
                 cpy #142
                 bne pad1

                 ; 30 sl
                 ldx #0                 ; track for first bot
                 jsr drawTrack

pad2             sta WSYNC
                 ;------------------------
                 dey
                 cpy #72
                 bne pad2

                 ; 30 sl
                 ldx #1                 ; track for second bot
                 jsr drawTrack

pad3             sta WSYNC
                 ;------------------------
                 dey
                 bpl pad3

                 lda #%00000010         ; D6 clear latches, D1 start vblank
                 sta WSYNC              ; before processing next frame clear any light detected
                 ;------------------------
                 sta VBLANK             ; turn off the beam

                 ldx #OVERSCANTIME
                 stx TIM64T             ; aet a count of 35 with 64-clock interval

                 jsr hitCheck           ; determine if xg-1 detected light during that frame
                 jsr moveBots
                 jsr triggerCheck       ; determine if the xg-1 trigger was pulled

overscan_timer   ldx INTIM
                 bne overscan_timer

                 jmp nextframe          ; jump back up to start the next frame

; -- set horizontal position (a = X position, x = 0-1 player, 2-3 missiles, 4 ball)
pos_x:           SUBROUTINE
                 sta WSYNC              ; (3) start a new line
                 ;------------------------
                 sec                    ; (2) set carry flag
.loop            sbc #15                ; (2) subtract 15
                 bcs .loop              ; (2/3) branch until negative
                 eor #7                 ; (2) calculate fine offset
                 asl                    ; (2)
                 asl                    ; (2)
                 asl                    ; (2)
                 asl                    ; (2)
                 sta RESP0,x            ; (3) fix coarse position
                 sta HMP0,x             ; (3) set fine offset
                 rts                    ; (6) return to caller

; x = bot to feature
; shotY = scanline for target
; 2kl-33sl
; draw bot (always)
; enable ball (check shotY)
moveBots:        SUBROUTINE
                 ldx #BOTS
.bot             lda botSpawnWait,x     ; check if we need to draw the bot
                 beq .move
                 lda #0
                 sta HMP0,x             ; set h movement
                 jmp .moved
.move            lda botHm,x            ; position the bot
                 sta HMP0,x             ; set h movement
.moved           dex
                 bpl .bot
                 sta WSYNC
                 ;------------------------
                 sta HMOVE
                 rts

drawTrack:       SUBROUTINE
                 sty temp
                 lda #BOTSHEIGHT
                 sta line
.loop            lda #0                 ; default to no shot
                 ldy temp
                 cpy shotY              ; shot on this line?
                 bne .noshot            ; not equal jump, no shot
                 lda #02                ; yes shot
.noshot          sta ENABL              ; set ball
                 lda botSpawnWait,x     ; check if we need to draw the bot
                 beq .drawBot
                 lda #0                 ; blank bot graphic
                 jmp .skip
.drawBot         ldy line               ; (2) load height of sprite
                 lda (botPtr),y
.skip            sta WSYNC
                 ;------------------------
                 sta GRP0,x
                 lda bot_col,y
                 sta COLUP0,x
                 dec temp
                 dec line
                 bpl .loop
                 ldy temp
                 rts

triggerCheck:    SUBROUTINE
                 lda SWCHA
                 and #%00010000         ; joystick up
                 cmp trigger            ; trigger changed?
                 beq .end
                 sta trigger
                 lda trigger            ; trigger pressed?
                 beq .end
                 lda #1
                 sta botHitCheck
                 ldx #0                 ; channel 0
                 ldy #0                 ; sound parameter index from sndbank_*
                 jsr snd_play           ; shoot sound
.end             rts

hitCheck:        SUBROUTINE
                 ldx #BOTS              ; loop through the bots
.bot             lda CXP0FB,x           ; check for a collision
                 and #%01000000
                 beq .nohit
                 jsr resetBot           ; yes, so respawn the bot
                 stx temp               ; store the bot number for later
                 ldx #1                 ; channel 0
                 ldy #1                 ; sound parameter index from sndbank_*
                 jsr snd_play           ; buzz sound
                 ldx temp               ; restore bot number
.nohit           dex                    ; move onto the next box
                 bpl .bot
                 lda #0                 ; disable the ball
                 sta ENABL
                 sta shotX              ; clear the shot x coordinate
                 sta shotY              ; clear the shot y coordinate
                 sta CXCLR              ; clear all collision flags
                 rts

; x=bot to feature
resetBot:        SUBROUTINE
                 jsr randomLfsr         ; get rnd number for spawn wait, direction, speed
                 sta botSpawnWait,x
                 lda #0                 ; clear any movement until spawn time is complete
                 sta botMove,x          ; clear the stored move value
                 sta HMP0,x             ; clear the move register
                 rts

; generate a random number
randomLfsr:      SUBROUTINE
                 lda r_seed             ; keep calling funtion for better entropy
                 lsr                    ; shift right
                 bcc .noeor             ; if carry 1, then exclusive OR the bits
                 eor #$D4               ; d4 tap (11010100)
.noeor           sta r_seed
                 rts

; cues a sound to play. sets audio registers based on table lookup sndbank.
; parameters: x = channel (0|1), y = sound to play
snd_play:        SUBROUTINE
                 lda sndbank_type,y
                 sta AUDC0,x            ; audio control
                 lda sndbank_vol,y
                 sta AUDV0,x            ; audio volume
                 lda sndbank_pitch,y
                 sta AUDF0,x            ; audio frequence
                 lda sndbank_len,y
                 sta snd_on,x           ; len of audio in frames (>0 = sound on)
                 rts

; process sound channels to turn off volume when sound length counter runs out
snd_process:     SUBROUTINE
                 ldx #1                 ; channel to process, start with channel 1
.ch              lda snd_on,x           ; get sound length counter for this channel
                 beq .done              ; are we playing a sound? a>1
                 dec snd_on,x           ; yes, decrese the sound length counter for this channel
                 bne .done              ; did we reach the end of the sound length?
                 lda #0                 ; yes
                 sta AUDV0,x            ; turn off the volume for this channel
.done            dex                    ; do it again for channel 0
                 beq .ch
                 rts

; define sounds
sndbank_type     .byte $0C, $02
sndbank_vol      .byte $0C, $0F
sndbank_pitch    .byte $0D, $06
sndbank_len      .byte $01, $08

; all the instructions in this next section need to be in the same page or the timing is messed up.
; this section will fill the screen with the background color, and then repeatedly poll the INPT4
; register to check for light. When draing the ball, we'll need to use the shotX and shotY values
; along with the HorxTable byte array to determine the timing for writing the horizontal position
; of the ball. If you change any of the timing here, it will not be accurate.

; Note: For the most part, this is almost exactly the same code all the other light gun games and
; examples use.

                 align 256

checkHit         lda INTIM              ; time remaining (or past)
                 bne checkHit           ; burn remaining cycles
                 sta WSYNC
                 ;------------------------

                 lda #236               ; timer for 199 scanlines
                 sta TIM64T

                 lda #%00000000         ; D1 to 0 to end VBLANK
                 sta WSYNC              ; when xg-1 detects light, we want inpt4 to hold that
                 ;------------------------
                 sta VBLANK             ; turn on the beam

                 lda #$2e               ; bright yellow(PAL) / orange(NTSC)
                 sta COLUBK
                 ldy #$00
                 nop                    ; remove a couple instrctions so making up 6mc
                 nop
                 nop
                 sty shotX              ; reset coordinates to no hit on screen
                 sty shotY
                 ldy #190               ; counter for hit scanline
                 sta WSYNC
                 ;------------------------
                 bit INPT3
                 nop
                 nop
                 nop
                 nop
                 nop

; loop through all scanlines looking for light 11 times each, if nothing then end frame
CoarseTest:      dey
                 beq CEndRelay          ; test is over with no hit detected
                 nop
                 nop
                 nop
                 nop
                 nop
                 nop
                 nop
                 bit INPT4              ; check for light
                 bpl HitX01to03         ; did we hit within the last 5 cycles
                 bit INPT4
                 bpl HitX04to08
                 bit INPT4
                 bpl HitX09to13
                 bit INPT4
                 bpl HitX14to18
                 bit INPT4
                 bpl HitX19to23
                 bit INPT4
                 bpl HitX24to28
                 bit INPT4
                 bpl HitX29to33
                 bit INPT4
                 bpl HitX34to38
                 bit INPT4
                 bpl HitX39to43
                 bit INPT4
                 bpl HitX44to48
                 bit INPT4
                 bpl HitX49to53
                 jmp CoarseTest

CEndRelay:       jmp CEndFrame          ; test is over with no hit detected

HitX49to53:      lda #158               ; hit was at pixel 158 or before
                 bne AdjustHpos
HitX44to48:      lda #143
                 bne AdjustHpos
HitX39to43:      lda #128
                 bne AdjustHpos
HitX34to38:      lda #113
                 bne AdjustHpos
HitX29to33:      lda #98
                 bne AdjustHpos
HitX24to28:      lda #83
                 bne AdjustHpos
HitX19to23:      lda #68
                 bne AdjustHpos
HitX14to18:      lda #53
                 bne AdjustHpos
HitX09to13:      lda #38
                 bne AdjustHpos
HitX04to08:      lda #23
                 bne AdjustHpos
HitX01to03:      lda #8
                 bit INPT4

AdjustHpos:      sty shotY
                 sta shotX

                 ldx #4                 ; 5 lines for adjusting horz. hit pos.
HitCycleAdjust:  ldy #9
HCADelay:        dey
                 bpl HCADelay           ; delay between lines is 75 cycles
                 nop
                 bit INPT4
                 bit INPT4              ; happens 1 cycle earlier in each line
                 bmi CEndFrame          ; if no hit detected anymore ...
                 sec
                 sbc #3                 ; hit was 3 pixel (1 cycle) earlier
                 sta shotX
                 nop
                 dex
                 bpl HitCycleAdjust

CEndFrame:       lda INTIM
                 bne CEndFrame
                 lda #30                ; timer for 26 scanlines (overscan)
                 ldy #%00000010         ; discharge lightgun sensor
                 sta WSYNC
                 ;------------------------
                 sta TIM64T
                 sty VBLANK
                 lda #$00
                 sta COLUBK

WaitOVS:         lda INTIM              ; wait for overscan period to end
                 bne WaitOVS
                 sta WSYNC
                 ;------------------------
                 lda #0
                 sta botHitCheck

                 jmp nextframe

                 align 256

HorzTable
                 .byte $30,$20,$10,$00,$f0,$e0,$d0,$c0
                 .byte $71,$61,$51,$41,$31,$21,$11,$01,$F1,$E1,$D1,$C1,$B1,$A1,$91
                 .byte $72,$62,$52,$42,$32,$22,$12,$02,$F2,$E2,$D2,$C2,$B2,$A2,$92
                 .byte $73,$63,$53,$43,$33,$23,$13,$03,$F3,$E3,$D3,$C3,$B3,$A3,$93
                 .byte $74,$64,$54,$44,$34,$24,$14,$04,$F4,$E4,$D4,$C4,$B4,$A4,$94
                 .byte $75,$65,$55,$45,$35,$25,$15,$05,$F5,$E5,$D5,$C5,$B5,$A5,$95
                 .byte $76,$66,$56,$46,$36,$26,$16,$06,$F6,$E6,$D6,$C6,$B6,$A6,$96
                 .byte $77,$67,$57,$47,$37,$27,$17,$07,$F7,$E7,$D7,$C7,$B7,$A7,$97
                 .byte $78,$68,$58,$48,$38,$28,$18,$08,$F8,$E8,$D8,$C8,$B8,$A8,$98
                 .byte $79,$69,$59,$49,$39,$29,$19,$09,$F9,$E9,$D9,$C9,$B9,$A9,$99
                 .byte $7A,$6A,$5A,$4A,$3A,$2A,$1A,$0A,$FA,$EA,$DA,$CA,$BA,$AA,$9A
                 .byte $8A,$6B

                 align $100             ; align data

botMovements     .byte #%00010000       ;l1
                 .byte #%00010000       ;l1
                 .byte #%00100000       ;l2
                 .byte #%00100000       ;l2
                 .byte #%11110000       ;r1
                 .byte #%11110000       ;r1
                 .byte #%11100000       ;r2
                 .byte #%11100000       ;r2

botSpeeds        .byte #12
                 .byte #10
                 .byte #10
                 .byte #8
                 .byte #8
                 .byte #10
                 .byte #10
                 .byte #12

bot_col          .byte #0
                 .byte #$06
                 .byte #$06
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$0A
                 .byte #$0A
                 .byte #$34
                 .byte #$34
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$08
                 .byte #$0A
                 .byte #$0A
                 .byte #$EE
                 .byte #$EE
                 .byte #$EE
                 .byte #$EE

bot_pLSB:        .byte <bot_f0          ; cell 1
                 .byte <bot_f1          ; cell 2

bot_pMSB:        .byte >bot_f0          ; cell 1
                 .byte >bot_f1          ; cell 2

bot_f0:          .byte $0               ; cell 1
                 .byte %11110000
                 .byte %11110000
                 .byte %01010000
                 .byte %01010000
                 .byte %01110000
                 .byte %01110000
                 .byte %11100000
                 .byte %11100000
                 .byte %11101000
                 .byte %11101000
                 .byte %01101000
                 .byte %01101000
                 .byte %01111000
                 .byte %01111000
                 .byte %01110000
                 .byte %01110000
                 .byte %00100000
                 .byte %00100000
                 .byte %11110000
                 .byte %11110000
                 .byte %01010000
                 .byte %01010000
                 .byte %11110000
                 .byte %11110000
                 .byte %11110000
                 .byte %11110000
                 .byte %01000000
                 .byte %01000000
                 .byte %00100000
                 .byte %00100000

bot_f1:          .byte $0               ; cell 2
                 .byte %01110000
                 .byte %01110000
                 .byte %00110000
                 .byte %00110000
                 .byte %01110000
                 .byte %01110000
                 .byte %01111000
                 .byte %01111000
                 .byte %11101000
                 .byte %11101000
                 .byte %10111000
                 .byte %00111000
                 .byte %01111000
                 .byte %01111000
                 .byte %01100000
                 .byte %01100000
                 .byte %00100000
                 .byte %00100000
                 .byte %11110000
                 .byte %11110000
                 .byte %01010000
                 .byte %01010000
                 .byte %11110000
                 .byte %11110000
                 .byte %11110000
                 .byte %11110000
                 .byte %01000000
                 .byte %01000000
                 .byte %00100000
                 .byte %00100000

                 org $fffa
                 .word reset            ; NMI  ($FFFA)
                 .word reset            ; RESET ($FFFC)
                 .word reset            ; IRQ ($FFFE)
