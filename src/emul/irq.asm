

irq_handle:

; Show debug banner if necessary
.ifdef DEBUG
        jsr irq_debug_start
.endif

        ; Determine the source of the IRQ
        bit timer_irq_pending
        bpl @not_timer
        lda timer_irq_vector
        jmp @finish
@not_timer:
        bit scc_irq_pending
        bpl @not_serial_in
        lda #$00
        ldx kbd_head
        cpx kbd_tail
        beq @not_kbd
        lda #$04
        bne @do_serial_irq
@not_kbd:
        ldx serial_head
        cpx serial_tail
        beq @do_serial_irq
        lda #$0C
@do_serial_irq:
        clc
        adc scc_irq_vector
        jmp @finish
@not_serial_in:
        bit disk_irq
        bpl @nothing
        jsr disk_clear
        lda #$80
        bne @finish
@nothing:
        lda #$FF
@finish:
        sta z8000_data
        
; Finish showing debug info
.ifdef DEBUG
        jsr irq_debug_end
.endif

        ; Output the value to the Z8000 data bus
        ldy #REG_DATA
        lda z8000_data
        sta (CHIPSET),y

        jmp nmi_finish

.ifdef DEBUG
        
irq_debug_start:
        lda #<debug_banner_irq
        ldy #>debug_banner_irq
        jmp serial_string

irq_debug_end:
        lda z8000_data
        jsr debug_hex
        lda #$0D
        jsr serial_output
        lda #$0A
        jmp serial_output
        
.endif
        
irq_issue:
        ldy #REG_CONTROL
        bit timer_irq_pending
        bmi @set
        bit scc_irq_pending
        bmi @set
        bit disk_irq
        bmi @set
        lda (CHIPSET),y
        and #<~CTRL_VI
        sta (CHIPSET),y
        rts
@set:
        lda (CHIPSET),y
        ora #CTRL_VI
        sta (CHIPSET),y
        rts
        
        
        
debug_banner_irq:
        .byte "IRQ ", 0
