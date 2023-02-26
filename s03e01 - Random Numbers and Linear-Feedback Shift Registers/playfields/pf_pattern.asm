PF_col_pattern 
        .byte #$0E      ; foreground
        .byte #$02      ; background

PF0_data_pattern
        .byte #%11110000 ;<- first
        .byte #%00010000 
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%11111111 ;<- last

PF1_data_pattern
        .byte #%11111111 ;<- first
        .byte #%00000000 
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%01000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000010
        .byte #%00000000
        .byte #%00001000
        .byte #%00000000
        .byte #%00000000
        .byte #%01000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%11111111 ;<- last

PF2_data_pattern
        .byte #%11111111 ;<- first
        .byte #%00000000 
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00100000
        .byte #%00100001
        .byte #%00100000
        .byte #%00100000
        .byte #%00100000
        .byte #%00100000
        .byte #%00100000
        .byte #%00100000
        .byte #%00100000
        .byte #%00100000
        .byte #%00100000
        .byte #%00100001
        .byte #%00100000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%11111111 ;<- last        
