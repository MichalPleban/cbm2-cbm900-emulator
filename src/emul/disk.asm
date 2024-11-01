
.macro  SD_WRITE value
        lda #value
        jsr sd_output
.endmacro
.macro  SD_WRITE_MEM value
        lda value
        jsr sd_output
.endmacro
.macro  BANK_SAVE
        ldx $00
        stx $01
.endmacro
.macro  BANK_RESTORE
        ldx #$0F
        stx $01
.endmacro

disk_init:
        lda #$00
        sta disk_request
        sta disk_irq
        jsr sd_init
        rts

; ------------------------------------------------------------------------
; Handle disk DMA access from the Z8000
; ------------------------------------------------------------------------

disk_handle:
        bit disk_request
        bmi @handle
        rts
@handle:
        sei
        
        ; Halt the Z8000
        ldy #6
        lda (CHIPSET),y
        ora #$04
        sta (CHIPSET),y

        ; Clear pending request flag
        lda #$00
        sta disk_request
        
        ; Copy SASI command block from Z8000 RAM to bank 15
        jsr sasi_load_bank15
        
        ; Copy SASI command block from bank 15 to bank 1
        lda #<sasi_command
        sta scratchpad
        lda #>sasi_command
        sta scratchpad+1
        ldy #$1F
@loop2:
        lda (scratchpad),y
        sta sasi_command,y
        dey
        bpl @loop2
        
        ; Check which disk drive is being addressed
        lda sasi_command+12
        cmp #$FF
        bne @disk1
        lda #$00
        .byt $2C
@disk1:
        lda #$10
        sta disk_unit
        
.ifdef DEBUG
        lda #<disk_banner1
        ldy #>disk_banner1
        jsr serial_string
        ldx disk_unit
        lda sasi_command,x
        jsr debug_hex
        lda #<disk_banner2
        ldy #>disk_banner2
        jsr serial_string
        lda disk_unit
        lsr a
        lsr a
        lsr a
        lsr a
        jsr debug_hex
        lda #$0D
        jsr serial_output
        lda #$0A
        jsr serial_output
.endif

        ; Fake status 
        ldx disk_unit
        lda sasi_command,x
        cmp #$08
        bne @not_read
        jmp disk_read
@not_read:
        cmp #$0A
        bne @not_write
        jmp disk_write
@not_write:
        lda #$00
disk_finish:
        ldx disk_unit
        sta sasi_command+12,x

.ifdef DEBUG
        lda #<disk_banner3
        ldy #>disk_banner3
        jsr serial_string
        ldx disk_unit
        lda sasi_command+12,x
        jsr debug_hex
        lda #$0D
        jsr serial_output
        lda #$0A
        jsr serial_output
.endif

        ; Copy SASI command block back to bank 15
        lda #<sasi_command
        sta scratchpad
        lda #>sasi_command
        sta scratchpad+1
        ldy #$1F
@loop3:
        lda sasi_command,y
        sta (scratchpad),y
        dey
        bpl @loop3

        ; Copy SASI command block from bank 15 to Z8000 RAM
        jsr sasi_save_bank15
        
        ; Restart the Z8000
        ldy #6
        lda (CHIPSET),y
        and #$FB
        sta (CHIPSET),y
        
        ; Issue IRQ to the Z8000
        lda #$80
        sta disk_irq
        jsr irq_issue

@end:
        cli
        rts

; ------------------------------------------------------------------------
; Block read from the disk
; ------------------------------------------------------------------------
        
disk_read:
        ; Disable floppy
        bit floppy_present
        bmi @floppy_present
        lda #$92
        ldx disk_unit
        bne @finish

@floppy_present:        
.ifdef DEBUG
        lda #<read_banner
        ldy #>read_banner
        jsr serial_string        
.endif

        jsr disk_sector
        jsr disk_translate
        jsr sd_read
        bcc @ok
        lda #$A1
        .byt $2C
@ok:        
        lda #$80
@finish:
        jmp disk_finish

