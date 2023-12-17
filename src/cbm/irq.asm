
irq_init:
        lda #<irq_handler
        sta $FFFE
        lda #>irq_handler
        sta $FFFF
.ifdef DEBUG
        lda #25
        sta irq_50hz
.endif
        rts

irq_handler:

; Save registers
        sta irq_save_a
        stx irq_save_x
        sty irq_save_y
        lda IND_REG
        sta irq_save_ind
        lda #$0F
        sta IND_REG

; Check TPI interrupt mask
        ldy #$07
        lda (TPI1), y

; Scan keyboard on 50Hz interrupt
        lsr a
        bcc @not_50hz
        jsr kbd_scan
.ifdef DEBUG
        dec irq_50hz
        beq @do_50hz
        jmp @end
@do_50hz:
        lda #25
        sta irq_50hz
.endif
        jsr cio_timer
        jmp @end
@not_50hz:

@end:
; Clear TPI pending interrupt 
        ldy #$07
        sta (TPI1), y

; Restore registers
        lda irq_save_ind
        sta IND_REG
        ldy irq_save_y
        ldx irq_save_x
        lda irq_save_a
        rti
