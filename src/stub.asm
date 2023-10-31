
.ifdef PRG
.word $03FC
.endif

.org $03FC

        lda #$01
        sta $00

.res 16, $AA