; ------------------------------------------------------------------------
; Block write from the disk
; ------------------------------------------------------------------------
        
disk_write:
        ; Disable floppy
        bit floppy_present
        bmi @floppy_present
        lda #$92
        ldx disk_unit
        bne @finish

@floppy_present:
.ifdef DEBUG
        lda #<write_banner
        ldy #>write_banner
        jsr serial_string        
.endif

        jsr disk_sector
        jsr disk_translate
        jsr sd_write
        bcc @ok
        lda #$A1
        .byt $2C
@ok:        
        lda #$80
@finish:
        jmp disk_finish

; ------------------------------------------------------------------------
; Copy sector number and address to zero page
; ------------------------------------------------------------------------

disk_sector:
        ldx disk_unit
        lda #0
        sta sd_sector+3
        lda sasi_command+1,x
        and #$1F
        sta sd_sector+2
        lda sasi_command+2,x
        sta sd_sector+1
        lda sasi_command+3,x
        sta sd_sector
        lda sasi_command+4,x
        sta disk_sectors
        lda sasi_command+6,x
        sta sd_bank
        lda sasi_command+7,x
        sta sd_ptr+1
        lda sasi_command+8,x
        sta sd_ptr

.ifdef DEBUG
        lda #<sector_banner1
        ldy #>sector_banner1
        jsr serial_string
        lda sd_sector+1
        jsr debug_hex
        lda sd_sector
        jsr debug_hex
        lda #<sector_banner2
        ldy #>sector_banner2
        jsr serial_string
        lda disk_sectors
        jsr debug_hex
        lda #<sector_banner3
        ldy #>sector_banner3
        jsr serial_string
        lda sd_bank
        jsr debug_hex
        lda #'|'
        jsr serial_output
        lda sd_ptr+1
        jsr debug_hex
        lda sd_ptr
        jsr debug_hex
        lda #$0D
        jsr serial_output
        lda #$0A
        jsr serial_output
.endif

        rts
        
; ------------------------------------------------------------------------
; Translate logical sector to physical sector on the SD card
; ------------------------------------------------------------------------

disk_translate:
        ldx disk_unit
        beq @hdd
        lda #<fd_mapping
        ldy #>fd_mapping
        jsr fat32_translate
        jmp @end
@hdd:
        lda #<hd_mapping
        ldy #>hd_mapping
        jsr fat32_translate
       
@end:
.ifdef DEBUG
        lda #<sector_banner4
        ldy #>sector_banner4
        jsr serial_string
        lda sd_sector+1
        jsr debug_hex
        lda sd_sector
        jsr debug_hex
        lda #$0D
        jsr serial_output
        lda #$0A
        jsr serial_output
.endif

        lda #$00
        sta sd_bank_flags
        rts

; ------------------------------------------------------------------------
; Clear IRQ flag
; ------------------------------------------------------------------------
                
disk_clear:
        lda #$00
        sta disk_irq
        jmp irq_issue

; ------------------------------------------------------------------------
; Print 8.3 filename to the screen
;     A:Y - pointer ot the filename
; ------------------------------------------------------------------------

filename_print:
        sta scratchpad
        sta scratchpad+2
        sty scratchpad+1
        sty scratchpad+3
        
        lda scratchpad+2
        clc
        adc #7
        sta scratchpad+2
        lda scratchpad+3
        adc #0
        sta scratchpad+3

@find_spaces:
        ldx #0
        lda (scratchpad+2,x)
        cmp #$20
        bne @not_space
        lda scratchpad+2
        sec
        sbc #1
        sta scratchpad+2
        lda scratchpad+3
        sbc #0
        sta scratchpad+3
        lda scratchpad+2
        cmp scratchpad
        bne @find_spaces
        
@not_space:
        lda scratchpad
        sta scratchpad+4
        lda scratchpad+1
        sta scratchpad+5
