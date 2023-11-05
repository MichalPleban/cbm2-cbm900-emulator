

trace_start:
        ; Clear the WAIT_CODE flag if it's set
        ldy #1
        sta (CHIPSET),y
        
@wait:        
        ; Loop until the processor is stopped on a new instruction
        ldy #3
        lda (CHIPSET),y
        and #$20
        beq @wait

        ; Output information about the current instruction
.ifdef DEBUG
        ldy #1
        lda (CHIPSET),y
        jsr debug_hex
        ldy #0
        lda (CHIPSET),y
        jsr debug_hex
        lda #$0D
        jsr serial_output
        lda #$0A
        jsr serial_output
.endif

        ; Clear the WAIT_CODE flag to let the processor go ahead
        ldy #1
        sta (CHIPSET),y
        jmp @wait
   