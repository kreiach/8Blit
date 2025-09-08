; S05E03 CX-50 Keyboard Controllers - Example 2
;
; Demonstrates how to read ALL keyboard controllers for the Atari 2600. This include the CX-50,
; Video Touchpad, and the Kids Controller.
;
; I don't feel like the existing documentation on programming the keyboard controllers were
; very clear, so I attempted to include as much information as I could in the examples and the 
; related episode on youtube. 
;
; This Episode on Youtube - https://www.youtube.com/watch?v=4xBDVPzHV88
;
; Become a Patron - https://patreon.com/8blit
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; 8blit Merch - https://8blit.myspreadshop.com/
; Visit the Website - https://www.8blit.com 
;
;----------------------------------------
; differences from example 1
;
; SWACNT is set at startup. This is because we're always reading from both controllers, so that 
; never changes. In this context, no need to do this every retrace.
;
; SWCHA is set to supply power to a rail on both controllers at the same time. This means we don't
; have to loop through the entire process once for each controller.
;
; INPUT is read onces per retrace. We first check the controller in port-a, and then continue to 
; check the controller in port-b right after. 
;
; for more information on reading input on the atari 2600, refer the to following episode
; https://www.youtube.com/watch?v=h_m0Us77r04

                 processor 6502

                 include "vcs.h"
                 include "macro.h"
                 include "build.h"

;----------------------------------------
; constants

drawSpeed        equ #30                ; 2 frames per second animation speed
numFrames        equ #6                 ; number of frames in button animation

                 seg.u vars
                 org $80

;----------------------------------------
; variables

char_ram         ds charBuffSize        ; size of zero page buffer forcurrent char graphic
keyDown          ds 1                   ; is a key being pressed
drawTimer        ds 1                   ; counter for animation timing
currFrame        ds 1                   ; which button frame to display
char             ds 1                   ; the button being pressed
char_ptr         ds 2                   ; pointer to the character graphic
pf1a             ds 1                   ; left pf1
pf2a             ds 1                   ; left pf2
pf0b             ds 1                   ; right pf0
pf1b             ds 1                   ; right pf1
pf_y             ds 1                   ; counter to track the y position in the kernel
row              ds 1                   ; which row on the keyboard to activate
col              ds 1                   ; which column of the keyboard to read
keyboard         ds 1                   ; which keyboard to read

                 seg main               ; start of main segment
                 org $F000

reset            CLEAN_START            ; ouput: all ram registers 0

                 lda #$00
                 sta COLUBK             ; the background's black because we're going to cheat a bit

                 lda pins_mask          ; get the bit mask telling SWACNT which pins are
                 sta SWACNT             ; input/output.

;----------------------------------------
; start of the next frame

vsync            VERTICAL_SYNC          ; wait for vsync to stablize

;----------------------------------------
; start of vblank period

                 ldx #VBLANKTIME        ; set a timer for 37 sl of vblank
                 stx TIM64T

                 ; draw the button animation
                 lda #$0A               ; graphics are all playfield graphics
                 sta COLUPF             ; set the default button graphic color

                 lda keyDown
                 bne drawChar           ; if a key is pressed, jump to draw the character

                 dec drawTimer          ; key is not pressed so process button animation
                 bpl repeatFrame        ; if the current animation frame is NOT done,

                 lda #drawSpeed         ; animation frame is complete
                 sta drawTimer          ; reset the animation speed to 2 fps (30 screen refresses)

                 dec currFrame          ; move on to the next frame
                 bpl nextFrame

                 ldx #numFrames         ; if next frame was zero, reset to start
                 stx currFrame

nextFrame        ldx currFrame          ; get the current frame index
                 lda buttonAni,x        ; load the index to where the current frame graphic exists
                 sta char               ; store it in char for drawing

repeatFrame      jmp continue           ; skip over the color routine for button graphics

drawChar         lda char               ; give the char graphics some unique color
                 asl                    ; take char index 0-12, [hex 0-C] and shift left
                 asl                    ; to move the value into the first nibble
                 asl
                 asl
                 adc #$1a               ; add a value to normalize it into a pleasent spectrum
                 sta COLUPF             ; if char was 5, the color value will be $6a

