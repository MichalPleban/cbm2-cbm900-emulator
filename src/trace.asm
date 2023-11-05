

trace_start:
        ldy #1
        sta (CHIPSET),y
@wait:        
        ldy #3
        lda (CHIPSET),y
        and #$20
        beq @wait
.ifdef DEBUG
        ldy #1
        lda (CHIPSET),y
        jsr debug_hex
        ldy #0
        lda (CHIPSET),y
        jsr debug_hex
        lda #$0A
        jsr serial_output
        lda #$0D
        jsr serial_output
.endif
        ldy #1
        sta (CHIPSET),y
        jmp @wait
   