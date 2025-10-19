

.ifdef PRG
.include "../cbm2/defs.asm"
.include "../chipset.asm"
.data
.byt $00, $10
.endif

.code
.org $1000

; --------------------------------------------------------
; Cold and warm start
; --------------------------------------------------------

        jmp cold_reset
        jmp warm_reset
.byt $43, $C2, $CD, $31

; --------------------------------------------------------
; Routines to run code in the first bank
; --------------------------------------------------------

        ; Cold reset in EPROM page 0
cold_reset:
        sei
        lda CHIPSET_BASE + REG_IO_PINS
        and #($FF - IO_BANK)
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 0 (cold reset)
        nop
        nop
        nop

        ; Warm reset in EPROM page 0
warm_reset:
        sei
        lda CHIPSET_BASE + REG_IO_PINS
        and #($FF - IO_BANK)
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 0 (warm reset)
        nop
        nop
        nop

        ; BASIC prompt in EPROM page 1
        sei
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        jmp InitBASICEnd

        ; Start monitor in EPROM 1
        sei
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        jmp $1500

        ; CBMLINK in EPROM page 1
        sei
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        jmp StartSerial

; --------------------------------------------------------
; Show BASIC prompt
; --------------------------------------------------------

InitBASICEnd:
        cli
        jsr $1300
        bit $8001
        bpl InitBASICEnd128
        
        jmp $85b8
InitBASICEnd128:
        jmp $85c0
        

; --------------------------------------------------------
; CBMLINK launch
; --------------------------------------------------------
StartSerial:
        ldx #0
StartSerial1:
        lda CbmLinkSerial,x
        sta $0400, x
        lda CbmLinkSerial+256,x
        sta $0500,x
        inx
        bne StartSerial1
        cli
        jmp $0400

CbmLinkSerial:
        .incbin "cbmlink.bin"

        
.res ($1300-*),$FF
.incbin "bin/wedge.bin"

.res ($1500-*),$FF
.incbin "bin/moni.bin"
                
.res ($2000-*),$FF