continue         jsr loadChar           ; jump to the graphic load routine

vblankTime       lda INTIM              ; check how much time we have left in our vblank timer
                 bne vblankTime         ; use up the rest

                 lda #0                 ; stop vblank, turn on the beam
                 sta VBLANK

; end of vblank
;----------------------------------------

;----------------------------------------
; start of main kernel loop

                 ldy #27                ; use up some space at the top of the screen
topSpacer
                 sta WSYNC
                 ; ----------------------
                 dey
                 bpl topSpacer

                 ldx #charRows - 1
                 stx pf_y

                 ; pre-vout prime pf0b and pf1b (right side) for first line to distribute the load
                 lda offsetChar,x
                 tax
                 lda char_ram+2,x
                 sta pf0b
                 lda char_ram+3,x
                 sta pf1b

                 sta WSYNC
                 ; ----------------------

vout_char        ; asymetrical playfield to draw the 17 lines of
                 ; playfield graphic data, repeating each line
                 ; for 7 scanlines.

                 ; for more on asymetrical playfields, refer to the following episode
                 ; https://www.youtube.com/watch?v=lUJmDX1fd18

                 ; left
                 lda #0                 ; 2   2
                 sta PF0                ; 3   5 PF0 is not populated on the left side

                 lda char_ram+0,x       ; 4   9
                 sta pf1a               ; 3  12
                 sta PF1                ; 3  15
                 lda char_ram+1,x       ; 4  19
                 sta pf2a               ; 3  22
                 sta PF2                ; 3  25
                 ; right
                 lda pf0b               ; 2  27
                 sta PF0                ; 3  30
                 lda pf1b               ; 2  32
                 nop                    ; 2  34
                 sta PF1                ; 3  37
                 nop                    ; 2  39
                 nop                    ; 2  41
                 nop                    ; 2  43
                 lda #0                 ; 2  45
                 sta PF2                ; 3  48

                 ldy #6                 ; 2  50
charLoop
                 sta WSYNC              ; 3  53
                 ; ----------------------
                 lda #0                 ; 2   2
                 sta PF0                ; 3   5 PF0 is not populated on the left side
                 lda pf1a               ; 2   7
                 sta PF1                ; 3  10
                 lda pf2a               ; 2  12
                 sta PF2                ; 3  15
                 nop                    ; 2  17
                 nop                    ; 2  19
                 lda pf0b               ; 2  21
                 sta PF0                ; 3  24
                 nop                    ; 2  26
                 nop                    ; 2  28
                 nop                    ; 2  30
                 nop                    ; 2  32
                 nop                    ; 2  34
                 lda pf1b               ; 2  36
                 sta PF1                ; 3  39
                 lda #0                 ; 2  41
                 sta PF2                ; 3  44
                 dey                    ; 2  46
                 bpl charLoop           ;2/3 49

                 dec pf_y               ; 5  54
                 bmi vout_char_done     ;2/3 57
                 ldx pf_y               ; 2  59
                 lda offsetChar,x       ; 4  63
                 tax                    ; 2  65
                 lda char_ram+2,x       ; 4  69
                 sta pf0b               ; 3  72
                 lda char_ram+3,x       ; 4  76
                 sta pf1b               ; 3  79

                 jmp vout_char

vout_char_done
                 lda #0
                 sta PF0
                 sta PF1
                 sta PF2

; end of main kernel loop
;----------------------------------------

;----------------------------------------
; start of overscan
                 lda #2                 ; turn off the beam
                 sta VBLANK

                 ldx #70                ; set a timer for overscan which in this example starts
                 stx TIM64T             ; right after the char or button graphic is drawn

                 lda #3                 ; start with bottom row
                 sta row
rows             ldx row                ; load the current row
                 lda keys_row_mask,x    ; lod the row

rowMaskDone      sta SWCHA
                 ; wait 400 microseconds before you can read
                 ldx #6                 ; 477 mc = 6.3 sl
