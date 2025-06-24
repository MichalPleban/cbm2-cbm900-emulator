
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
        jmp jump_wedge_1
.byt $43, $C2, $CD, $31

; --------------------------------------------------------
; Routines to run code in the first bank
; --------------------------------------------------------

        ; Cold reset in bank 0
cold_reset:
        sei
        lda CHIPSET_BASE + REG_IO_PINS
        and #($FF - IO_BANK)
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 0 (cold reset)
        nop
        nop
        nop

        ; Warm reset in bank 0
warm_reset:
        sei
        lda CHIPSET_BASE + REG_IO_PINS
        and #($FF - IO_BANK)
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 0 (warm reset)
        nop
        nop
        nop

        ; Wedge start in bank 1 - points to wedge function #0
        sei
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        jmp jump_wedge_0

        ; Warm rest in bank 1 - points to wedge function #1
        sei
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        jmp jump_wedge_1

; --------------------------------------------------------
; Initialize BASIC (first part)
; --------------------------------------------------------

InitBASICStart:
        bit $8001
        bpl Init128_

Init256_:
        jsr $bb29
        ldx #2
Init256l1_:
        lda $b460,x
        sta $02,x
        dex
        bpl Init256l1_
        sta $61
        ldx #4
Init256l2_:
        lda $bb34,x
        sta $0259,x
        dex
        bne Init256l2_
        jsr InitCommon
        jsr $b9f5
        jsr $b9ee
Init256l2b_:
        ldy #0
        tya
        sta ($2d),y
        inc $2d
        bne Init256l3_
        inc $2e
Init256l3_:
        rts

Init128_:
        jsr $bbbc
        ldx #2
Init128l1_:
        lda $b4fe,x
        sta $02,x
        dex
        bpl Init128l1_
        sta $61
        ldx #4
Init128l2_:
        lda $bbc7,x
        sta $0259,x
        dex
        bne Init128l2_
        jsr InitCommon
        jsr $ba93
        jsr $ba8c
        jmp Init256l2b_

InitCommon:
        stx $78
        stx $1a
        stx $16
        stx $0258
        stx $1d
        dex
        stx $1e
        stx $1f
        inx
        stx $31
        ldx #$80
        stx $32
        sec
        jsr $ff9c
        stx $39
        sty $3a
        stx $35
        sty $36
        stx $2d
        sty $2e
        rts
        
; --------------------------------------------------------
; Initialize BASIC (second part)
; --------------------------------------------------------

InitBASICMiddle:
        ; Need to save the stack pointer because the BASIC routine changes it
        tsx
        stx $FF
        bit $8001
        bpl InitBASICMiddle128
        jsr $8a12 
InitBASICMiddleFinish:
        ldx #$39
        ldy #$bb
        jsr $ff6f
        ldx $FF
        txs
        rts
InitBASICMiddle128:        
        jsr $8a2b 
        jmp InitBASICMiddleFinish

; --------------------------------------------------------
; Initialize BASIC (third part)
; --------------------------------------------------------

InitBASICEnd:
        bit $8001
        bpl InitBASICEnd128
        
        jmp $85b8
InitBASICEnd128:
        jmp $85c0
        
; --------------------------------------------------------
; Call the original IRQ & NMI routines
; --------------------------------------------------------

CallIRQ:
        php
        nop
        nop
        nop
        nop
        nop
        ; This must be a JSR, so that the IRQ routine can properly get the flags from the stack
        ;  and determine whether this is an IRQ or a BRK.
        jsr do_CallIRQ
        rts       
CallNMI:
        php
        jmp ($FFFB)

do_CallIRQ:
        jmp ($FFFE)

do_rti:
        rti

        

; --------------------------------------------------------
; Return from bank 0 call - set Z flag accordingly
; --------------------------------------------------------

.res ($1100-*),$FF

CallReturn:
        beq @zero
        ; Zero flag not set
        ; $00 contains $0F - incrementing will yield $10 with Z=0
        inc $00
        ; Continued from bank 0 - no need to do anything
        rts
@zero:
        ; Zero flag set
        inc $00
        ; Continued from bank 0 - need to set zero flag
        ; Decrement $01 value to yield $00 with Z=1
        dec @one
        rts
@one:
        .byt $01
        
; --------------------------------------------------------
; IRQ handler stub
; --------------------------------------------------------

.res ($1110-*),$FF

        nop
        lda $01
        pha
        cld
        lda $DE07
        beq @irq_end
        jmp jump_wedge_2
@irq_end:
        jmp $FCA2

; --------------------------------------------------------
; Calls from bank 0 
; --------------------------------------------------------

.res ($1120-*),$FF

.macro  CALL address
        inc $00
        jsr address
        jmp CallReturn
.endmacro

.macro  JUMP address
        inc $00
        jmp address
        nop
        nop
        nop
.endmacro

jump_wedge_0:
        CALL cold_reset
jump_wedge_1:
        CALL warm_reset
jump_wedge_2:
        CALL InitBASICStart
jump_wedge_3:
        CALL InitBASICMiddle
jump_wedge_4:
        CALL InitBASICEnd
jump_wedge_5:
        CALL CallIRQ
;        CALL Test
jump_wedge_6:
        CALL CallNMI        
jump_wedge_7:
        JUMP $FBF5              ; IRQ handler start
jump_wedge_8:
        JUMP $FC9F              ; IRQ handler end
jump_wedge_9:
        JUMP do_rti             ; Simple RTI instruction
jump_wedge_10:
        JUMP $8003              ; Warm reset
jump_wedge_11:
        CALL $FFD2              ; BSOUT
        
        
                
.res ($2000-*),$FF


