; S06E01 Optimizing Atari 2600 Data Structures for Graphics - Example 5
;
; The Atari 2600 is severely limited in resources, so optimizing your data structures so you can
; draw graphics in tight RAM/ROM constraints within only 76 machine cycles per scanline is
; critical. This episode covers the foundational basics of Atari 2600 kernel development that
; developers can build upon for their own kernels.
;
; Switching from player graphics to playfield graphics, this example demonstrates how to store the
; graphics for the playfield in byte tables by register. The bytes are shown twice: once in binary
; format for clarity, and once in hex format for easy copy-pasting and a smaller code footprint.
;
; You can grab a copy of the spreadsheet used in this episode from here :
; https://docs.google.com/spreadsheets/d/1OqW7LrnDes31m5Tj24O4OwcgnnVEWINkcUMx8B-bGoA/template/preview
;
; This Episode on Youtube - https://youtu.be/jjPdUFzuI40
;
; Become a Patron - https://patreon.com/8blit
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; 8blit Merch - https://8blit.myspreadshop.com/
; Join us on Discord - https://discord.gg/KD3ff9qMR7
; Visit the Website - https://www.8blit.com

                 processor 6502
                 include "vcs.h"
                 include "macro.h"

; constants
PFCOL            equ 44                 ; color of the playfield
VOUTTOP          equ 5                  ; top space buffer in vout
VOUTBOTTOM       equ 5                  ; bottom space buffer in vout

                 seg.u zeropage         ; start of zero page ram
                 org $80

temp             ds 1

                 seg rom                ; start of rom
                 org $f000

reset            CLEAN_START

                 lda #PFCOL
                 sta COLUPF

frame            VERTICAL_SYNC
                 ldx #(37 * 76) / 64
                 stx TIM64T

                 lda #%00000001
                 sta CTRLPF

vblank           lda INTIM              ; burn any unused cycles on the timer
                 bne vblank

                 sta WSYNC
                 lda #%00000000
                 sta VBLANK

                 ldy #VOUTTOP
top_blank        sty WSYNC
                 ;------------------------
                 dey
                 bpl top_blank

                 ldy #0                 ; y = data index (0 to 32 for 33 lines)
                 ldx #0                 ; x = repeat counter (0 to 2 for 3 scanlines)

vout             sta WSYNC              ; start new scanline (76 CPU cycles)
                 ;------------------------

                 lda PF1a,y             ; load PF1 left
                 sta PF1                ; store to PF1
                 lda PF2a,y             ; load PF2 left
                 sta PF2                ; store to PF2

                 nop                    ; waste some machine cycles for timing
                 nop
                 nop
                 nop
                 nop
                 nop
                 nop
                 nop
                 nop
                 nop
                 nop
                 dec temp

                 lda PF2b,y             ; load PF2 right
                 sta PF2                ; store to PF2
                 ; right side playfield
                 lda PF1b,y             ; load PF1 right
                 sta PF1                ; store to PF1
                 ; update repeat counter
                 inx                    ; increment repeat counter
                 cpx #18                ; check if repeated 3 times
                 bne vout               ; no, repeat same data
                 ; move to next data row
                 ldx #0                 ; reset repeat counter
                 iny                    ; increment data index
                 cpy #10                ; check if done with all 33 rows
                 bne vout               ; loop until 33 rows

                 ; clear playfield registers
                 lda #0
                 sta PF1
                 sta PF2

                 ldy #VOUTBOTTOM
bottom_blank     sty WSYNC
                 ;------------------------
                 dey
                 bpl bottom_blank

                 lda #%00000010
                 sta VBLANK
                 ldx #(30 * 76) / 64
                 stx TIM64T

overscan_loop    lda INTIM
                 bne overscan_loop

                 jmp frame

; binary encoded
; ----------------
PF1a             .byte %00000000
                 .byte %00000000
                 .byte %00000111
                 .byte %00000111
                 .byte %00000000
                 .byte %00000000
                 .byte %00000000
                 .byte %00000000
                 .byte %00000111
                 .byte %00000000

PF2a             .byte %11111000
                 .byte %11111111
                 .byte %11000111
                 .byte %11111111
                 .byte %00111111
                 .byte %11111000
                 .byte %11111000
                 .byte %11000111
                 .byte %11000000
                 .byte %00000000

PF2b             .byte %11110000
                 .byte %11111110
                 .byte %10001110
                 .byte %11111110
                 .byte %01110000
                 .byte %11110000
                 .byte %11110000
                 .byte %10001110
                 .byte %10000001
                 .byte %01110000

PF1b             .byte %00000000
                 .byte %00000000
                 .byte %00000000
                 .byte %00000000
                 .byte %00000000
                 .byte %00000000
                 .byte %00000000
                 .byte %00000000
                 .byte %00000011
                 .byte %00000000

; hex encoded
; -------------
;PF1a hex 00000707000000000700
;PF2a hex F8FFC7FF3FF8F8C7C000
;PF2b hex F0FE8EFE70F0F08E8170
;PF1b hex 00000000000000000300

                 org $fffa
                 .word reset
                 .word reset
                 .word reset
