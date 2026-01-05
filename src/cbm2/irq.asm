
; 100 Hz counter constant
COUNTER = 20000 

irq_init:
        ; Set up IRQ handler vector at the top of RAM
        lda #<irq_handler
        sta $FFFE
        lda #>irq_handler
        sta $FFFF
        
        ; Set CIA timer A to 100 Hz
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

irq_restart:
        ldy #13
        lda #$81
        sta (CIA),y
        lda (CIA),y
        rts
        
irq_handler:

        ; Save registers
        cld
        pha
        txa
        pha
        tya
        pha
        lda IND_REG
        pha
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
        
        ; Re-enable IRQ to allow servicing higher priority ACIA interrupts
        cli
        
        ; Scan keyboard
        jsr kbd_scan
        
        jsr vga_check_mirror
        
        ; Issue timer IRQ to the Z8000
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
        jsr serial_irq
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
        pla
        sta IND_REG
        pla
        tay
        pla
        tax
        pla
        rti
