
; Initialize the screen routines
screen_init:
        jsr screen_clear
        lda #$00
        sta screen_charset
        ldx #10
        lda #$60
        jsr crtc_write
        rts

; Clear screen and reset screen pointer to 0,0.
; Destroyed: A, X, Y
screen_clear:
        lda #$D8
        sta SCREEN+1
        ldy #$00
        sty SCREEN
        lda #$20
        ldx #8
@loop2:
        dec SCREEN+1
@loop1:
        sta (SCREEN),y
        dey
        bne @loop1
        dex
        bne @loop2
        stx screen_x
        sty screen_y
        rts

; Output one character to the screen at the current position.
; Input: A = character
; Destroyed: A, X, Y
screen_output:
        cmp #$0D
        bne @not_cr
        lda #0
        sta screen_x
        jmp screen_cursor
@not_cr:
        cmp #$07
        bne @not_bell
        rts
@not_bell:
        cmp #$08
        bne @not_bksp
        lda screen_x
        bne @bksp
        rts
@bksp:
        dec screen_x
        bpl screen_cursor
@not_bksp:        
        cmp #$09
        bne @not_tab
        lda screen_x
        and #$F8
        ora #$07
        sta screen_x
        bne screen_advance
@not_tab:        
        cmp #$0A
        beq screen_newline
        tax
        and #$E0
        ; Ignore control characters
        bne @output
        rts
@output:
        lda petscii_table, x
        ldy screen_x
        sta (SCREEN),y
        
; Move screen position one character.
screen_advance:
        ldy screen_x
        iny
        cpy #80
        beq screen_newline
        sty screen_x
        bne screen_cursor
screen_newline:
        ldy #$00
        sty screen_x
        ldy screen_y
        iny
        cpy #25
        beq screen_scroll
        sty screen_y
        clc
        lda SCREEN
        adc #80
        sta SCREEN
        lda SCREEN+1
        adc #0
        sta SCREEN+1
        bne screen_cursor
screen_scroll:
        lda #$D0
        sta scratchpad+1
        sta scratchpad+3
        ldy #$00
        sty scratchpad
        lda #$50
        sta scratchpad+2
        ldx #6
@loop:
        lda (scratchpad+2),y
        sta (scratchpad),y
        iny
        bne @loop
        inc scratchpad+1
        inc scratchpad+3
        dex
        bpl @loop
@loop2:
        lda (scratchpad+2),y
        sta (scratchpad),y
        iny
        cpy #128
        bne @loop2
        ldy #$4F
        lda #$20
@loop3:
        sta (SCREEN),y
        dey
        bpl @loop3

; Position cursor on the screen
screen_cursor:
        lda screen_x
        clc
        adc SCREEN
        ldx #15
        jsr crtc_write
        lda SCREEN+1
        adc #0
        and #$07
        ora screen_charset
        dex
        jsr crtc_write
        rts

; Output null-terminated string to screen
; Input: A,Y = pointer to the string
; Destroyed: A, X, Y
screen_string:
        sta screen_ptr
        sty screen_ptr+1
@loop:
        ldx #$00
        lda (screen_ptr,x)
        beq @end
        jsr screen_output
        inc screen_ptr
        bne @loop
        inc screen_ptr+1
        bne @loop
@end:
        rts

; Read a CRTC register
; Input: X = index number
; Output: A = register value
; Destroyed: Y
crtc_read:
        ldy #0
        txa
        sta (CRTC),y
        iny
        lda (CRTC),y
        rts

; Write a CRTC register
; Input: X = index number, A = register value
; Destroyed: Y
crtc_write:
        ldy #0
        pha
        txa
        sta (CRTC),y
        iny
        pla
        sta (CRTC),y
        rts

                
; Conversion table from ASCII to screen codes
petscii_table:
	.byt $60, $64, $64, $64, $64, $64, $64, $2a, $aa, $2a, $aa, $64, $64, $64, $64, $64
	.byt $3e, $3c, $5d, $64, $64, $64, $62, $5d, $1e, $16, $3e, $3c, $64, $64, $1e, $16
	.byt $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f
	.byt $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f
	.byt $00, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f
	.byt $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5a, $1b, $1c, $1d, $1e, $1f
	.byt $40, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
	.byt $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $5b, $5c, $5d, $5e, $1e
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $0c, $64, $64, $64
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $3c, $3e
	.byt $66, $5f, $5f, $5d, $73, $73, $73, $6e, $6e, $73, $5d, $6e, $7d, $7d, $7d, $6e
	.byt $6d, $71, $72, $6b, $40, $5b, $6b, $6b, $6d, $70, $71, $72, $6b, $40, $5b, $71
	.byt $71, $72, $72, $6d, $6d, $70, $70, $5b, $5b, $7d, $70, $e0, $62, $61, $e1, $e2
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $2a, $2a, $7a, $64, $64, $2a, $60
