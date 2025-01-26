
.include "defs.asm"
.include "../cbm2/defs.asm"
.include "../chipset.asm"

.ifdef PRG
.data
.byt $00, $10
.endif

.code
.org $1000

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

boot_emulation:
        ; Init the SD card and look for the emulation.file
        jsr fat32_init
        bcs @error
        lda #<emul_filename
        ldy #>emul_filename
        jsr fat32_find_file
        bcs @error        
        lda #<file_mapping
        ldy #>file_mapping
        jsr fat32_scan_file
        bcs @error        
        
        ; Load the file into memory
        lda #0
        sta fat32_pointers+FILE_SECTOR
        sta fat32_pointers+FILE_SECTOR+1
        sta fat32_pointers+FILE_SECTOR+2
        sta fat32_pointers+FILE_SECTOR+3
        
@loop:
        lda fat32_pointers+FILE_SECTOR
        sta sd_sector
        lda fat32_pointers+FILE_SECTOR+1
        sta sd_sector+1
        lda fat32_pointers+FILE_SECTOR+2
        sta sd_sector+2
        lda fat32_pointers+FILE_SECTOR+3
        sta sd_sector+3
        lda #<file_mapping
        ldy #>file_mapping
        jsr fat32_translate
        jsr fat32_set_buffer
        jsr fat32_load_sector
@error:
        sta $1FFF
        rts

sd_output:
        sta CHIPSET_BASE + SD_CARD
        nop
        nop
        nop
        nop
        lda CHIPSET_BASE + SD_CARD
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
        sta CHIPSET_BASE + SD_CARD
        iny
        sty sd_loop
        bne @loop
        inc sd_ptr+1
        dec sd_loop+1
        bne @loop
        pla
        sta $01
        rts

.include "../sd/init.asm"
.include "../sd/access.asm"
.include "../sd/fat32.asm"

emul_filename:  .byt "EMULCBM2BIN"

.res ($2000-*),$FF
