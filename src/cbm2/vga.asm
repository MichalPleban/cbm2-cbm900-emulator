
VGA_CMD = $BC
VGA_DATA = $BD

VGA_BUFFER = $E000
VGA_DELAY = 50      ; Screen refresh every 0.1s

vga_init:
        ; VGA command - switch to VGA mode
        ldy #VGA_CMD
        lda #$81
        sta (SID),y
        jsr vga_clear
        rts

vga_clear:
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
        stx vga_x
        stx vga_y
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
        rts

vga_check_mirror:
        ; Check if any part of the screen is dirty
        lda vga_dirty
        beq @end
        
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
        cmp #$0D
        bne @not_cr
        lda #0
        sta vga_x
        rts
@not_cr:
        cmp #$07
        bne @not_bell
        rts
@not_bell:
        cmp #$08
        bne @not_bksp
        lda vga_x
        bne @bksp
        rts
@bksp:
        dec vga_x
        jmp vga_cursor
@not_bksp:        
        cmp #$09
        bne @not_tab
        lda vga_x
        and #$F8
        ora #$07
        sta vga_x
        bne vga_advance
@not_tab:        
        cmp #$0A
        beq vga_newline
        tax
        and #$E0
        ; Ignore control characters
        bne @output
        rts
@output:
        txa
        pha
        ; Calculate the character address
        lda vga_x
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
        ldy vga_x
        iny
        cpy #80
        beq vga_newline
        sty vga_x
        rts        
vga_newline:
        ldy #$00
        sty vga_x
        ldy vga_y
        iny
        cpy #25
        beq vga_scroll
        sty vga_y
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
        rts
vga_scroll:
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
        lda #$FF
        sta vga_dirty
        ; Refresh immediately on scroll
        lda #0
        rts
        
; Position VGA cursor according to the screen position
vga_cursor:
        bit menu_visible
        bmi @end
        lda vga_ptr+1
        lsr a
        sta vga_buffer+1
        lda vga_ptr
        ror a
        sta vga_buffer
        lda vga_x
        clc
        adc vga_buffer
        ldx #15
        jsr crtc_write
        lda vga_buffer+1
        and #$07
        dex
        jsr crtc_write
@end:
        rts

vga_bits:
        .byte $01, $02, $04, $08, $10, $20, $40, $80
        