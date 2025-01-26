

emul_init:
        lda #<nmi_handler
        sta $FFFA
        lda #>nmi_handler
        sta $FFFB
        jsr cio_init
        jsr scc_init
        jsr disk_init
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
        ldy #REG_CODE_HI
@copy:
        lda (CHIPSET), y
        sta z8000_addr, y
        dey
        bpl @copy

        ; Is it a I/O read?
        bit z8000_status
        bvs @continue
        jmp irq_handle

@continue:
        
; Show debug banner if necessary
.ifdef DEBUG
        jsr debug_start
        lda #$00
        sta io_unimplemented
.endif

        dec z8000_addr+1
        bpl @not_cio
        bit z8000_addr
        bmi @cio2
        jmp cio_handle
@cio2:        
        jmp cio2_handle
@not_cio:
        dec z8000_addr+1
        bpl @not_scc
        jmp scc_handle
@not_scc:
        dec z8000_addr+1
        bpl @not_200
        jsr undefined
        jmp nmi_end
@not_200:
        dec z8000_addr+1
        bpl @not_300
        jsr undefined
        jmp nmi_end
@not_300:
        dec z8000_addr+1
        bpl @not_400
        jsr undefined
        jmp nmi_end
@not_400:
        dec z8000_addr+1
        bpl @not_500
        lda z8000_data
        beq @disk_clear
        lda #$80
        sta disk_request
        jmp nmi_end
@disk_clear:
        jsr disk_clear
        jmp nmi_end
@not_500:
        jsr undefined
        
nmi_end:

; Finish showing debug banner
.ifdef DEBUG
        jsr debug_end
.endif

; Restore registers
        ldy #REG_DATA
        bit z8000_status
        bpl @notread
        ; Output the value to the Z8000 data bus
        lda z8000_data
        sta (CHIPSET),y
@notread:        
        
nmi_finish:
        ; Check if interrupts were enabled when NMI handler was called.
        pla
        pha
        and #$04
        bne @no_irq
        ; If yes, allow IRQ handler so that it is not starved.
        cli
        nop
        sei
@no_irq:
        ldy #REG_STATUS
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
        lda z8000_code+1
        jsr debug_hex
        lda z8000_code
        jsr debug_hex
        lda #':'
        jsr serial_output
        lda #' '
        jsr serial_output
        bit z8000_status
        bpl @write
        lda #<debug_banner_in
        ldy #>debug_banner_in
        bne @output
@write:
        lda #<debug_banner_out
        ldy #>debug_banner_out
@output:
        jsr serial_string
        lda z8000_addr+1
        jsr debug_nibble
        lda z8000_addr
        jsr debug_hex
        lda #','
        jsr serial_output
        lda #' '
        jsr serial_output
        bit z8000_status
        bmi @end
        lda z8000_data
        jsr debug_hex
        lda #' '
        jsr serial_output
@end:
        rts

; Finish outputting information about I/O operation
debug_end:
        bit z8000_status
        bpl @write
        lda z8000_data
        jsr debug_hex
        lda #' '
        jsr serial_output
@write:
        bit io_unimplemented
        bpl @end
        lda #'*'
        jsr serial_output
@end:
        lda #$0D
        jsr serial_output
        lda #$0A
        jmp serial_output
        
debug_banner_in:
        .byte "IN  ", 0
debug_banner_out:
        .byte "OUT ", 0

.endif

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
        jmp serial_output

hex_chars:
        .byte "0123456789ABCDEF"

.include "emul/cio.asm"
.include "emul/cio2.asm"
.include "emul/scc.asm"
.include "emul/disk.asm"
.include "emul/irq.asm"
