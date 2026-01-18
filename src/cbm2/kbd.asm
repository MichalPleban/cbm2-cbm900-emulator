
kbd_buffer      = $FE00

REPEAT_FIRST = 40
REPEAT_NEXT = 3

kbd_init:
        ldy #3
        lda #$FF
        sta (TPI2),y
        sta kbd_last
        iny
        sta (TPI2),y
        lda #$00
        iny
        sta (TPI2),y
        sta kbd_head
        sta kbd_tail
        sta kbd_stop
        rts

kbd_scan:
        ldx #$FE
        stx kbd_col+1
        inx
        stx kbd_col
        stx kbd_current
        inx
        stx kbd_shift
@scan_col:
        ldy #0
        lda kbd_col
        sta (TPI2),y
        iny
        lda kbd_col+1
        sta (TPI2),y
@check_row:
        ldy #2
        lda (TPI2),y
        sta kbd_row
        lda (TPI2),y
        cmp kbd_row
        bne @check_row
        ldy #6
@check_key:
        lsr a
        bcc @key_pressed
@continue:
        inx
        dey
        bne @check_key
@finish_row:
        sec
        rol kbd_col+1
        rol kbd_col
        bcs @scan_col
        ldx kbd_current
        bpl @finished
        stx kbd_last
@end:
        rts

@key_pressed:
        cpx #4
        bne @not_shift
        lda kbd_shift
        ora #$80
        sta kbd_shift
        bne @continue
@not_shift:
        cpx #5
        bne @not_ctrl
        lda kbd_shift
        ora #$40
        sta kbd_shift
        bne @continue
@not_ctrl:
        cpx #70
        bne @not_alt
        lda kbd_shift
        ora #$01
        sta kbd_shift
        bne @continue
@not_alt:
        stx kbd_current
        bne @continue

@finished:
        cpx kbd_last
        bne @new_key
        dec kbd_repeat
        bne @end
        lda #REPEAT_NEXT
        sta kbd_repeat
        bne @output
@new_key:
        cpx #90
        bne @not_stop
        lda #$80
        sta kbd_stop
@not_stop:
        stx kbd_last
        lda #REPEAT_FIRST
        sta kbd_repeat
@output:
        bit kbd_shift
        bmi @is_shift
        bvs @is_ctrl
        lda normal_table,x
        jmp @do_output
@is_shift:        
        lda shift_table,x
        jmp @do_output
@is_ctrl:        
        lda ctrl_table,x
@do_output:
        bpl @not_special
        and #$7F
        sec
        rol
        tax
        lda conv_table,x
        pha
        dex
        lda conv_table,x
        jsr @not_special
        pla
@not_special:
        beq @end
        ldx kbd_tail
        ldy kbd_tail
        iny
        cpy kbd_head
        ; Buffer full?
        beq @end
        sta kbd_buffer,x
        inx
        stx kbd_tail
        ; Issue IRQ to Z8000 if necessary
        jsr scc_set_irq
        rts

; Get next character from the buffer
; Destroyed: X
; Return: A = next character
kbd_fetch:
        ldx kbd_head
        cpx kbd_tail
        beq @nochar
        lda kbd_buffer,x
        inx
        stx kbd_head
        rts
@nochar:
        lda #$00
        rts        
        
