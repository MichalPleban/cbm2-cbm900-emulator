
.include "defs.asm"

.code

.ifdef PRG
.byt $00, $04
.endif

.org $0400
        jmp wedge_start
        jmp wedge_warm
        jmp wedge_irq
        jmp wedge_nmi

wedge_start:
        sei
        jsr init_irq
        jsr jump_bas_init_1
        jsr jump_bas_init_2
        lda IndReg
        pha
        jsr detect_basic
        bit basic_type
        bpl @banner_128
        lda #<banner_256
        ldy #>banner_256
        bne @banner_256
@banner_128:
        lda #<banner_128
        ldy #>banner_128
@banner_256:
        jsr print_string
        lda #<banner_wedge
        ldy #>banner_wedge
        jsr print_string
        jsr setup_warmstart
        jsr setup_wedge_irq
        pla
        sta IndReg
        cli
        jmp jump_bas_init_3

wedge_warm:
        cli
        jmp jump_8003
        
; --------------------------------------------------------
; BASIC type detection (basic_type bit 7 = 0 - BASIC 128)
; --------------------------------------------------------
    
detect_basic:
        lda #$0F
        sta IndReg
        lda #$01
        sta mem_ptr
        lda #$80
        sta mem_ptr+1
        ldy #$00
        lda (mem_ptr),y
        sta basic_type
        rts        

; --------------------------------------------------------
; IRQ handler routines in bank 0 - redirect to bank 15
; --------------------------------------------------------
                
init_irq:
        lda #<IRQ
        sta $FFFE
        lda #>IRQ
        sta $FFFF
        lda #<NMI
        sta $FFFA
        lda #>NMI
        sta $FFFB
        rts

IRQ:
        jsr jump_irq
        rti
NMI:
        jsr jump_nmi
        rti

; --------------------------------------------------------
; Set up warm start at $102B
; --------------------------------------------------------

setup_warmstart:
        lda #$F8
        sta mem_ptr
        lda #$03
        sta mem_ptr+1
        ldy #0
        lda #$2f
        sta (mem_ptr),y
        iny
        lda #$10
        sta (mem_ptr),y
        iny
        lda #$a5
        sta (mem_ptr),y
        iny
        lda #$5a
        sta (mem_ptr),y
        rts

; --------------------------------------------------------
; Custom IRQ handler
; --------------------------------------------------------

setup_wedge_irq:
        lda #$03
        sta mem_ptr+1
        lda #$00
        sta mem_ptr
        tay
        lda #$10
        sta (mem_ptr),y
        iny
        lda #$11
        sta (mem_ptr),y
        rts
                
wedge_irq:
        jmp jump_irq_handle
        
wedge_nmi:
        jmp jump_rti

; --------------------------------------------------------
; Print null terminated string
; --------------------------------------------------------

print_string:
        sta screen_ptr
        sty screen_ptr+1
@loop:
        ldx #0
        lda (screen_ptr,x)
        beq @end
        jsr jump_bsout
        inc screen_ptr
        bne @loop
        inc screen_ptr+1
        bne @loop
@end:
        rts

; --------------------------------------------------------
; Startup banners
; --------------------------------------------------------

banner_256:
        .byt $93, "*** commodore basic 256, v4.0 ***", $0D, 0
banner_128:
        .byt $93, "*** commodore basic 128, v4.0 ***", $0D, 0
banner_wedge:
        .byt "dummy wedge installed in bank 0", $0D, 0

; --------------------------------------------------------
; Return from bank 15 call - set Z flag accordingly
; --------------------------------------------------------

.res ($1100-*),$FF

CallReturn:
        beq @zero
        ; Zero flag not set
        ; $00 contains $00 - incrementing will yield $FF with Z=0
        dec $00
        ; Continued from bank 15 - no need to do anything
        rts
@zero:
        ; Zero flag set
        dec $00
        ; Continued from bank 15 - need to set zero flag
        ; Save A value
        sta acc_save
        ; Set A to $00 to ensure Z=1
        lda #$00
        ; Push flags with Z=1
        php
        ; Restore old A value
        lda acc_save
        ; Restore flags with Z=1
        plp
        rts
                
.res ($1120-*),$FF

.macro  CALL address
        dec $00
        jsr address
        jmp CallReturn
.endmacro

.macro  JUMP address
        dec $00
        jmp address
        nop
        nop
        nop
.endmacro

jump_reset:
        CALL $0400+3*0          ; Initialize wedge
jump_warm_start:
        CALL $0400+3*1          ; READY prompt [not implemented yet]
jump_bas_init_1:
        JUMP $0400+3*2          ; Custom IRQ handler
jump_bas_init_2:
        JUMP $0400+3*3          ; Custom NMI handler
jump_bas_init_3:
        CALL $0400+3*4
jump_irq:
        CALL $0400+3*5
jump_nmi:
        CALL $0400+3*6
jump_irq_handle:
        CALL $0400+3*7
jump_irq_end:
        CALL $0400+3*8
jump_rti:
        CALL $0400+3*9
jump_8003:
        CALL $0400+3*10
jump_bsout:
        CALL $0400+3*11       
        
.ifdef PRG
.res 16, $AA
.endif