@print_name:
        ldx #0
        lda (scratchpad,x)
        jsr screen_output
        lda scratchpad
        cmp scratchpad+2
        beq @name_end
        clc
        adc #1
        sta scratchpad
        lda scratchpad+1
        adc #0
        sta scratchpad+1
        bne @print_name
        
@name_end:
        lda #$2E
        jsr screen_output      
        
        lda scratchpad+4
        clc
        adc #8
        sta scratchpad+4
        lda scratchpad+5
        adc #0
        sta scratchpad+5
        ldx #0
        lda (scratchpad+4,x)
        jsr screen_output
        inc scratchpad+4
        bne @second_char
        inc scratchpad+5
@second_char:        
        ldx #0
        lda (scratchpad+4,x)
        jsr screen_output
        inc scratchpad+4
        bne @third_char
        inc scratchpad+5
@third_char:        
        ldx #0
        lda (scratchpad+4,x)
        jsr screen_output
        
        rts        
        



.ifdef DEBUG
disk_banner1:
        .byt "Disk command ", 0
disk_banner2:
        .byt " issued to unit ", 0
disk_banner3:
        .byt "Command status: ", 0
read_banner:
        .byt "Disk read:", 0
write_banner:
        .byt "Disk write:", 0
sector_banner1:
        .byt " sector ", 0
sector_banner2:
        .byt ", count ", 0
sector_banner3:
        .byt " to location ", 0
sector_banner4:
        .byt "Physical sector: ", 0
.endif

; ------------------------------------------------------------------------
; SD card access primitives
; ------------------------------------------------------------------------

sd_output:
        ldy #7
        sta (CHIPSET),y
        lda (CHIPSET),y
        rts

sd_read_loop:
        ldy #3
        lda #<sd_bank
        sta scratchpad
        lda #>sd_bank
        sta scratchpad+1
@loop:
        lda sd_bank,y
        sta (scratchpad),y
        dey
        bpl @loop
        jmp sd_read_bank15

sd_write_loop:
        ldy #3
        lda #<sd_bank
        sta scratchpad
        lda #>sd_bank
        sta scratchpad+1
@loop:
        lda sd_bank,y
        sta (scratchpad),y
        dey
        bpl @loop
        jmp sd_write_bank15

; ------------------------------------------------------------------------
; Display disk error message
; Input:
;       A - error number
; Output:
;       A:Y - pointer to error text
;       X - destroyed
; ------------------------------------------------------------------------

disk_error:
        sta scratchpad
        ldx #0
        lda #<disk_errors
        sta screen_ptr
        lda #>disk_errors
        sta screen_ptr+1
@loop:
        lda (screen_ptr,x)
        beq @found
        cmp scratchpad
        beq @found
@loop2:
        inc screen_ptr
        bne @notzero
        inc screen_ptr+1
@notzero:
        lda (screen_ptr,x)
        bne @loop2
        inc screen_ptr
        bne @loop
        inc screen_ptr+1
        bne @loop
@found:
        inc screen_ptr
        bne @notzero2
        inc screen_ptr+1
@notzero2:
        lda screen_ptr
        ldy screen_ptr+1
        rts
                
disk_errors:
        .byt $01, "SD card not found", $00
        .byt $02, "SD card init error", $00
        .byt $03, "SD card init error", $00
        .byt $04, "SD card is not SDHC", $00
        .byt $05, "SD card init error", $00
        .byt $11, "Sector read error", $00
        .byt $12, "Sector read error", $00
        .byt $21, "Sector write error", $00
        .byt $22, "Sector write error", $00
        .byt $23, "Sector write error", $00
        .byt $31, "Master boot record not found", $00
        .byt $32, "Partition is not FAT32", $00
        .byt $33, "FAT32 boot sector not found", $00
        .byt $41, "File not found", $00
        .byt $51, "File is too fragmented", $00
        .byt $52, "Seek past file end", $00
        .byt $00, "Unknown error", $00

                
.include "../sd/init.asm"
.include "../sd/access.asm"
.include "../sd/fat32.asm"
