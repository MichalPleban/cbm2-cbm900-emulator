
VGA_CMD = $BC
VGA_DATA = $BD

VGA_BUFFER = $E000
VGA_DELAY = 10      ; Screen refresh every 0.1s

vga_init:
        ; VGA command - switch to VGA mode
        lda #$00
        sta vga_busy
        lda #VGA_DELAY
        sta vga_delay
        ldy #VGA_CMD
        lda #$81
        sta (SID),y
        jsr vga_clear
        rts

vga_clear:
        ; Disable screen mirroring
        lda #$80
        sta vga_busy
        
        ; VGA command - clear screen
        ldy #VGA_CMD
        lda #$82
        sta (SID),y
        
        ; Fill screen buffer with zeroes
        lda #<VGA_BUFFER
        sta vga_buffer
        sta vga_ptr
        lda #>VGA_BUFFER
        sta vga_buffer+1
        sta vga_ptr+1
        ldx #0
        stx screen_x
        stx screen_y
        stx vga_dirty
        lda #VGA_DELAY
        sta vga_delay
        ldy #16
        txa
@loop:
        sta (vga_buffer,x)
        inc vga_buffer
        bne @loop
        inc vga_buffer+1
        dey
        bne @loop
        
        ; Default text attribute
        lda #$07
        sta vga_attr
        
        ; Re-enable screen mirroring
        lda #$00
        sta vga_busy
        rts

vga_check_mirror:
        ; Check if any part of the screen is dirty
        lda vga_dirty
        beq @end
        lda vga_busy
        bne @end
        
        ; Check if it's time to copy screen
        lda vga_delay
        beq vga_mirror
        
        ; Not yet, decrement the counter
        dec vga_delay
@end:
        rts
                        
vga_mirror:
        lda #0
        sta vga_segment
        lda #<VGA_BUFFER
        sta vga_mirror_buf
        lda #>VGA_BUFFER
        sta vga_mirror_buf+1
        ldx #0
@loop:
        lsr vga_dirty
        bcc @not_dirty
        ldy #VGA_CMD
        lda vga_segment
        sta (SID),y
        iny
@first_half:
        lda (vga_mirror_buf,x)
        sta (SID),y
        inc vga_mirror_buf
        bne @first_half
        inc vga_mirror_buf+1
@second_half:
        lda (vga_mirror_buf,x)
        sta (SID),y
        inc vga_mirror_buf
        bne @second_half
        inc vga_mirror_buf+1
@next_segment:        
        inc vga_segment
        lda vga_segment
        cmp #8
        bne @loop
        lda #VGA_DELAY
        sta vga_delay
        jmp vga_cursor
        rts
@not_dirty:
        inc vga_mirror_buf+1
        inc vga_mirror_buf+1
        bne @next_segment

vga_output:
        dec vga_busy
        cmp #$0D
        bne @not_cr
        lda #0
        sta screen_x
        sta vga_busy
        rts
@not_cr:
        cmp #$07
        bne @not_bell
        lda #0
        sta vga_busy
        rts
@not_bell:
        cmp #$08
        bne @not_bksp
        lda screen_x
        bne @bksp
        sta vga_busy
        rts
@bksp:
        dec screen_x
        jmp vga_cursor
@not_bksp:        
        cmp #$09
        bne @not_tab
        lda screen_x
        and #$F8
        ora #$07
        sta screen_x
        bne vga_advance
@not_tab:        
        cmp #$0A
        beq vga_newline
        tax
        and #$E0
        ; Ignore control characters
        bne @output
        sta vga_busy
        rts
@output:
        txa
        pha
        ; Calculate the character address
        lda screen_x
        asl a
        clc
        adc vga_ptr
        sta vga_buffer
        lda vga_ptr+1
        adc #0
        sta vga_buffer+1
        ldx #0
        pla
        sta (vga_buffer,x)
        inc vga_buffer
        lda vga_attr
        sta (vga_buffer,x)
        
