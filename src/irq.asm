
irq_init:
        lda #<irq_handler
        sta $FFFE
        lda #>irq_handler
        sta $FFFF
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
        beq @end

;        inc $FF
;        lda $FF
;        jsr screen_output

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
