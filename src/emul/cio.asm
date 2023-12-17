
cio_init:
        lda #0
        sta timer_irq_enable
        sta timer_irq_pending
        rts

cio_handle:
        lda z8000_status
        asl a
        lda z8000_addr
        and #$7E
        adc #$00
        asl a
        tax
        lda cio_table,x
        sta io_jump
        lda cio_table+1,x
        sta io_jump+1
        jsr io_handle
        jmp nmi_end

cio_timer:
        bit timer_irq_enable
        bpl @disabled
        lda #$80
        sta timer_irq_pending
        jmp irq_issue
@disabled:
        rts
                
; Register 08 - pattern match flags
; We return 00 to indicate that there is no character from the keyboard 
cio_in_08:
        lda #$00
        sta z8000_data
        rts

; Register 04 - timer interrupt vector
cio_out_04:
        lda z8000_data
        sta timer_irq_vector
        jmp cio_save

; Register 00 - master interrupt control
cio_out_00:
        lda z8000_data
        sta timer_irq_enable
        jmp cio_save

; Register 0C - clear interrupt
; TODO: handle written values properly ($24 clears IRQ)
cio_out_0c:
        lda #0
        sta timer_irq_pending
        jsr irq_issue
        jmp cio_save

cio_save:
        lda z8000_addr
        lsr a
        and #$3F
        tax
        lda z8000_data
        sta cio_registers,x
        rts

cio_load:
        lda z8000_addr
        lsr a
        and #$3F
        tax
        lda cio_registers,x
        sta z8000_data
        rts
                                
cio_table:
        .word cio_out_00, undefined     ; 00
        .word empty, empty              ; 01
        .word cio_save, cio_load        ; 02
        .word cio_save, cio_load        ; 03
        .word cio_out_04, cio_load      ; 04
        .word cio_save, cio_load        ; 05
        .word cio_save, cio_load        ; 06
        .word cio_save, cio_load        ; 07
        .word empty, cio_in_08          ; 08
        .word empty, undefined          ; 09
        .word cio_save, cio_load        ; 0A
        .word cio_save, cio_load        ; 0B
        .word cio_out_0c, cio_load      ; 0C
        .word cio_save, cio_load        ; 0D
        .word empty, empty              ; 0E
        .word empty, undefined          ; 0F
        .word undefined, undefined      ; 10
        .word undefined, undefined      ; 11
        .word undefined, undefined      ; 12
        .word undefined, undefined      ; 13
        .word undefined, undefined      ; 14
        .word undefined, undefined      ; 15
        .word cio_save, cio_load        ; 16
        .word cio_save, cio_load        ; 17
        .word cio_save, cio_load        ; 18
        .word cio_save, cio_load        ; 19
        .word cio_save, cio_load        ; 1A
        .word cio_save, cio_load        ; 1B
        .word cio_save, cio_load        ; 1C
        .word cio_save, cio_load        ; 1D
        .word cio_save, cio_load        ; 1E
        .word undefined, undefined      ; 1F
        .word cio_save, cio_load        ; 20
        .word cio_save, cio_load        ; 21
        .word cio_save, cio_load        ; 22
        .word cio_save, cio_load        ; 23
        .word cio_save, cio_load        ; 24
        .word cio_save, cio_load        ; 25
        .word cio_save, cio_load        ; 26
        .word cio_save, cio_load        ; 27
        .word empty, undefined          ; 28
        .word undefined, undefined      ; 29
        .word undefined, undefined      ; 2A
        .word empty, undefined          ; 2B
        .word undefined, undefined      ; 2C
        .word undefined, undefined      ; 2D
        .word undefined, undefined      ; 2E
        .word undefined, undefined      ; 2F
        .word undefined, undefined      ; 30
        .word undefined, undefined      ; 31
        .word undefined, undefined      ; 32
        .word undefined, undefined      ; 33
        .word undefined, undefined      ; 34
        .word undefined, undefined      ; 35
        .word undefined, undefined      ; 36
        .word undefined, undefined      ; 37
        .word undefined, undefined      ; 38
        .word undefined, undefined      ; 39
        .word undefined, undefined      ; 3A
        .word undefined, undefined      ; 3B
        .word undefined, undefined      ; 3C
        .word undefined, undefined      ; 3D
        .word undefined, undefined      ; 3E
        .word undefined, undefined      ; 3F

        