normal_table:
        .byt $88        ; F1
        .byt 27         ; Esc
        .byt $09        ; Tab
        .byt 0
        .byt 0          ; Shift
        .byt 0          ; Ctrl
        .byt $89        ; F2
        .byt '1'        ; 1
        .byt 'q'        ; Q
        .byt 'a'        ; A
        .byt 'z'        ; Z
        .byt 0
        .byt $8A        ; F3
        .byt '2'        ; 2
        .byt 'w'        ; W
        .byt 's'        ; S
        .byt 'x'        ; X
        .byt 'c'        ; C
        .byt $8B        ; F4
        .byt '3'        ; 3
        .byt 'e'        ; E
        .byt 'd'        ; D
        .byt 'f'        ; F
        .byt 'v'        ; V
        .byt $8C        ; F5
        .byt '4'        ; 4
        .byt 'r'        ; R
        .byt 't'        ; T
        .byt 'g'        ; G
        .byt 'b'        ; B
        .byt $8D        ; F6
        .byt '5'        ; 5
        .byt '6'        ; 6
        .byt 'y'        ; Y
        .byt 'h'        ; H
        .byt 'n'        ; N
        .byt $8E        ; F7
        .byt '7'        ; 7
        .byt 'u'        ; U
        .byt 'j'        ; J
        .byt 'm'        ; M
        .byt ' '        ; Space
        .byt $8F        ; F8
        .byt '8'        ; 8
        .byt 'i'        ; I
        .byt 'k'        ; K
        .byt ','        ; ,
        .byt '.'        ; .
        .byt $90        ; F9
        .byt '9'        ; 9
        .byt 'o'        ; O
        .byt 'l'        ; L
        .byt ';'        ; ;
        .byt '/'        ; /
        .byt $91        ; F10
        .byt '0'        ; 0
        .byt '-'        ; -
        .byt 'p'        ; P
        .byt '['        ; [
        .byt $27        ; '
        .byt $83        ; Cursor down
        .byt '='        ; =
        .byt '\'        ; Pound
        .byt ']'        ; ]
        .byt $0D        ; Return
        .byt '`'        ; Pi
        .byt $80        ; Cursor up
        .byt $81        ; Cursor left
        .byt $82        ; Cursor right
        .byt $08        ; Ins/Del
        .byt 0          ; C=
        .byt 0
        .byt $84        ; Clr/Home
        .byt '?'        ; Numeric ?
        .byt '7'        ; Numeric 7
        .byt '4'        ; Numeric 4
        .byt '1'        ; Numeric 1
        .byt '0'        ; Numeric 0
        .byt $85        ; Rvs/Off
        .byt $87        ; CE
        .byt '8'        ; Numeric 8
        .byt '5'        ; Numeric 5
        .byt '2'        ; Numeric 2
        .byt '.'        ; Numeric .
        .byt $86        ; Norm/Graph
        .byt '*'        ; Numeric *
        .byt '9'        ; Numeric 9
        .byt '6'        ; Numeric 6
        .byt '3'        ; Numeric 3
        .byt '0'        ; Numeric 00
        .byt 0          ; Run/Stop
        .byt '/'        ; Numeric /
        .byt '-'        ; Numeric -
        .byt '+'        ; Numeric +
        .byt $0D        ; Numeric Enter
        .byt 0

