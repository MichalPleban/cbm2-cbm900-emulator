
.include "../sd/defs.asm"

.code

.ifdef PRG
.word $4000
.endif

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

.org $4000

        lda #$0f
        sta $00
        sta $01
        jsr fat32_init
        bcs @error
        lda #<filename
        ldy #>filename
        jsr fat32_find_file
        bcs @error
        lda #$00
        ldy #$53
        jsr fat32_scan_file
        bcs @error
        lda #$30
        sta sd_sector
        lda #$0
        sta sd_sector+1
        sta sd_sector+2
        sta sd_sector+3
        lda #$00
        ldy #$53
        jsr fat32_translate
        bcs @error
        jsr fat32_set_buffer
        jsr sd_read
@error:      
        sta $5FFF  
        rts

filename:   .byt "DISK4   BIN"
        
.include "../sd/init.asm"
.include "../sd/access.asm"
.include "../sd/fat32.asm"
        
sd_output:
        sta $D907
        nop
        nop
        nop
        nop
        lda $D907
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
        sta $D907
        iny
        sty sd_loop
        bne @loop
        inc sd_ptr+1
        dec sd_loop+1
        bne @loop
        pla
        sta $01
        rts
                
.ifdef PRG
.res 16, $AA
.endif
