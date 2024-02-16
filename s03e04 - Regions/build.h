    IFNCONST REGIONPARAM
REGION          = PAL_SECAM        ; default targted region
    ELSE
REGION          = REGIONPARAM   ; target region supplied by the dasm assembler (see build.bat)
    ENDIF


; available regions
NTSC			= 1
PAL 			= 2
PAL_SECAM       = 3
SECAM 			= 4

; region scanlines
    IF REGION = NTSC
VBLANKLINES     = 37         
VOUTLINES       = 96            ; height of our 2lk kernel playfield 192/2
OVERSCANLINES   = 30
PFSEGHEIGHT     = %00001111     ; pf segements are 4 kernel lines in height
    ELSE
; PAL and SECAM use the same timings    
VBLANKLINES     = 36         
VOUTLINES       = 120           ; height of our 2lk kernel playfield 240/2
OVERSCANLINES   = 33
PFSEGHEIGHT     = %00011111     ; pf segements are 5 kernel lines in height
    ENDIF

; calculate timings
VBLANKTIME      = (VBLANKLINES * 76) / 64 
OVERSCANTIME    = (OVERSCANLINES * 76) / 64 
	
; region color
    IF REGION = NTSC
RED             = $46
ORANGE          = $3c
YELLOW          = $1e
BLUE            = $a6
    ECHO "REGION NTSC"
    ENDIF

    IF REGION = PAL
RED             = $66
ORANGE          = $2a
YELLOW          = $2e
BLUE            = $b4
    ECHO "REGION PAL"
    ENDIF    

; PAL carts will also work on SECAM consoles. If you want to support SECAM and PAL on the same cart you need
; to adjust the first nybble to match with one of the 8 SECAM colors.
    IF REGION = PAL_SECAM
RED             = $64
ORANGE          = $26
YELLOW          = $1c
BLUE            = $b2
    ECHO "REGION PAL_SECAM"
    ENDIF

; If you're specifically targetting a SECAM audience then assign your colours based on the 8 available with the top nybble being 0.
; These will display as black and white if used with a PAL console.
    IF REGION = SECAM
RED             = $04
ORANGE          = $06
YELLOW          = $0c
BLUE            = $02
    ECHO "REGION SECAM"
    ENDIF
   
; Give a little feedback about our target during build   
    ECHO "VSYNC 3"
    ECHO "VBLANK", [VBLANKLINES]d
    ECHO "VOUT", [VOUTLINES]d
    ECHO "OVERSCAN", [OVERSCANLINES]d