shift_table:
        .byt $9A        ; F1
        .byt 27         ; Esc
        .byt $09        ; Tab
        .byt 0
        .byt 0          ; Shift
        .byt 0          ; Ctrl
        .byt $9B        ; F2
        .byt '!'        ; 1
        .byt 'Q'        ; Q
        .byt 'A'        ; A
        .byt 'Z'        ; Z
        .byt 0
        .byt $9C        ; F3
        .byt '@'        ; 2
        .byt 'W'        ; W
        .byt 'S'        ; S
        .byt 'X'        ; X
        .byt 'C'        ; C
        .byt $9D        ; F4
        .byt '#'        ; 3
        .byt 'E'        ; E
        .byt 'D'        ; D
        .byt 'F'        ; F
        .byt 'V'        ; V
        .byt $9E        ; F5
        .byt '$'        ; 4
        .byt 'R'        ; R
        .byt 'T'        ; T
        .byt 'G'        ; G
        .byt 'B'        ; B
        .byt $9F        ; F6
        .byt '%'        ; 5
        .byt '^'        ; 6
        .byt 'Y'        ; Y
        .byt 'H'        ; H
        .byt 'N'        ; N
        .byt $A0        ; F7
        .byt '&'        ; 7
        .byt 'U'        ; U
        .byt 'J'        ; J
        .byt 'M'        ; M
        .byt ' '        ; Space
        .byt $A1        ; F8
        .byt '*'        ; 8
        .byt 'I'        ; I
        .byt 'K'        ; K
        .byt '<'        ; ,
        .byt '>'        ; .
        .byt $A2        ; F9
        .byt '('        ; 9
        .byt 'O'        ; O
        .byt 'L'        ; L
        .byt ':'        ; ;
        .byt '?'        ; /
        .byt $A3        ; F10
        .byt ')'        ; 0
        .byt '_'        ; -
        .byt 'P'        ; P
        .byt '{'        ; [
        .byt '"'        ; '
        .byt $95        ; Cursor down
        .byt '+'        ; =
        .byt '|'        ; Pound
        .byt '}'        ; ]
        .byt $0D        ; Return
        .byt '~'        ; Pi
        .byt $92        ; Cursor up
        .byt $93        ; Cursor left
        .byt $94        ; Cursor right
        .byt $7F        ; Ins/Del
        .byt 0          ; C=
        .byt 0
        .byt $96        ; Clr/Home
        .byt '?'        ; Numeric ?
        .byt '7'        ; Numeric 7
        .byt '4'        ; Numeric 4
        .byt '1'        ; Numeric 1
        .byt '0'        ; Numeric 0
        .byt $97        ; Rvs/Off
        .byt $99        ; CE
        .byt '8'        ; Numeric 8
        .byt '5'        ; Numeric 5
        .byt '2'        ; Numeric 2
        .byt '.'        ; Numeric .
        .byt $98        ; Norm/Graph
        .byt '*'        ; Numeric *
        .byt '9'        ; Numeric 9
        .byt '6'        ; Numeric 6
        .byt '3'        ; Numeric 3
        .byt '0'        ; Numeric 00
        .byt 0          ; Run/Stop
        .byt '/'        ; Numeric /
        .byt '-'        ; Numeric -
        .byt '+'        ; Numeric +
        .byt $0D        ; Numeric Enter
        .byt 0

ctrl_table:
        .byt $AC        ; F1
        .byt 0          ; Esc
        .byt 0          ; Tab
        .byt 0
        .byt 0          ; Shift
        .byt 0          ; Ctrl
        .byt $AD        ; F2
        .byt 0          ; 1
        .byt 'Q'-64     ; Q
        .byt 'A'-64     ; A
        .byt 'Z'-64     ; Z
        .byt 0
        .byt $AE        ; F3
        .byt 0          ; 2
        .byt 'W'-64     ; W
        .byt 'S'-64     ; S
        .byt 'X'-64     ; X
        .byt 'C'-64     ; C
        .byt $AF        ; F4
        .byt 0          ; 3
        .byt 'E'-64     ; E
        .byt 'D'-64     ; D
        .byt 'F'-64     ; F
        .byt 'V'-64     ; V
        .byt $B0        ; F5
        .byt 0          ; 4
        .byt 'R'-64     ; R
        .byt 'T'-64     ; T
        .byt 'G'-64     ; G
        .byt 'B'-64     ; B
        .byt $B1        ; F6
        .byt 0          ; 5
        .byt 0          ; 6
        .byt 'Y'-64     ; Y
        .byt 'H'-64     ; H
        .byt 'N'-64     ; N
        .byt $B2        ; F7
        .byt 0          ; 7
        .byt 'U'-64     ; U
        .byt 'J'-64     ; J
        .byt 'M'-64     ; M
        .byt 0          ; Space
        .byt $B4        ; F8
        .byt 0          ; 8
        .byt 'I'-64     ; I
        .byt 'K'-64     ; K
        .byt 0          ; ,
        .byt 0          ; .
        .byt $B4        ; F9
        .byt 0          ; 9
        .byt 'O'-64     ; O
        .byt 'L'-64     ; L
        .byt 0          ; ;
        .byt 0          ; /
        .byt $B5        ; F10
        .byt 0          ; 0
        .byt 0          ; -
        .byt 'P'-64     ; P
        .byt 0          ; [
        .byt 0          ; '
        .byt $A7        ; Cursor down
        .byt 0          ; =
        .byt 0          ; Pound
        .byt 0          ; ]
        .byt $0D        ; Return
        .byt 0          ; Pi
        .byt $A4        ; Cursor up
        .byt $A5        ; Cursor left
        .byt $A6        ; Cursor right
        .byt 'D'-64     ; Ins/Del
        .byt 0          ; C=
        .byt 0
        .byt $A8        ; Clr/Home
        .byt 0          ; Numeric ?
        .byt 0          ; Numeric 7
        .byt 0          ; Numeric 4
        .byt 0          ; Numeric 1
        .byt 0          ; Numeric 0
        .byt $A9        ; Rvs/Off
        .byt $AB        ; CE
        .byt 0          ; Numeric 8
        .byt 0          ; Numeric 5
        .byt 0          ; Numeric 2
        .byt 0          ; Numeric .
        .byt $AA        ; Norm/Graph
        .byt 0          ; Numeric *
        .byt 0          ; Numeric 9
        .byt 0          ; Numeric 6
        .byt 0          ; Numeric 3
        .byt 0          ; Numeric 00
        .byt 0          ; Run/Stop
        .byt 0          ; Numeric /
        .byt 0          ; Numeric -
        .byt 0          ; Numeric +
        .byt $0D        ; Numeric Enter
        .byt 0

