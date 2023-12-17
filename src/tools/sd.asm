
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

.org $4000

        jsr sd_init
        sta $5fff
        bcs @error

@read:
        lda #$00
        sta sd_sector
        lda #$00
        sta sd_sector+1
        sta sd_sector+2
        sta sd_sector+3
        lda #$0F
        sta sd_bank
        lda #$00
        sta sd_ptr
        lda #$50
        sta sd_ptr+1
        jsr sd_read
        sta $5ffe
        bcs @error

        lda #$02
        sta sd_sector
        lda #$00
        sta sd_sector+1
        sta sd_sector+2
        sta sd_sector+3
        lda #$0F
        sta sd_bank
        lda #$00
        sta sd_ptr
        lda #$50
        sta sd_ptr+1
        jsr sd_write
        sta $5ffd
        bcs @error

@error:        
        rts

.include "../sd/init.asm"
.include "../sd/access.asm"
        
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