wait             sta WSYNC
                 ; ----------------------
                 dex
                 bne wait

                 ldx row
                 ldy rowOffset,x        ; offsets for chars index based on which row we're reading
                 ; if it's the first row, the offset will be 0, and if there
                 ; is key press on the first collumn, the char index will
                 ; remain 0. however if we're on the second row, with the
                 ; key press on the first column, the offset and char index
                 ; will be 3. if it's the second column, the char index will
                 ; be 4.

p0_col1          lda INPT0              ; if keypress char index = rowOffset
                 bmi p0_col2
                 jmp pressed            ; key press detected
p0_col2          lda INPT1              ; if keypress char index = rowOffset + 1
                 bmi p0_col3
                 iny                    ; add 1 to rowOffset
                 jmp pressed            ; key press detected
p0_col3          lda INPT4              ; if keypress char index = rowOffset + 2
                 bmi p1_col1
                 iny                    ; add 2 to rowOffset
                 iny                    ; key press detected
                 jmp pressed
p1_col1          lda INPT2              ; if keypress char index = rowOffset
                 bmi p1_col2
                 jmp pressed            ; key press detected
p1_col2          lda INPT3              ; if keypress char index = rowOffset + 1
                 bmi p1_col3
                 iny                    ; add 1 to rowOffset
                 jmp pressed            ; key press detected
p1_col3          lda INPT5              ; if keypress char index = rowOffset + 2
                 bmi nopress
                 iny                    ; add 2 to rowOffset
                 iny                    ; key press detected
pressed          lda #1
                 sta keyDown

                 sty char               ; set chat char index was calculated
                 jmp doneKeys           ; done with reading keyboards

nopress          dec row                ; no key press detected, move to next row
                 bpl rows

                 ldx #0                 ; no key presses detected
                 lda keyDown            ; check if we need to reset button animation, or continue
                 beq noButtonUpdate     ; with the currently running animation
                 stx currFrame          ; reset graphics and timing for button animation
                 stx drawTimer
noButtonUpdate   stx keyDown
doneKeys

overscanTime     ldx INTIM              ; check how much time we have left in our vblank timer
                 bne overscanTime       ; use up the rest

; end of overscan
;----------------------------------------

                 jmp vsync              ; re-synchronize vertical retrace

;----------------------------------------
; helper subroutines

charCols         equ 4
charRows         equ 17
charBuffSize     equ ((charRows) * charCols)

loadChar         SUBROUTINE
                 ldx char               ; get current lchar
                 lda charLSB,x
                 sta char_ptr
                 lda charMSB,x          ; calc rom position of char data
                 sta char_ptr+1         ; set pointer to char data
                 ldy #charBuffSize-1
.load            lda (char_ptr),y
                 sta char_ram,y
                 dey
                 bpl .load
                 rts

; -----------------------------------
; keyboard routines

pins_mask        .byte %11111111        ; all output

keys_row_mask    .byte %11101110        ; power first row
                 .byte %11011101        ; power second tow
                 .byte %10111011        ; power third row
                 .byte %01110111        ; power forth row

; ---------------------------------------
; setup data pointers

charLSB          .byte <charData01
                 .byte <charData02
                 .byte <charData03
                 .byte <charData04
                 .byte <charData05
                 .byte <charData06
                 .byte <charData07
                 .byte <charData08
                 .byte <charData09
                 .byte <charData0p
                 .byte <charData00
                 .byte <charData0s
                 .byte <buttonData01
                 .byte <buttonData02
                 .byte <buttonData03
                 .byte <buttonData04

charMSB          .byte >charData01
                 .byte >charData02
                 .byte >charData03
                 .byte >charData04
                 .byte >charData05
                 .byte >charData06
                 .byte >charData07
                 .byte >charData08
                 .byte >charData09
                 .byte >charData0p
                 .byte >charData00
                 .byte >charData0s
                 .byte >buttonData01
                 .byte >buttonData02
                 .byte >buttonData03
                 .byte >buttonData04

buttonAni        .byte 12, 13, 14, 15, 14, 13, 12

rowOffset        .byte 0, 3, 6, 9

