
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Menu entry point
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menu_enter:
        lda #$80
        sta menu_visible
        
menu_redraw:
        jsr menu_background
        jsr menu_options

@main_loop:
        jsr kbd_fetch
        
        ; F1 - Select floppy image
        cmp #$C0
        bne @not_f1
        jsr menu_select_floppy
        jsr save_config        
        jmp menu_redraw
        
@not_f1: 
        ; F2 - Eject floppy
        cmp #$C1
        bne @not_f2
        lda #$00
        sta floppy_present
        jsr save_config        
        jmp menu_redraw

@not_f2:
        ; F3 - Select hard disk image
        cmp #$C2
        bne @not_f3
        jsr menu_select_hdd
        jsr save_config        
        jmp menu_redraw
        
@not_f3: 
        ; F5 - Video configuration
        cmp #$C4
        bne @not_f5
        jsr menu_video
        jsr save_config        
        jmp menu_redraw

@not_f5: 
        ; F6 - Reset config
        cmp #$C5
        bne @not_f6
        jsr menu_reset_config
        jsr save_config        
        jmp menu_redraw

@not_f6:
        ; F8 - Reset CPU, only if started
        bit z8000_started
        bpl @not_f8
        cmp #$C7
        bne @not_f8
        ldy #6
        lda (CHIPSET),y
        ora #$01
        sta (CHIPSET),y
        bne @exit

@not_f8:
        cmp #27
        bne @main_loop

@exit:
        lda #$00
        sta menu_visible
        ; Clear IRQ flag 
        sta scc_irq_pending
        
        rts
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Draw menu key assignments
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menu_options:
        ldx #24
        ldy #6
        jsr screen_position
        lda #<menu_option_1
        ldy #>menu_option_1
        jsr screen_string
        ldx #29
        ldy #7
        jsr screen_position
        bit floppy_present
        bpl @floppy_ejected
        lda #<fd_filename
        ldy #>fd_filename
        jsr filename_print
        jmp @after_floppy        
@floppy_ejected:
        lda #<menu_option_1b
        ldy #>menu_option_1b
        jsr screen_string
@after_floppy:
        ldx #24
        ldy #9
        jsr screen_position
        lda #<menu_option_2
        ldy #>menu_option_2
        jsr screen_string
        ldx #24
        ldy #11
        jsr screen_position
        lda #<menu_option_3
        ldy #>menu_option_3
        jsr screen_string
        ldx #29
        ldy #12
        jsr screen_position
        lda #<hd_filename
        ldy #>hd_filename
        jsr filename_print
        ldx #24
        ldy #14
        jsr screen_position
        lda #<menu_option_4
        ldy #>menu_option_4
        jsr screen_string
        ldx #24
        ldy #16
        jsr screen_position
        lda #<menu_option_5
        ldy #>menu_option_5
        jsr screen_string
        bit z8000_started
        bpl @not_started
        ldx #24
        ldy #18
        jsr screen_position
        lda #<menu_option_6
        ldy #>menu_option_6
        jsr screen_string
@not_started:
        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Draw menu key assignments
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menu_list_files:

        ; Load files from the disk
        lda #<file_list
        ldy #>file_list
        jsr fat32_list_files
        jsr menu_sort_files

        ; Draw the files on the screen        
        jsr menu_background
        lda #0
        sta menu_file_pos

        ; Copy filename to a temp buffer
@loop_2:
        ldx menu_file_pos
        lda menu_file_mul, x
        tax
        lda file_list, x
        beq @end
        ldy #0
@loop_1:
        lda file_list, x
        sta menu_file_buf, y
        inx
        iny
        cpy #11
        bne @loop_1
        
        ; Position the cursor and write the filename
        ldx menu_file_pos
        lda menu_file_y, x
        tay
        lda menu_file_x, x
        tax
        inx
        inx
        jsr screen_position
        lda #<menu_file_buf
        ldy #>menu_file_buf
        jsr screen_string
        
        inc menu_file_pos
        bne @loop_2
        
@end:
        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Select a file on the screen with keyboard
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menu_select_file:
        lda #0
        sta menu_file_pos
        
@main_loop:
        jsr menu_mark_file
@check_key:
        jsr kbd_fetch
        
        cmp #$83
        bne @not_down
        jsr menu_unmark_file
        ldx menu_file_pos
        inx
        cpx menu_file_max
        beq @main_loop
        stx menu_file_pos
        jmp @main_loop
        
@not_down:
        cmp #$80
        bne @not_up
        jsr menu_unmark_file
        ldx menu_file_pos
        beq @main_loop
        dex
        stx menu_file_pos
        jmp @main_loop
        
@not_up:
        cmp #$0D
        bne @not_return
        clc
        rts
        
@not_return:
        cmp #$27
        bne @check_key
        sec
        rts
                
menu_mark_file:
        ldx menu_file_pos
        lda menu_file_y, x
        tay
        lda menu_file_x, x
        tax
        jsr screen_position
        lda #'>'
        jsr screen_output
        ldx menu_file_pos
        lda menu_file_y, x
        tay
        lda menu_file_x, x
        clc
        adc #14
        tax
        jsr screen_position
        lda #'<'
        jsr screen_output
        rts

