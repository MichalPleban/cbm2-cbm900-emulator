

.ifdef LOGGER

logger_init:
        lda IND_REG
        pha
        lda #$0F
        sta IND_REG
        lda #$FD
        sta logger_ptr
        lda #$40
        sta logger_ptr+1
        lda #$00
        tay
        sta (logger_ptr),y
        iny
        sta (logger_ptr),y
        lda #$41
        iny
        sta (logger_ptr),y
        pla
        sta IND_REG
        rts
        
logger_store:
        php
        tax
        sei
        lda IND_REG
        pha
        lda #$0F
        sta IND_REG
        ldy #1
        lda (logger_ptr),y
        sta logger_tmp
        iny
        lda (logger_ptr),y
        sta logger_tmp+1
        txa
        ldy #0
        sta (logger_tmp),y
        inc logger_tmp
        bne @save
        inc logger_tmp+1
        bpl @save
        lda #$41
        sta logger_tmp+1
        sta (logger_ptr),y
@save:  
        iny
        lda logger_tmp
        sta (logger_ptr),y
        iny
        lda logger_tmp+1
        sta (logger_ptr),y
        pla
        sta IND_REG
        plp
        rts       

.endif
