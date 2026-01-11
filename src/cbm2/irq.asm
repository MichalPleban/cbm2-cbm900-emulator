
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
        beq @acia
        
        cmp #$10
        beq @acia
        
        ; Re-enable IRQ to allow servicing higher priority ACIA interrupts
        cli
        cld
        cmp #$04
        bne @end

        ; Scan keyboard
        jsr kbd_scan
        
        ; Update VGA screen
        bit screen_charset
        bpl @no_vga
        jsr vga_check_mirror
@no_vga:
        
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

        ; Clear CIA interrupt flag. 
        ldy #13
        lda (CIA),y
                
        jmp @end
                
@acia:
        cld
        jsr serial_irq
        
@end:
        ; Clear TPI pending interrupt 
        ldy #7
        sta (TPI1),y
                
        ; Restore registers
        pla
        sta IND_REG
        pla
        tay
        pla
        tax
        pla
        rti
