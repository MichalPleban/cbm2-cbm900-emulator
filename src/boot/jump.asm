
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

cold_reset:
        lda CHIPSET_BASE + REG_IO_PINS
        and #($FF - IO_BANK)
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 0
        jmp $0400

warm_reset:
        lda CHIPSET_BASE + REG_IO_PINS
        and #($FF - IO_BANK)
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 0
        jmp $0403

        lda CHIPSET_BASE + REG_IO_PINS
        and #($FF - IO_BANK)
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 0
        jmp $0406

        lda CHIPSET_BASE + REG_IO_PINS
        and #($FF - IO_BANK)
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 0
        jmp $0409

.res ($2000-*),$FF
