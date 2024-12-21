
scc_init:
        lda #0
        sta scc_irq_pending
        sta scc_irq_enable
        rts

scc_handle:
        lda z8000_status
        asl a
        lda z8000_addr
        and #$3E
        adc #$00
        asl a
        tax
        lda scc_table,x
        sta io_jump
        lda scc_table+1,x
        sta io_jump+1
        jsr io_handle
        jmp nmi_end

scc_set_irq:
        bit scc_irq_enable
        bpl @no_irq
        ldx kbd_head
        cpx kbd_tail
        beq @no_irq
        lda #$80
        .byt $2c
@no_irq:
        lda #$00
        sta scc_irq_pending
        jmp irq_issue        
        
; Register 00 - line status
; We return 04 to indicate that it's OK to send the next character
; and if there is a character in the keyboard buffer, we or with 01.
scc_in_00:
        lda #$04
        ldx kbd_head
        cpx kbd_tail
        beq @nochar
        ora #$01
@nochar:
        sta z8000_data
        rts
        
; Register 08 - receive buffer
; Input the character from the keyboard.
scc_in_08:
        jsr kbd_fetch
        sta z8000_data
        jsr scc_set_irq
        rts

; Register 08 - transmit buffer
; Output the transmitted character to screen.
scc_out_08:
        lda z8000_data
        jmp screen_output
        
; Register 02 - interrupt vector
scc_out_02:
        lda z8000_data
        sta scc_irq_vector
        jmp scc_save

; Register 09 - interrupt enable
scc_out_09:
        lda z8000_data
        asl a
        asl a
        asl a
        asl a
        sta scc_irq_enable
        rts

scc_save:
        lda z8000_addr
        lsr a
        and #$3F
        tax
        lda z8000_data
        sta scc_registers,x
        rts

scc_load:
        lda z8000_addr
        lsr a
        and #$3F
        tax
        lda scc_registers,x
        sta z8000_data
        rts
                        
scc_table:
        .word empty, scc_in_00          ; 00
        .word scc_save, scc_load        ; 01
        .word scc_out_02, scc_load      ; 02
        .word empty, undefined          ; 03
        .word empty, undefined          ; 04
        .word empty, undefined          ; 05
        .word empty, undefined          ; 06
        .word empty, undefined          ; 07
        .word scc_out_08, scc_in_08     ; 08
        .word scc_out_09, undefined     ; 09
        .word empty, undefined          ; 0A
        .word empty, undefined          ; 0B
        .word scc_save, scc_load        ; 0C
        .word scc_save, scc_load        ; 0D
        .word empty, undefined          ; 0E
        .word scc_save, scc_load        ; 0F
        .word undefined, undefined      ; 10
        .word undefined, undefined      ; 11
        .word scc_save, scc_load        ; 12
        .word undefined, undefined      ; 13
        .word undefined, undefined      ; 14
        .word undefined, undefined      ; 15
        .word undefined, undefined      ; 16
        .word undefined, undefined      ; 17
        .word undefined, undefined      ; 18
        .word empty, undefined          ; 19
        .word undefined, undefined      ; 1A
        .word undefined, undefined      ; 1B
        .word scc_save, scc_load        ; 1C
        .word scc_save, scc_load        ; 1D
        .word undefined, undefined      ; 1E
        .word scc_save, scc_load        ; 1F
