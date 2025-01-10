; S05E01 Atari XG-1 Light Gun Example #2

; Demonstrates how to read the trigger and detect light using the hit box technique

; Create two bars with 1 active bot per bar. The spawning, direction, and speed of each bot is 
; randomized. When the trigger is pulled on the light gun, the next frame will draw a white square 
; in place of the first bot, and then check if the gun detects light. If not, the next frame will
; do the same for the second bot and check for light. When light is detected, the bot that was hit
; will be respawned off screen and reactivated

; Note: At the time this episode, the light detection works on real hardware but does not work on
; the Stella emulator.

; This Episode on Youtube - https://youtu.be/2Uy3hhwdqqs

; Become a Patron - https://patreon.com/8blit
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; Follow on Facebook - https://www.facebook.com/8Blit
; Follow on Instagram - https://www.instagram.com/8blit
; Visit the Website - https://www.8blit.com 
; 8blit Merch - https://8blit.myspreadshop.com/

                processor 6502

                include	"vcs.h"
                include "macro.h"
                include "build.h"

; bot parameters
BOTS            equ #2-1                ; 2 bots, adjusted for a 0 index
BOTSHEIGHT      equ #15                 ; bot sprite height

                seg.u vars
                org	$80

r_seed          ds 1                    ; rnd num used for spawn, direction, speed
botPtr          ds 4                    ; pointers to the 2 frames of bot graphics
botFrame        ds 2                    ; frame of bot animation
botFrameIdx     ds 2                    ; count of frames per cell animation 
botSpeed        ds 2                    ; speed 1-3 for each bot
botSpawnWait    ds 2                    ; 0=active, >0 count down to respawn
botMove         ds 2                    ; direction and speed to move (using hmove)
botHm           ds 2                    ; hmove value for each bot
trigger         ds 1                    ; was the trigger pressed?
botHitCheck     ds 1                    ; bot index being checked
snd_on          ds 2                    ; 1 byte per audio channel - greater than 0 if sound is playing

                seg	main                ; start of main segment
                org $F000

reset:          CLEAN_START             ; ouput: all ram registers 0

                ; generate a random seed from the interval timer
                lda INTIM               ; unknown value to use as an initial random seed
                sta r_seed              ; random seed

                ldx #1
initBot         jsr resetBot            ; initialize the bots
                dex
                bpl initBot

                lda #%00000101          ; double size the bots
                sta NUSIZ0
                sta NUSIZ0+1

                lda #%00000101          ; reflect playfield, place above graphics
                sta CTRLPF

                lda #0
                sta COLUPF              ; set the playfield color
                sta	COLUBK              ; set the background color

                lda #%00010000          ; prime trigger as not pulled
                sta trigger
                lda #%10000000          ; prime negative hit check
                sta botHitCheck

nextframe:      VERTICAL_SYNC

verticalBlank
                ldx #VBLANKTIME         ; defined/precalculated in build.h
                stx TIM64T              ; set 64-clock for 43 intervals.

                jsr snd_process         ; do the sounds

; select and set move direction
; output: set the movement for a bot that is not yet active
                ldx #1                  ; start with second bot
bot:            lda botSpawnWait,x      ; was rnd generated in resetBot()
                beq botActive           ; 0=active, >0 waiting to spawn
                ldy botMove,x           ; get bot movement settings
                bne noMove              ; 0=movement not yet set
                and #%00000111          ; reduce to 0..8
                tay
                lda botSpeeds,y
                sta botSpeed,x
                sta botFrameIdx,x
                lda botMovements,y      ; check the list of movement values
                sta botMove,x           ; set the bots movement
                sta botHm,x             ; store it's hmove value for later
                ldy #%00001000          ; reflect
                rol                     ; d7 tells if bot facing left or right
                bcs reflect
                ldy #%00000000          ; no reflect
reflect:        sty REFP0,x
noMove:         dec botSpawnWait,x      ; bot is not active
                jsr randomLfsr          ; add a little entropy
botActive:      dec botFrameIdx,x       ; dec frame index counter
                bne br                  ; do we move to the next cell
                lda botSpeed,x          ; yes
                sta botFrameIdx,x
                lda botFrame,x
                eor #%00000001
                sta botFrame,x
br:             lda botFrame,x          ; next 10 lines determine 16bit addr for each bots cell
                tay
                txa
                asl
                tax
                lda bot_pLSB,y
                sta botPtr,x
                lda bot_pMSB,y
                sta botPtr+1,x
                dex
                dex                     ; dec x2 because we asl'd it a few lines up
                bpl bot                 ; move to the first bot

