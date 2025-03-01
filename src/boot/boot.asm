

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
        bcs @error        
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
        sta $1FFF
        cli
        rts
        
@ok:
        ; Start the emulation code at $010400
        lda #$A9
        sta $03FC
        lda #$01    ; LDA #$01
        sta $03FD
        lda #$85
        sta $03FE
        lda #$00    ; STA $00
        sta $03FF
        jmp $03FC

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

.include "../sd/init.asm"
.include "../sd/access.asm"
.include "../sd/fat32.asm"

