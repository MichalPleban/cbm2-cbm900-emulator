
SERIAL_BUFFER = $DF00

; 6551 ACIA registers:
;  0 - data in/out
;  1 - reset/status
;  2 - command
;  3 - control

serial_init:
        ldy #1              ; Register 1 - programmatic reset
        sta (ACIA),y
        iny                 ; Register 2 - command
        lda #$09            ; No parity, no echo, receiver IRQ, transmitter enable
        sta (ACIA),y
        iny                 ; Register 2 - control
        lda #$1E            ; 1 stop bit, 8 data bits, 9600 baud
        sta (ACIA),y
        lda #0
        sta serial_head     ; Clear receive buffer
        sta serial_tail
        rts

; Output one character to the serial line
; Input: A = character code
; Destroyed: Y
serial_output:
        pha
        ldy #1              ; Register 1 - status
@wait:
        lda (ACIA),y
        and #$10            ; Bit 4 = transmitter register empty
        beq @wait
        pla
        dey                 ; Register 0 - data
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

serial_status:
        ldy #1
        lda (ACIA),y
        and #$10
        rts
                
serial_irq:
        ldy #1              ; Register 1 - status
        lda (ACIA),y
        and #$08            ; Check if character received
        beq @end 

        ; <debug>
;        lda #'.'
;        jsr screen_output
        ; </debug>
        
        ldy #0              ; Register 0 - serial data
        lda (ACIA),y
        ldx serial_tail
        inx
        cpx serial_head
        beq @end            ; Buffer full
        dex
        sta SERIAL_BUFFER,x
        inc serial_tail

        ; Re-enable interrupts so that the next byte can arrive
        cli
        jsr scc_set_irq
@end:
        rts