checktimer:     lda INTIM               ; time remaining (or past)
                bne checktimer          ; burn remaining cycles

                lda #%01000000          ; D6 to latch inpt4, D1 to 0 to end VBLANK
                sta	WSYNC               ; when xg-1 detects light, we want inpt4 to hold that
                ;------------------------
                sta VBLANK              ; turn on the beam

                ldx #50
pad1            sta WSYNC
                ;------------------------
                dex
                bne pad1

                ldx #0                  ; track for first bot
                jsr drawTrack

                ldx #27
pad2            sta WSYNC
                ;------------------------
                dex
                bne pad2

                ldx #1                  ; track for second bot
                jsr drawTrack

                ldx #50
pad3            sta WSYNC
                ;------------------------
                dex
                bne pad3

                jsr hitCheck            ; determine if xg-1 detected light during that frame

                lda #%10000010          ; D6 clear latches, D1 start vblank 
                sta WSYNC               ; before processing next frame clear any light detected
                ;------------------------
                sta VBLANK              ; turn off the beam

                ldx #OVERSCANTIME
                stx TIM64T              ; set a count of 35 with 64-clock interval

                jsr triggerCheck        ; determine if the xg-1 trigger was pulled

overscan_timer  ldx INTIM
                bne overscan_timer

                jmp nextframe           ; jump back up to start the next frame

; -- set horizontal position (a = X position, x = 0-1 player, 2-3 missiles, 4 ball)
pos_x:          SUBROUTINE
                sta WSYNC               ; (3) start a new line
                ;------------------------
                sec                     ; (2) set carry flag
.loop           sbc #15                 ; (2) subtract 15
                bcs .loop               ; (2/3) branch until negative
                eor #7                  ; (2) calculate fine offset
                asl                     ; (2)
                asl                     ; (2)
                asl                     ; (2)
                asl                     ; (2)
                sta RESP0,x             ; (3) fix coarse position
                sta HMP0,x              ; (3) set fine offset
                rts                     ; (6) return to caller

; small kernel, x = bot to feature
drawTrack:      SUBROUTINE
                ldy #BOTSHEIGHT         ; load height of sprite
                lda botHitCheck         ; are we supposed to check for a hit?
                bmi .active             ; trigger pulled when 0
                cpx botHitCheck         ; is this the bot we need to check?
                bne .eline              ; not the bot you're looking for
                lda botSpawnWait,x
                bne .eline              ; bot is not active so dont do hit detection
                sta WSYNC               ; setup detect color, and solid graphic
                ;------------------------
                sta WSYNC
                ;------------------------
                lda #$0E
                sta COLUP0,x            ; change player graphic to white(ish)
                lda #$FF
                sta GRP0,x              ; solid block
                jmp .eline
.active         lda botSpawnWait,x      ; check if we need to draw the bot
                beq .drawBot
                sta WSYNC                ; no active bot or hit detection, so blank track
                ;------------------------
.eline          sta WSYNC
                ;------------------------
                sta WSYNC
                ;------------------------
                dey
                bpl .eline
                jmp .end
.drawBot        lda botHm,x	            ; position the bot
                sta HMP0,x              ; set h movement
                sta WSYNC
                ;------------------------
                sta HMOVE
.line           lda (botPtr),y          ; get line of graphic for bot
                sta WSYNC 
                ;------------------------
                sta WSYNC
                ;------------------------
                sta GRP0,x              ; set graphic
                lda bot_col,y           ; get bot color
                sta COLUP0,x            ; set
                dey                     ; next line?
                bpl .line               ; (2/3)
.end            lda #0
                sta HMP0,x              ; clear h movement 
                sta GRP0,x              ; clear graphic
                rts

; check if the xg-1 has detected light
hitCheck:       SUBROUTINE
                ldx botHitCheck         ; which bot are we checking this frame?
                bmi .end                ; none?
                bit INPT4               ; test lightgun sensor (joystick fire button)
                bmi .nohit              ; did we hit during this frame?
                jsr resetBot            ; yes, so respawn the bot
                ldx #1                  ; channel 0
                ldy #1                  ; sound parameter index from sndbank_*
                jsr snd_play            ; buzz sound
.nohit          dec botHitCheck
.end            rts

