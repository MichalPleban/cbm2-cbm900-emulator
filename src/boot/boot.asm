

.macro  SD_WRITE value
        lda #value
        jsr sd_output
.endmacro

.macro  SD_WRITE_MEM value
        lda value
        jsr sd_output
.endmacro

.macro  BANK_SAVE
        ldx $01
        stx bank_save
        ldx $00
        stx $01
.endmacro

.macro  BANK_RESTORE
        ldx bank_save
        stx $01
.endmacro

boot_file:
        sei
        
        ; Init the SD card and look for the emulation file
        jsr fat32_init
        bcc @initialized
        jmp @error
@initialized:
        lda #<emul_filename
        ldy #>emul_filename
        jsr fat32_find_file
        bcc @initialize_ok
        jmp @error        
@initialize_ok:
        lda #<file_mapping
        ldy #>file_mapping
        jsr fat32_scan_file
        bcs @error        
        
        ; Load file into memory
        lda #0
        sta fat32_pointers+FILE_SECTOR
        sta fat32_pointers+FILE_SECTOR+1
        sta fat32_ptr_1+1
        lda #1
        sta fat32_ptr_1
        
@loop:
        ; Load one sector into buffer
        lda fat32_pointers+FILE_SECTOR
        sta sd_sector
        lda fat32_pointers+FILE_SECTOR+1
        sta sd_sector+1
        lda #0
        sta sd_sector+2
        lda #0
        sta sd_sector+3
        lda #<file_mapping
        ldy #>file_mapping
        jsr fat32_translate
        bcc @continue
        cmp #$52
        beq @ok
        bne @error
@continue:
        jsr fat32_set_buffer
        BANK_RESTORE
        jsr sd_read
        BANK_SAVE
        bcs @error
        
        ; Copy buffer to the RAM
        lda #$01
        sta $01
        ldy #0
        lda fat32_ptr_1+1
        bne @not_first
        iny
        iny
@not_first:
@loop2:
        lda fat32_buffer,y
        sta (fat32_ptr_1),y
        iny
        bne @loop2
        inc fat32_ptr_1+1
@loop3:
        lda fat32_buffer+256,y
        sta (fat32_ptr_1),y
        iny
        bne @loop3
        lda #$0F
        sta $01
        inc fat32_ptr_1+1
        
        ; Increase file pointer        
        inc fat32_pointers+FILE_SECTOR
        bne @loop
        inc fat32_pointers+FILE_SECTOR+1
        bne @loop
        lda #$52
        
@error:
        ; Report error and return
        sec
        rts
        
@ok:
        clc        
        rts

sd_output:
        sta CHIPSET_BASE + REG_SD_CARD
        nop
        nop
        nop
        nop
        lda CHIPSET_BASE + REG_SD_CARD
        rts

sd_read_loop:
        lda $01
        pha
        lda sd_bank
        sta $01
        lda #2
        sta sd_loop+1
        lda #0
        sta sd_loop
@loop:
        SD_WRITE $FF
        ldy sd_loop
        sta (sd_ptr),y
        iny
        sty sd_loop
        bne @loop
        inc sd_ptr+1
        dec sd_loop+1
        bne @loop
        pla
        sta $01
        rts
                
sd_write_loop:
        lda $01
        pha
        lda sd_bank
        sta $01
        lda #2
        sta sd_loop+1
        lda #0
        sta sd_loop
@loop:
        ldy sd_loop
        lda (sd_ptr),y
        sta CHIPSET_BASE + REG_SD_CARD
        iny
        sty sd_loop
        bne @loop
        inc sd_ptr+1
        dec sd_loop+1
        bne @loop
        pla
        sta $01
        rts

emul_filename:
        .byt $45, $4D, $55, $4C, $43, $42, $4D, $32, $42, $49, $4e ; "EMULCBM2BIN"

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