; calculates a table of offsets to ram locations storing char data
offsetChar
off              set 0
                 repeat charRows
                 .byte off
off              set off + charCols
                 repend

; ---------------------------------------
; define character graphics as pf
; upside down going from left to right in 4 bytes per line x 17 lines
; byte 1 = pf1(left), byte 2 = pf2(left), byte 3 = pf0(right), byte 4 = pf1(right)
; the next episode will cover data structures for graphics so be sure to subscribe
; https://youtube.com/8blit?sub_confirmation=1

charData00       hex 00E0F00000F0F08000F8F0C000F8F0C000F8E0C00078C0C00078C0C00078C0C00078C0C00078C0C00078C0C00078C0C000F8E0C000F8F0C000F8F0C000F0F08000E0F000
charData01       hex 00003000000070000080F0000080F0000080F0000080F0000080F0000080F0000080F0000080F0000080F0000080F00000F0F00000F0F00000E0F00000C0700000803000
charData02       hex 00F0F00000F8F08000F8F08000F8F00000F8700000F8000000F0100000E0300000C070000080F0000000F0800000E0800038E0C00078E0C000F8F0C000F0F08000E0F000
charData03       hex 00E0F00000F0F08000F8F0C000F8C0C00078C0C00000E0800000F0800080F00000C070000080F0000000F0800000E0C00000C0C000F0F0C000F8F0C000F8F0C000F0F080
charData04       hex 00008080000080C00000C0C00000C0C00000C0C000FCF0C000FEF0C000FEF0C0003EC0C0007CC0C000F8C0C000F0D0C000E0F0C000C0F0C00080F0C00000F0C00000E080
charData05       hex 00F0F00000F8F08000FCF0C0007CE0C0003CE0C00000F0800080F08000C0F00000E0700000F8300000FC1000007C0000007C000000FCF08000FCF0C000F8F0C000F8F080
charData06       hex 00F0F00000F8F08000FCF0C0007CC0C0003CC0C0003CC0C0003CE0C000FCF0C000FCF08000FCF000003C0000003CC080003CC0C0007CE0C000FCF0C000F8F08000F0F000
charData07       hex 00E0000000F0000000F0100000F0100000E0100000C0300000C0700000807000008070000080F0000000F0000000E0800000E0C000F0F0C000F8F0C000F8F08000F0F080
charData08       hex 00F0F00000F8F08000FCF0C0007CE0C0003CC0C0003CC0C0007CE0C000F8F08000F0F00000F8F080007CE0C0003CC0C0003CC0C0007CE0C000FCF0C000F8F08000F0F000
charData09       hex 00F0F00000F8F08000FCF0C0007CE0C0003CC0C00038C0C00000C0C000F0F0C000F8F0C000FCF0C0007CC0C0003CC0C0003CC0C0003CE0C000FCF0C000F8F08000F0F000
charData0p       hex 0018C0000038C0800078E0800078E08000FEF0F000FFF0F000FFF0E00078E0800078E0800078E08000FEF0F000FFF0F000FFF0E00078E0800078E0800038C0800018C000
charData0s       hex 001880800038C080003CC0C0007CE0C000FCF0C000F8F08000F0F00000E0700000C0300000E0700000F0F00000F8F08000FCF0C0007CE0C0003CC0C00038C08000188080
buttonData01     hex 00C07000003880C00004002000C27010003A80D0000600300002001000040020001800C000E0F00000000000000000000000000000000000000000000000000000000000
buttonData02     hex 00C07000003880C000C47020003A80D0000600300002001000040020001800C000E0F0000000000000000000000000000000000000000000000000000000000000000000
buttonData03     hex 00C0700000F8F0C0003C80E0000600300002001000040020001800C000E0F000000000000000000000000000000000000000000000000000000000000000000000000000
buttonData04     hex 00C07000003880C0000400200002001000040020001800C000E0F00000000000000000000000000000000000000000000000000000000000000000000000000000000000

;----------------------------------------
; define interupts

                 org $fffa
                 .word reset            ; NMI  ($fffa)
                 .word reset            ; RESET ($fffc)
                 .word reset            ; IRQ ($fffe)