triggerCheck:   SUBROUTINE
                lda SWCHA
                and #%00010000          ; joystick up
                cmp trigger             ; trigger changed?
                beq .end
                sta trigger
                lda trigger             ; trigger pressed?
                beq .end
                ldx #BOTS               ; trigger was pressed
                stx botHitCheck
                ldx #0                  ; channel 0
                ldy #0                  ; sound parameter index from sndbank_*
                jsr snd_play            ; shoot sound
.end            rts

; x=bot to feature
resetBot        SUBROUTINE
                lda #153
                jsr pos_x               ; set the initial course position of the player 1 graphic
                sta HMOVE               ; move the box
                jsr randomLfsr          ; get rnd number for spawn wait, direction, speed
                sta botSpawnWait,x
                lda #0                  ; clear any movement until spawn time is complete
                sta botMove,x
                sta HMP0,x
                rts

; generate a random number
randomLfsr:     SUBROUTINE
                lda r_seed              ; keep calling funtion for better entropy
                lsr                     ; shift right
                bcc .noeor              ; if carry 1, then exclusive OR the bits
                eor #$D4                ; d4 tap (11010100)
.noeor          sta r_seed
                rts

; cues a sound to play. sets audio registers based on table lookup sndbank.
; parameters: x = channel (0|1), y = sound to play
snd_play        SUBROUTINE
                lda sndbank_type,y
                sta AUDC0,x             ; audio control
                lda sndbank_vol,y
                sta AUDV0,x             ; audio volume
                lda sndbank_pitch,y
                sta AUDF0,x             ; audio frequence
                lda sndbank_len,y
                sta snd_on,x            ; len of audio in frames (>0 = sound on)
                rts

; process sound channels to turn off volume when sound length counter runs out
snd_process     SUBROUTINE
                ldx #1                  ; channel to process, start with channel 1
.ch             lda snd_on,x            ; get sound length counter for this channel
                beq .done               ; are we playing a sound? a>1 
                dec snd_on,x            ; yes, decrese the sound length counter for this channel
                bne .done               ; did we reach the end of the sound length?
                lda #0                  ; yes
                sta AUDV0,x             ; turn off the volume for this channel 
.done           dex                     ; do it again for channel 0
                beq .ch
                rts

                align $100              ; align data

; define sounds
sndbank_type    .byte $0C, $02
sndbank_vol     .byte $0C, $0F
sndbank_pitch   .byte $0D, $06
sndbank_len     .byte $01, $08

botMovements    .byte #%00010000        ;l1
                .byte #%00010000        ;l1
                .byte #%00100000        ;l2
                .byte #%00100000        ;l2
                .byte #%11110000        ;r1
                .byte #%11110000        ;r1
                .byte #%11100000        ;r2
                .byte #%11100000        ;r2

botSpeeds       .byte #12
                .byte #10
                .byte #10
                .byte #8
                .byte #8
                .byte #10
                .byte #10
                .byte #12

bot_col         .byte #0
                .byte #$06
                .byte #$08
                .byte #$08
                .byte #$08
                .byte #$08
                .byte #$08
                .byte #$08
                .byte #$0A
                .byte #$34
                .byte #$08
                .byte #$08
                .byte #$08
                .byte #$0A
                .byte #$EE
                .byte #$EE 

bot_pLSB:       .byte <bot_f0           ; cell 1
                .byte <bot_f1           ; cell 2

bot_pMSB:       .byte >bot_f0           ; cell 1
                .byte >bot_f1           ; cell 2

bot_f0:         .byte $0                ; cell 1
                .byte %11110000
                .byte %01010000
                .byte %01110000
                .byte %11100000
                .byte %11101000
                .byte %01101000
                .byte %01111000
                .byte %01110000
                .byte %00100000
                .byte %11110000
                .byte %01010000
                .byte %11110000
                .byte %11110000
                .byte %01000000
                .byte %00100000

bot_f1:         .byte $0                ; cell 2
                .byte %01110000
                .byte %00110000
                .byte %01110000
                .byte %01111000
                .byte %11101000
                .byte %10111000
                .byte %01111000
                .byte %01100000
                .byte %00100000
                .byte %11110000
                .byte %01010000
                .byte %11110000
                .byte %11110000
                .byte %01000000
                .byte %00100000   

                org   $fffa
                .word reset             ; NMI  ($FFFA)
                .word reset             ; RESET ($FFFC)
                .word reset             ; IRQ ($FFFE)