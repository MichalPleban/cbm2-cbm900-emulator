
screen_save = $F000
screen_charset = config_data + $29


; Initialize the screen routines
screen_init:
        jsr vt52_init
;        jsr vga_init
        jsr screen_clear
        lda #$00
        sta screen_invert
        sta menu_visible
        ldx #10
        lda #$60
        jsr crtc_write
        ldx #12
        jsr crtc_read
        bit screen_charset
        bvs @pc_charset
        and #$EF
        .byt $2C
@pc_charset:
        ora #$10
        jsr crtc_write            
        rts

; Clear screen and reset screen pointer to 0,0.
; Destroyed: A, X, Y
screen_clear:
;        jmp vga_clear
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

; Clear a part of the screen
; Destroyed: A, X, Y
screen_clear_special:
        lda #$D0
        sta screen_ptr+1
        lda #$00
        sta screen_ptr
        ldx #0
@loop2:
        ldy #0
@loop1:
        cpx screen_clr_y1
        beq @do_check
        bcc @dont_write
        cpx screen_clr_y2
        beq @do_check
        bcs @dont_write
        bcc @dont_check
@do_check:
        cpy screen_clr_x1
        bcc @dont_write
        cpy screen_clr_x2
        bcs @dont_write
@dont_check:
        lda #' '
        sta (screen_ptr),y
@dont_write:
        iny
        cpy #80
        bne @loop1
        inx
        cpx #25
        beq @end
        lda screen_ptr
        clc
        adc #80
        sta screen_ptr
        lda screen_ptr+1
        adc #0
        sta screen_ptr+1
        jmp @loop2
@end:
        rts

; Output one character to the screen at the current position.
; Input: A = character
; Destroyed: A, X, Y
screen_output:
        bit vt52_state
        bpl @not_vt52
        jmp vt52_handle
@not_vt52:        
        cmp #$1B
        bne @not_escape
        jmp vt52_start
@not_escape:
;        jmp vga_output
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
        jmp screen_cursor
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
        bit screen_charset
        bvs @pc_charset
        lda petscii_table, x
        jmp @output2
@pc_charset:
        lda petscii_table2, x
@output2:
        eor screen_invert
        eor menu_visible 
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
        rts

; Set screen X and Y position
; Input: X - screen X, Y - screen Y
; Destroyed: A, Y
screen_position:
        stx screen_x
        sty screen_y
        lda #$00
        sta SCREEN
        lda #$D0
        sta SCREEN+1
        dey
        bmi @end
@loop:
        lda SCREEN
        clc
        adc #$50
        sta SCREEN
        lda SCREEN+1
        adc #0
        sta SCREEN+1
        dey
        bpl @loop
@end:
        rts
        
; Position CRTC cursor according to the screen position
screen_cursor:
        bit menu_visible
        bmi @end
        lda screen_x
        clc
        adc SCREEN
        ldx #15
        jsr crtc_write
        lda SCREEN+1
        adc #0
        and #$07
        bit screen_charset
        bvc @cbm_charset
        ora #$10
@cbm_charset:
        dex
        jsr crtc_write
@end:
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
	.byt $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5a, $1b, $6e, $1d, $1e, $64
	.byt $6d, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
	.byt $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $73, $5d, $6b, $78, $1e
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $0c, $64, $64, $64
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $3c, $3e
	.byt $66, $5f, $5f, $5d, $73, $73, $73, $6e, $6e, $73, $5d, $6e, $7d, $7d, $7d, $6e
	.byt $6d, $71, $72, $6b, $40, $5b, $6b, $6b, $6d, $70, $71, $72, $6b, $40, $5b, $71
	.byt $71, $72, $72, $6d, $6d, $70, $70, $5b, $5b, $7d, $70, $e0, $62, $61, $e1, $e2
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $2a, $2a, $7a, $64, $64, $2a, $60

petscii_table2:
	.byt $7f, $5f, $5f, $5f, $5f, $5f, $5f, $7c, $7d, $7c, $7d, $5f, $5f, $5f, $5f, $5f
	.byt $76, $75, $7a, $5f, $5f, $5f, $62, $7a, $77, $78, $76, $75, $5f, $5f, $77, $78
	.byt $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f
	.byt $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f
	.byt $00, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f
	.byt $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5a, $1b, $1c, $1d, $1e, $1f
	.byt $40, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
	.byt $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $5b, $5c, $5d, $5e, $77
	.byt $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f
	.byt $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $7e, $5f, $5f, $5f
	.byt $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $75, $76
	.byt $69, $68, $6a, $65, $6c, $6c, $6c, $6f, $6f, $6c, $65, $6f, $71, $71, $71, $6f
	.byt $72, $6d, $6e, $6b, $66, $67, $6b, $6b, $72, $70, $6d, $6e, $6b, $66, $67, $6d
	.byt $6d, $6e, $6e, $72, $72, $70, $70, $67, $67, $71, $70, $60, $62, $61, $64, $63
	.byt $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f
	.byt $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $7c, $7c, $79, $5f, $5f, $74, $7f

menu_show:
        ; Stop the CPU if needed
        bit z8000_started
        bpl @not_started
        ldy #6
        lda (CHIPSET),y
        ora #$04
        sta (CHIPSET),y
@not_started:

        ; Save screen pointers and variables
        lda SCREEN
        sta menu_ptr_save
        lda SCREEN+1
        sta menu_ptr_save+1
        lda screen_x
        sta menu_ptr_save+2
        lda screen_y
        sta menu_ptr_save+3
        lda screen_invert
        sta menu_ptr_save+4
        lda#$00
        sta screen_invert
        
        ; Save the current screen
        lda #<screen_save
        sta scratchpad
        lda #>screen_save
        sta scratchpad+1
        lda #$D0
        sta scratchpad+3
        lda #$00
        sta scratchpad+2
        tax
        tay
