
.code

.ifdef PRG
.byt $00, $04
.endif

.org $0400
        jmp $0400

.ifdef PRG
.res 16, $AA
.endif

