
; Memory pointers for the FAT32 driver (see src/memory.txt)
file_list = $F800
fd_mapping = $F900
hd_mapping = $FA00
fat32_buffer = $FB00
config_data = $FD00
config_mapping = $FF00

floppy_present = config_data + $12
hd_filename = config_data + $13
fd_filename = config_data + $1E


machine_init:
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
        stx SID+1
        sta SID
        inx
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

