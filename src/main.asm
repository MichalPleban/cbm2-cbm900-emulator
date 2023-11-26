
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
        ; Pull /RESET low
        ldy #6
        lda (CHIPSET),y
        ora #$01
        sta (CHIPSET),y
        
        jsr emul_init
        jsr kbd_init
        jsr irq_init
        jsr screen_init
        jsr serial_init
        lda #<banner
        ldy #>banner
        jsr screen_string
        cli
        
        ; Pull /RESET high
        ldy #6
        lda (CHIPSET),y
        and #$FE
        sta (CHIPSET),y
        
        ; Main loop
@loop:
        jsr disk_handle
        jmp @loop  

init:
        ; Initialize chip pointers
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
        stx ACIA+1
        sta ACIA
        inx
        stx TPI1+1
        sta TPI1
        inx
        stx TPI2+1
        sta TPI2
        
        ; Copy routines to bank 15        
        ldy #$00
        sty scratchpad
        lda #$05
        sta scratchpad+1
@loop:
        lda bank15_0500, y
        sta (scratchpad), y
        iny
        bne @loop

        rts

banner:
        .byt "Commodore C900 emulation layer version 0.2.2, (C) 2023 Michal Pleban", $0D, $0A, $00

test:
        jsr nmi_handler
        rts

.include "trace.asm"

        .res ($0500-*), $FF

; ------------------------------------------------------------------------
; Routines to be copied to bank 15
; ------------------------------------------------------------------------
bank15_0500:

sasi_load_bank15:
        lda #$0F
        sta EXEC_REG
        ; Enable access to RAM & XOR A15
        lda $D906
        ora #$16
        sta $D906
        lda #$08
        sta IND_REG
        lda #$00
        sta scratchpad
        lda #$80
        sta scratchpad+1
        ldy #$1F
@loop:
        lda (scratchpad), y
        sta sasi_command, y 
        dey
        bpl @loop
        ; Disable access to RAM
        lda $D906
        and #$E9
        sta $D906
        lda #$0F
        sta IND_REG
        lda #$01
        sta EXEC_REG
        rts

sasi_save_bank15:
        lda #$0F
        sta EXEC_REG
        ; Enable access to RAM & XOR A15
        lda $D906
        ora #$16
        sta $D906
        lda #$08
        sta IND_REG
        lda #$00
        sta scratchpad
        lda #$80
        sta scratchpad+1
        ldy #$1F
@loop:
        lda sasi_command, y
        sta (scratchpad), y 
        dey
        bpl @loop
        ; Disable access to RAM
        lda $D906
        and #$E9
        sta $D906
        lda #$0F
        sta IND_REG
        lda #$01
        sta EXEC_REG
        rts

        .res ($0600-*), $FF
        
.include "emul.asm"
.include "cbm/screen.asm"
.include "cbm/irq.asm"
.include "cbm/kbd.asm"
.include "cbm/serial.asm"

.ifdef PRG
.res 16, $AA
.endif
