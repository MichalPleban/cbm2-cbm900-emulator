

emul_init:
        lda #<nmi_handler
        sta $FFFA
        lda #>nmi_handler
        sta $FFFB
        rts
        
nmi_handler:

; Save registers
        sta nmi_save_a
        stx nmi_save_x
        sty nmi_save_y
        lda IND_REG
        sta nmi_save_ind
        lda #$0F
        sta IND_REG

; Copy Z8000 status from the chipset register
        ldy #3
@copy:
        lda (CHIPSET), y
        sta z8000_addr, y
        dey
        bpl @copy

; Show debug banner if necessary
.ifdef DEBUG
        jsr debug_start
        lda #$00
        sta io_unimplemented
.endif

        dec z8000_addr+1
        bpl @not_cio
        jsr undefined
        jmp nmi_end
@not_cio:
        dec z8000_addr+1
        bpl @not_scc
        jmp scc_handle
@not_scc:

nmi_end:

; Finish showing debug banner
.ifdef DEBUG
        jsr debug_end
.endif

; Restore registers
        ldy #$02
        bit z8000_status
        bpl @notread
        ; Output the value to the Z8000 data bus
        lda z8000_data
        sta (CHIPSET),y
@notread:        
        iny
        lda nmi_save_ind
        sta IND_REG
        ldx nmi_save_x
        lda nmi_save_a
        ; Acknowledge NMI & bring down the WAIT line
        sta (CHIPSET),y
        ldy nmi_save_y
        rti

io_handle:
        jmp (io_jump)

empty:
        rts
                
undefined:
.ifdef DEBUG
        lda #$80
        sta io_unimplemented
.endif
        rts
        
.ifdef DEBUG

; Output information about I/O pending operation
debug_start:
        bit z8000_status
        bpl @write
        lda #<debug_banner_in
        ldy #>debug_banner_in
        bne @output
@write:
        lda #<debug_banner_out
        ldy #>debug_banner_out
@output:
        jsr screen_string
        lda z8000_addr+1
        jsr debug_nibble
        lda z8000_addr
        jsr debug_hex
        lda #','
        jsr screen_output
        lda #' '
        jsr screen_output
        bit z8000_status
        bmi @end
        lda z8000_data
        jsr debug_hex
        lda #' '
        jsr screen_output
@end:
        rts

; Finish outputting information about I/O operation
debug_end:
        bit z8000_status
        bpl @write
        lda z8000_data
        jsr debug_hex
        lda #' '
        jsr screen_output
@write:
        bit io_unimplemented
        bpl @end
        lda #'*'
        jsr screen_output
@end:
        lda #$0D
        jmp screen_output
        

; Output hexadecimal character to screen
; Input: A = hex number
; Destroyed: A, X, Y
debug_hex:
        pha
        lsr a
        lsr a
        lsr a
        lsr a
        jsr debug_nibble
        pla
debug_nibble:
        and #$0F
        tax
        lda hex_chars, x
        jmp screen_output

hex_chars:
        .byte "0123456789ABCDEF"

debug_banner_in:
        .byte "IN  ", 0
debug_banner_out:
        .byte "OUT ", 0

.endif

.include "emul/scc.asm"
