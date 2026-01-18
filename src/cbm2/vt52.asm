
VT52_IDLE = $00
VT52_ESCAPE = $80
VT52_GET_Y = $81
VT52_GET_X = $82

vt52_init:
        lda #VT52_IDLE
        sta vt52_state
        rts
        
vt52_start:
        lda #VT52_ESCAPE
        sta vt52_state
        rts
        
vt52_handle:
        ldx vt52_state
        cpx #VT52_ESCAPE
        beq @handle_esc
        cpx #VT52_GET_Y
        bne @not_get_y
        
        ; First character of Esc Y (set cursor)
        sec
        sbc #$20
        sta vt52_tmp
        lda #VT52_GET_X
        sta vt52_state
        rts
        
@not_get_y:
        cpx #VT52_GET_X
        beq @do_get_x
        jmp @end

@do_get_x:
        ; Second character of Esc Y (set cursor)
        sec
        sbc #$20
        tax
        lda vt52_tmp
        tay
@do_cursor:
        jsr screen_position
        jsr screen_cursor
        jmp @end
        
@handle_esc:

        cmp #'Y'
        bne @not_y
        ; Esc Y (set cursor) requires two more characters
        lda #VT52_GET_Y
        sta vt52_state
        rts
        
@not_y:

        cmp #'E'
        bne @not_e
        ; Esc E - clear screen
        jsr screen_clear
        jsr screen_cursor
        jmp @end

@not_e:
        cmp #'H'
        bne @not_h
        ; Esc H - cursor home
        ldy #0
        ldx #0
        jsr screen_position
        jsr screen_cursor
        jmp @end

@not_h:
        cmp #'J'
        bne @not_j
        ; Esc J - clear rest of screen
        lda screen_x
        sta screen_clr_x1
        lda screen_y
        sta screen_clr_y1
        lda #80
        sta screen_clr_x2
        lda #25
        sta screen_clr_y2
        jsr screen_clear_special
        jmp @end
        
@not_j:
        cmp #'K'
        bne @not_k
        ; Esc J - clear rest of line
        lda screen_x
        sta screen_clr_x1
        lda screen_y
        sta screen_clr_y1
        sta screen_clr_y2
        lda #80
        sta screen_clr_x2
        jsr screen_clear_special
        jmp @end
        
@not_k:
        cmp #'A'
        bne @not_a
@do_a:
        ldx screen_x
        ldy screen_y
        beq @end
        dey
        jmp @do_cursor
        
@not_a:
        cmp #'B'
        bne @not_b
        ldx screen_x
        ldy screen_y
        cpy #24
        beq @end
        iny
        jmp @do_cursor
        
@not_b:
        cmp #'C'
        bne @not_c
        ldy screen_y
        ldx screen_x
        cpy #79
        beq @end
        inx
        jmp @do_cursor
        
@not_c:
        cmp #'D'
        bne @not_d
        ldy screen_y
        ldx screen_x
        beq @end
        dex
        jmp @do_cursor
        
@not_d:
        cmp #'I'
        ; TODO: Esc I should scroll screen when on first line, this is not supported yet
        beq @do_a
        
        ldx #VT52_IDLE
        stx vt52_state
        jsr screen_output
        rts
@end:
        ldx #VT52_IDLE
        stx vt52_state
        rts
        