@not_space:
        
        ; Mark the current block as dirty
        lda vga_buffer+1
        lsr a
        and #$07
        tax
        lda vga_bits,x
        ora vga_dirty
        sta vga_dirty
        
        ; Move cursor
        jmp vga_advance
        
vga_advance:
        ldy screen_x
        iny
        cpy #80
        beq vga_newline
        sty screen_x
        lda #0
        sta vga_busy
        rts        
vga_newline:
        ldy #$00
        sty screen_x
        ldy screen_y
        iny
        cpy #25
        beq vga_scroll
        sty screen_y
        clc
        lda vga_ptr
        adc #160
        sta vga_ptr
        lda vga_ptr+1
        adc #0
        sta vga_ptr+1
        ; Refresh immediately on newline
        lda #0
        sta vga_delay
        sta vga_busy
        rts
vga_scroll:
;        lda #$80
;        sta vga_busy
        ldy #16
        ldx #00
        lda #<VGA_BUFFER
        sta vga_buffer
        lda #>VGA_BUFFER
        sta vga_buffer+1
        lda #<(VGA_BUFFER+160)
        sta vga_mirror_buf
        lda #>(VGA_BUFFER+160)
        sta vga_mirror_buf+1
@scroll_loop:        
        lda (vga_mirror_buf,x)
        sta (vga_buffer,x)
        inc vga_mirror_buf
        bne @not_zero
        inc vga_mirror_buf+1
@not_zero:
        inc vga_buffer
        bne @scroll_loop
        inc vga_buffer+1
        dey
        bne @scroll_loop
        lda #<(VGA_BUFFER+24*160)
        sta vga_buffer
        lda #>(VGA_BUFFER+24*160)
        sta vga_buffer+1
        ldy #160
        txa
@clear_loop:
        sta (vga_buffer,x)
        dey
        beq @end
        inc vga_buffer
        bne @clear_loop
        inc vga_buffer+1
        bne @clear_loop
@end:
        ; Refresh immediately on scroll
        ldy #VGA_CMD
        lda #$83
        sta (SID),y        
        lda #$C0
        sta vga_dirty
        jsr vga_mirror
        lda VGA_DELAY
;        sta vga_delay
        lda #0
        sta vga_busy
        rts
        
; Position VGA cursor according to the screen position
vga_cursor:
        lda vga_ptr+1
        lsr a
        sta vga_buffer+1
        lda vga_ptr
        ror a
        sta vga_buffer
        lda screen_x
        clc
        adc vga_buffer
        ldx #15
        jsr crtc_write
        lda vga_buffer+1
        and #$07
        dex
        jsr crtc_write
@end:
        lda #0
        sta vga_busy
        rts

vga_position:
        stx screen_x
        sty screen_y
        lda #<VGA_BUFFER
        sta vga_ptr
        lda #>VGA_BUFFER
        sta vga_ptr+1
        dey
        bmi @end
@loop:
        lda vga_ptr
        clc
        adc #$A0
        sta vga_ptr
        lda vga_ptr+1
        adc #0
        sta vga_ptr+1
        dey
        bpl @loop
@end:
        rts

        
; Clear a part of the screen
; Destroyed: A, X, Y
vga_clear_special:
        lda #$80
        sta vga_busy
        lda #<VGA_BUFFER
        sta vga_buffer
        lda #>VGA_BUFFER
        sta vga_buffer+1
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
        txa
        pha
        lda #0
        tax
        sta (vga_buffer,x)
        inc vga_buffer
        sta (vga_buffer,x)
        dec vga_buffer
        lda vga_buffer+1
        lsr a
        and #$07
        tax
        lda vga_bits,x
        ora vga_dirty
        sta vga_dirty
        pla
        tax
@dont_write:
        lda vga_buffer
        clc
        adc #2
        sta vga_buffer
        lda vga_buffer+1
        adc #0
        sta vga_buffer+1
        iny
        cpy #80
        bne @loop1
        inx
        cpx #25
        beq @end
        bne @loop2
@end:
        lda #$00
        sta vga_busy
        rts

        
vga_bits:
        .byte $01, $02, $04, $08, $10, $20, $40, $80
        