menu_unmark_file:
        ldx menu_file_pos
        lda menu_file_y, x
        tay
        lda menu_file_x, x
        tax
        jsr screen_position
        lda #' '
        jsr screen_output
        ldx menu_file_pos
        lda menu_file_y, x
        tay
        lda menu_file_x, x
        clc
        adc #14
        tax
        jsr screen_position
        lda #' '
        jsr screen_output
        rts
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Select a floppy image file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menu_select_floppy:
        jsr menu_list_files
        jsr menu_select_file
        bcs @end
        
        ; Try to map the file
        lda menu_file_pos
        tax
        lda menu_file_mul, x
        clc
        adc #<file_list
        pha
        lda #>file_list
        adc #0
        tay
        pla
        jsr fat32_find_file
        bcs @end
        lda #<fd_mapping
        ldy #>fd_mapping
        jsr fat32_scan_file
        bcs @end
        
        ; Copy filename
        lda menu_file_pos
        tax
        lda menu_file_mul, x
        tax
        ldy #0
@loop:
        lda file_list, x
        sta fd_filename, y
        inx
        iny
        cpy #11
        bne @loop
        lda #$80
        sta floppy_present

        clc
@end:
        rts
                
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sort file list
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menu_sort_files:
        ; Find the maximum number of files
        ldx #0
@loop:
        lda menu_file_mul, x
        tay
        lda file_list, y
        beq @found_max
        inx
        bne @loop
@found_max:
        stx menu_file_max
        lda #0
        sta menu_file_pos
        lda #>file_list
        sta menu_file_ptr+1
        sta menu_file2_ptr+1
        
        ; Iterate over file pairs
@next_first_file:
        ldy menu_file_pos
        cpy menu_file_max
        beq @end
        sty menu_file2_pos
@next_second_file:
        ldy menu_file_pos
        lda menu_file_mul,y
        sta menu_file_ptr
        inc menu_file2_pos
        ldy menu_file2_pos
        cpy menu_file_max
        bne @second_file
        inc menu_file_pos
        bne @next_first_file
@second_file:
        lda menu_file_mul,y
        sta menu_file2_ptr
        
        ; Compare two file names
        ldx #0
        stx menu_name_pos
@next_byte:
        lda (menu_file_ptr,x)
        cmp (menu_file2_ptr,x)
        bne @files_differ
        inc menu_file_ptr
        inc menu_file2_ptr
        inc menu_name_pos
        lda menu_name_pos
        cmp #11
        bne @next_byte
        jmp @next_second_file
        
@files_differ:
        bcc @next_second_file
        ; Swap two filenames
        ldy menu_file_pos
        lda menu_file_mul,y
        sta menu_file_ptr
        ldy menu_file2_pos
        lda menu_file_mul,y
        sta menu_file2_ptr
        ldy #10
@swap_loop:
        lda (menu_file_ptr,x)
        pha
        lda (menu_file2_ptr,x)
        sta (menu_file_ptr,x)
        pla
        sta (menu_file2_ptr,x)
        inc menu_file_ptr
        inc menu_file2_ptr
        dey
        bpl @swap_loop
        bmi @next_second_file
        
@end:   
        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Select a hard disk image file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menu_select_hdd:
        jsr menu_list_files
        jsr menu_select_file
        bcs @end
        
        ; Try to map the file
        lda menu_file_pos
        tax
        lda menu_file_mul, x
        clc
        adc #<file_list
        pha
        lda #>file_list
        adc #0
        tay
        pla
        jsr fat32_find_file
        bcs @end
        lda #<hd_mapping
        ldy #>hd_mapping
        jsr fat32_scan_file
        bcs @end
        
        ; Copy filename
        lda menu_file_pos
        tax
        lda menu_file_mul, x
        tax
        ldy #0
@loop:
        lda file_list, x
        sta hd_filename, y
        inx
        iny
        cpy #11
        bne @loop

        clc        
@end:
        rts
                
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Restore default configuration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menu_reset_config:
        ldy #_config_end-_config_start-1
@loop:
        lda _config_start,y
        sta config_data,y
        dey
        bpl @loop
        rts
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Video configuration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


menu_option_1:
        .byt "F1:  Select floppy image", 0
menu_option_1b:
        .byt "(floppy ejected)", 0
menu_option_2:
        .byt "F2:  Eject floppy", 0
menu_option_3:
        .byt "F3:  Select hard disk image", 0
menu_option_4:
        .byt "F5:  Video configuration", 0
menu_option_5:
        .byt "F6:  Restore configuration", 0
menu_option_6:
        .byt "F8:  Reset Z8000", 0

menu_file_buf:
        .res 12, $00
menu_file_mul:
        .byt 0, 11, 22, 33, 44, 55, 66, 77, 88, 99, 110, 121, 132, 143, 154, 165, 176, 187, 198, 209, 220, 231, 242, 253
menu_file_x:
        .byt 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40
menu_file_y:
        .byt 6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 17, 6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 17
        
.include "../tools/config.asm"