conv_table:
        ; Normal keys
        .byt 'P'-64, 0         ; Cursor up      [up]
        .byt 'B'-64, 0         ; Cursor left    [left]
        .byt 'F'-64, 0         ; Cursor right   [right]
        .byt 'N'-64, 0         ; Cursor down    [down]
        .byt $1B, '<'          ; Clr/Home       [beginning of text]
        .byt 0, 0              ; Rvs/Off
        .byt 0, 0              ; Norm/Graph
        .byt 0, 0              ; CE
        .byt 0, 0              ; F1
        .byt 'X'-64, 'S'-64    ; F2             [save]
        .byt 0, 0              ; F3
        .byt 0, 0              ; F4
        .byt 0, 0              ; F5
        .byt 0, 0              ; F6
        .byt 0, 0              ; F7
        .byt 0, 0              ; F8
        .byt 0, 0              ; F9
        .byt 'X'-64, 'C'-64    ; F10            [quit]
        ; With Shift
        .byt 0, 0              ; Cursor up
        .byt $1B, 'B'          ; Cursor left    [previous word]
        .byt $1B, 'F'          ; Cursor right   [next word]
        .byt 0, 0              ; Cursor down
        .byt 0, 0              ; Clr/Home
        .byt 0, 0              ; Rvs/Off
        .byt 0, 0              ; Norm/Graph
        .byt 0, 0              ; CE
        .byt 0, 0              ; F1
        .byt 0, 0              ; F2
        .byt 0, 0              ; F3
        .byt 0, 0              ; F4
        .byt 0, 0              ; F5
        .byt 0, 0              ; F6
        .byt 0, 0              ; F7
        .byt 0, 0              ; F8
        .byt 0, 0              ; F9
        .byt 0, 0              ; F10
        ; With Ctrl
        .byt 'Y'-64, 0         ; Cursor up      [page up]
        .byt 'A'-64, 0         ; Cursor left    [beginning of line]
        .byt 'E'-64, 0         ; Cursor right   [end of line]
        .byt $1B, 'Y'          ; Cursor down    [page down]
        .byt $1B, '>'          ; Clr/Home       [end of text]
        .byt 0, 0              ; Rvs/Off
        .byt 0, 0              ; Norm/Graph
        .byt 0, 0              ; CE
        .byt 0, 0              ; F1
        .byt 0, 0              ; F2
        .byt 0, 0              ; F3
        .byt 0, 0              ; F4
        .byt 0, 0              ; F5
        .byt 0, 0              ; F6
        .byt 0, 0              ; F7
        .byt 0, 0              ; F8
        .byt 0, 0              ; F9
        .byt 0, 0              ; F10
        