@loop_copy:        
        lda (scratchpad+2),y
        sta (scratchpad,x)
        inc scratchpad
        inc scratchpad+2
        bne @loop_copy
        inc scratchpad+1
        inc scratchpad+3
        lda scratchpad+3
        cmp #$D8
        bne @loop_copy

        ; Hide CRTC cursor
        ldx #15
        lda #$FF
        jsr crtc_write
        dex
        jsr crtc_write

        jsr menu_enter
        
        ; Restore the screen
        lda #<screen_save
        sta scratchpad
        lda #>screen_save
        sta scratchpad+1
        lda #$D0
        sta scratchpad+3
        lda #$00
        sta scratchpad+2
        tax
        tay
@loop_restore:
        lda (scratchpad,x)
        sta (scratchpad+2),y
        inc scratchpad
        inc scratchpad+2
        bne @loop_restore
        inc scratchpad+1
        inc scratchpad+3
        lda scratchpad+3
        cmp #$D8
        bne @loop_restore
           
        ; Restore screen pointers and variables
        lda menu_ptr_save
        sta SCREEN
        lda menu_ptr_save+1
        sta SCREEN+1
        lda menu_ptr_save+2
        sta screen_x
        lda menu_ptr_save+3
        sta screen_y
        lda menu_ptr_save+4
        sta screen_invert
        jsr screen_cursor

        ; Start the CPU if needed    
        bit z8000_started
        bpl @not_stopped
        ldy #6
        lda (CHIPSET),y
        and #$FA
        sta (CHIPSET),y
@not_stopped:        
        rts
        
        ; Draw the menu background
menu_background:
        lda #$A4
        sta scratchpad
        lda #$D1
        sta scratchpad+1
        ldx #15
@loop_bk_1:
        ldy #39
        lda #$DD
        sta (scratchpad),y
        dey
@loop_bk_2:
        lda #$A0
        sta (scratchpad),y
        dey
        bne @loop_bk_2
        lda #$DD
        sta (scratchpad),y
        lda scratchpad
        clc
        adc #80
        sta scratchpad
        lda scratchpad+1
        adc #0
        sta scratchpad+1
        dex
        bne @loop_bk_1

        lda #$54
        sta scratchpad
        lda #$D1
        sta scratchpad+1
        ldy #39
        lda #$EE
        sta (scratchpad),y
        dey
@loop_frame_1:
        lda #$C0
        sta (scratchpad),y
        dey
        bne @loop_frame_1
        lda #$F0
        sta (scratchpad),y
        
        lda #$54
        sta scratchpad
        lda #$D6
        sta scratchpad+1
        ldy #39
        lda #$FD
        sta (scratchpad),y
        dey
@loop_frame_2:
        lda #$C0
        sta (scratchpad),y
        dey
        bne @loop_frame_2
        lda #$ED
        sta (scratchpad),y

        rts
        
menu_video:
        jsr menu_background
        ldx #24
        ldy #6
        jsr screen_position
        lda #<menu_video_1
        ldy #>menu_video_1
        jsr screen_string
        ldx #24
        ldy #8
        jsr screen_position
        lda #<menu_video_2
        ldy #>menu_video_2
        jsr screen_string
        ldx #24
        ldy #10
        jsr screen_position
        lda #<menu_video_3
        ldy #>menu_video_3
        jsr screen_string
        ldx #22
        ldy #12
        jsr screen_position
        lda #<menu_video_r
        ldy #>menu_video_r
        jsr screen_string
        ldx #22
        ldy #13
        jsr screen_position
        lda #<menu_video_r2
        ldy #>menu_video_r2
        jsr screen_string
@show_options:
        ldx #22
        ldy #6
        jsr screen_position
        lda screen_charset
        beq @cbm_charset
        lda #$20
        bne @show_first
@cbm_charset:
        lda #'>'
@show_first:
        jsr screen_output
        ldx #22
        ldy #8
        jsr screen_position
        bit screen_charset
        bvs @pc_charset
        lda #$20
        bne @show_second
@pc_charset:
        lda #'>'
@show_second:
        jsr screen_output
        ldx #22
        ldy #10
        jsr screen_position
        bit screen_charset
        bmi @vga_card
        lda #$20
        bne @show_third
@vga_card:
        lda #'>'
@show_third:
        jsr screen_output
@loop:
        jsr kbd_fetch
        cmp #'a'
        beq @is_a
        cmp #'A'
        bne @not_a
@is_a:
        lda #$00
        sta screen_charset
        beq @show_options
@not_a:
        cmp #'b'
        beq @is_b
        cmp #'B'
        bne @not_b
@is_b:
        lda #$40
        sta screen_charset
        bne @show_options
@not_b:
        cmp #'c'
        beq @is_c
        cmp #'C'
        bne @not_c
@is_c:
        lda #$80
        sta screen_charset
        bne @show_options
@not_c:
        cmp #27
        bne @loop
        rts

menu_video_1:
        .byt "A: Inbuilt video, standard charset", 0
menu_video_2:
        .byt "B: Inbuilt video, PC charset", 0
menu_video_3:
        .byt "C: VGA adapter", 0
menu_video_r:
        .byt "WARNING: Video mode change will only", 0
menu_video_r2:
        .byt "take effect after computer restart.", 0
