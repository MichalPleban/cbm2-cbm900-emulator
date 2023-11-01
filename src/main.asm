
.include "defs.asm"

.code

.ifdef PRG
.word $0400
.endif

.org $0400

start:
        sei
        cld
        ldx #$FF
        txs
        lda #$0F
        sta IND_REG
        jsr init
        jsr emul_init
        jsr kbd_init
        jsr irq_init
        jsr screen_init
        jsr serial_init
        lda #<banner
        ldy #>banner
        jsr screen_string
        lda #<banner
        ldy #>banner
        jsr serial_string
;        jsr test
        cli
loop:
        jmp loop
        
        
init:
        lda #$D0
        sta SCREEN+1
        lda #$00
        sta SCREEN
        ldx #$D8
        stx CRTC+1
        sta CRTC
        inx
        stx CHIPSET+1
        sta CHIPSET
        inx
        inx
        stx SID+1
        sta SID
        inx
        stx CIA+1
        sta CIA
        inx
        inx
        stx TPI1+1
        sta TPI1
        inx
        stx TPI2+1
        sta TPI2
        rts

test:
        jsr nmi_handler
        rts
        
        
.include "emul.asm"
.include "cbm/screen.asm"
.include "cbm/irq.asm"
.include "cbm/kbd.asm"
.include "cbm/serial.asm"

banner:
        .byt "Commodore 900 emulation layer version 0.1.0, (C) 2023 Michal Pleban", $0D, $0A, $0D, $0A, $00
        
.res 16, $AA
