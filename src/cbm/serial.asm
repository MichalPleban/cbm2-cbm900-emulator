
serial_init:
        ldy #1
        sta (ACIA),y
        iny
        lda #$0B
        sta (ACIA),y
        iny
        lda #$1E
        sta (ACIA),y
        rts

; Output one character to the serial line
; Input: A = character code
; Destroyed: Y
serial_output:
        pha
        ldy #1
@wait:
        lda (ACIA),y
        and #$10
        beq @wait
        pla
        dey
        sta (ACIA),y
        rts

; Output null-terminated string to serial line
; Input: A,Y = pointer to the string
; Destroyed: A, X, Y
serial_string:
        sta serial_ptr
        sty serial_ptr+1
@loop:
        ldx #0
        lda (serial_ptr,x)
        beq @end
        jsr serial_output
        inc serial_ptr
        bne @loop
        inc serial_ptr+1
        bne @loop
@end:
        rts
