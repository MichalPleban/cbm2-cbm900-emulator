
load_config:
        lda #0
        sta sd_sector
        sta sd_sector+1
        sta sd_sector+2
        sta sd_sector+3
        lda #<config_mapping
        ldy #>config_mapping
        jsr fat32_translate
        lda $00
        ora #$80
        sta sd_bank
        lda #<config_data
        sta sd_ptr
        lda #>config_data
        sta sd_ptr+1
        jsr sd_read
        rts
        
save_config:
        lda #0
        sta sd_sector
        sta sd_sector+1
        sta sd_sector+2
        sta sd_sector+3
        lda #<config_mapping
        ldy #>config_mapping
        jsr fat32_translate
        lda $00
        ora #$80
        sta sd_bank
        lda #<config_data
        sta sd_ptr
        lda #>config_data
        sta sd_ptr+1
        jsr sd_write
        rts
        


