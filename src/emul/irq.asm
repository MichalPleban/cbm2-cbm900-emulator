

irq_handle:

; Show debug banner if necessary
.ifdef DEBUG
        jsr irq_debug_start
.endif

        bit timer_irq_pending
        bpl @not_timer
        lda timer_irq_vector
        jmp @finish
@not_timer:
        bit scc_irq_pending
        bpl @not_serial_in
        lda scc_irq_vector
        clc
        adc #4
        jmp @finish
@not_serial_in:
;        jsr disk_clear
        lda #$80
@finish:
        sta z8000_data
        
; Finish showing debug info
.ifdef DEBUG
        jsr irq_debug_end
.endif

        ; Output the value to the Z8000 data bus
        ldy #2
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
        ldy #6
        bit timer_irq_pending
        bmi @set
        bit scc_irq_pending
        bmi @set
        bit disk_irq
        bmi @set
        lda (CHIPSET),y
        and #$7F
        sta (CHIPSET),y
        rts
@set:
        lda (CHIPSET),y
        ora #$80
        sta (CHIPSET),y
        rts
        
        
        
debug_banner_irq:
        .byte "IRQ ", 0
