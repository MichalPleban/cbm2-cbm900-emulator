
; 100 Hz counter constant
COUNTER = 20000 

irq_init:
        lda #<irq_handler
        sta $FFFE
        lda #>irq_handler
        sta $FFFF
        ldy #4
        lda #<COUNTER
        sta (CIA),y
        iny
        lda #>COUNTER
        sta (CIA),y
        ldy #14
        lda #$11
        sta (CIA),y
        ldy #13
        lda #$81
        sta (CIA),y
        lda (CIA),y
.ifdef DEBUG
        lda #25
        sta irq_delay
.endif
        ; Enable only IRQ from CIA and ACIA
        ldy #5
        lda #$14
        sta (TPI1),y
        ; Enable IRQ priority
        iny
        lda (TPI1),y
        and #$F0
        ora #$03
        sta (TPI1),y
        rts

irq_handler:

        ; Save registers
        cld
        sta irq_save_a
        stx irq_save_x
        sty irq_save_y
        lda IND_REG
        sta irq_save_ind
        lda #$0F
        sta IND_REG

        ; Check TPI interrupt mask
        ldy #7
        lda (TPI1),y
        pha
        
        lsr a
        bcc @not_60hz
        jmp @end
@not_60hz:
        lsr a
        bcc @not_srq
        jmp @end
@not_srq:
        lsr a
        bcc @not_cia
        
        ; Scan keyboard
        jsr kbd_scan
        
        ; Issue timer IRQ to the Z800
.ifdef DEBUG
        dec irq_delay
        bne @no_timer
        lda #25
        sta irq_delay
.endif
        jsr cio_timer
@no_timer:
        lda timer_irq_enable
        
        jmp @end
@not_cia:
        lsr a
        bcc @acia
        jmp @end
@acia:

@end:
        ; Clear TPI pending interrupt 
        ldy #7
        sta (TPI1),y
        
        ; Delayed clearing of CIA interrupt flag. 
        ; If the flag is cleared earlier, an NMI in the middle of the IRQ handler will cause a race condition
        ; that at some point causes the flag to not be cleared properly and the CIA IRQs get disabled.
        pla
        cmp #$04
        bne @not_cia_again
        ldy #13
        lda (CIA),y
@not_cia_again:

        ; Restore registers
        lda irq_save_ind
        sta IND_REG
        ldy irq_save_y
        ldx irq_save_x
        lda irq_save_a
        rti
