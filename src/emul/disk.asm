
FD_START = 40992
HD_START = 43312

.macro  SD_WRITE value
        lda #value
        jsr sd_output
.endmacro
.macro  SD_WRITE_MEM value
        lda value
        jsr sd_output
.endmacro

disk_init:
        lda #$00
        sta disk_request
        sta disk_irq
        jsr sd_init
        rts

; ------------------------------------------------------------------------
; Handle disk DMA access from the Z8000
; ------------------------------------------------------------------------

disk_handle:
        bit disk_request
        bmi @handle
        rts
@handle:
        sei
        
        ; Halt the Z8000
        ldy #6
        lda (CHIPSET),y
        ora #$04
        sta (CHIPSET),y

        ; Clear pending request flag
        lda #$00
        sta disk_request
        
        ; Copy SASI command block from Z8000 RAM to bank 15
        jsr sasi_load_bank15
        
        ; Copy SASI command block from bank 15 to bank 1
        lda #<sasi_command
        sta scratchpad
        lda #>sasi_command
        sta scratchpad+1
        ldy #$1F
@loop2:
        lda (scratchpad),y
        sta sasi_command,y
        dey
        bpl @loop2
        
        ; Check which disk drive is being addressed
        lda sasi_command+12
        cmp #$FF
        bne @disk1
        lda #$00
        .byt $2C
@disk1:
        lda #$10
        sta disk_unit
        
.ifdef DEBUG
        lda #<disk_banner1
        ldy #>disk_banner1
        jsr serial_string
        ldx disk_unit
        lda sasi_command,x
        jsr debug_hex
        lda #<disk_banner2
        ldy #>disk_banner2
        jsr serial_string
        lda disk_unit
        lsr a
        lsr a
        lsr a
        lsr a
        jsr debug_hex
        lda #$0D
        jsr serial_output
        lda #$0A
        jsr serial_output
.endif

        ; Fake status 
        ldx disk_unit
        lda sasi_command,x
        cmp #$08
        bne @not_read
        jmp disk_read
@not_read:
        cmp #$0A
        bne @not_write
        jmp disk_write
@not_write:
        lda #$00
disk_finish:
        ldx disk_unit
        sta sasi_command+12,x

.ifdef DEBUG
        lda #<disk_banner3
        ldy #>disk_banner3
        jsr serial_string
        ldx disk_unit
        lda sasi_command+12,x
        jsr debug_hex
        lda #$0D
        jsr serial_output
        lda #$0A
        jsr serial_output
.endif

        ; Copy SASI command block back to bank 15
        lda #<sasi_command
        sta scratchpad
        lda #>sasi_command
        sta scratchpad+1
        ldy #$1F
@loop3:
        lda sasi_command,y
        sta (scratchpad),y
        dey
        bpl @loop3

        ; Copy SASI command block from bank 15 to Z8000 RAM
        jsr sasi_save_bank15
        
        ; Restart the Z8000
        ldy #6
        lda (CHIPSET),y
        and #$FB
        sta (CHIPSET),y
        
        ; Issue IRQ to the Z8000
        lda #$80
        sta disk_irq
        jsr irq_issue

@end:
        cli
        rts

; ------------------------------------------------------------------------
; Block read from the disk
; ------------------------------------------------------------------------
        
disk_read:
        ; Disable floppy
        lda #$70
        ldx disk_unit
        bne @ok

.ifdef DEBUG
        lda #<read_banner
        ldy #>read_banner
        jsr serial_string        
.endif

        jsr disk_sector
        jsr disk_translate
        jsr sd_read
        bcc @ok
        lda #$A1
        .byt $2C
@ok:        
        lda #$80
@finish:
        jmp disk_finish

; ------------------------------------------------------------------------
; Block write from the disk
; ------------------------------------------------------------------------
        
disk_write:
        ; Disable floppy
        lda #$70
        ldx disk_unit
        bne @ok

.ifdef DEBUG
        lda #<write_banner
        ldy #>write_banner
        jsr serial_string        
.endif

        jsr disk_sector
        jsr disk_translate
        jsr sd_write
        bcc @ok
        lda #$A1
        .byt $2C
@ok:        
        lda #$80
@finish:
        jmp disk_finish

; ------------------------------------------------------------------------
; Copy sector number and address to zero page
; ------------------------------------------------------------------------

disk_sector:
        ldx disk_unit
        lda #0
        sta sd_sector+3
        lda sasi_command+1,x
        and #$1F
        sta sd_sector+2
        lda sasi_command+2,x
        sta sd_sector+1
        lda sasi_command+3,x
        sta sd_sector
        lda sasi_command+4,x
        sta disk_sectors
        lda sasi_command+6,x
        sta sd_bank
        lda sasi_command+7,x
        sta sd_ptr+1
        lda sasi_command+8,x
        sta sd_ptr

.ifdef DEBUG
        lda #<sector_banner1
        ldy #>sector_banner1
        jsr serial_string
        lda sd_sector+1
        jsr debug_hex
        lda sd_sector
        jsr debug_hex
        lda #<sector_banner2
        ldy #>sector_banner2
        jsr serial_string
        lda disk_sectors
        jsr debug_hex
        lda #<sector_banner3
        ldy #>sector_banner3
        jsr serial_string
        lda sd_bank
        jsr debug_hex
        lda #'|'
        jsr serial_output
        lda sd_ptr+1
        jsr debug_hex
        lda sd_ptr
        jsr debug_hex
        lda #$0D
        jsr serial_output
        lda #$0A
        jsr serial_output
.endif

        rts
        
; ------------------------------------------------------------------------
; Translate logical sector to physical sector on the SD card
; ------------------------------------------------------------------------

disk_translate:
        ldx disk_unit
        beq @hdd
        clc
        lda sd_sector
        adc #<FD_START
        sta sd_sector
        lda sd_sector+1
        adc #>FD_START
        sta sd_sector+1
        lda sd_sector+2
        adc #0
        sta sd_sector+2
        jmp @end
@hdd:
        clc
        lda sd_sector
        adc #<HD_START
        sta sd_sector
        lda sd_sector+1
        adc #>HD_START
        sta sd_sector+1
        lda sd_sector+2
        adc #0
        sta sd_sector+2
        
@end:
.ifdef DEBUG
        lda #<sector_banner4
        ldy #>sector_banner4
        jsr serial_string
        lda sd_sector+1
        jsr debug_hex
        lda sd_sector
        jsr debug_hex
        lda #$0D
        jsr serial_output
        lda #$0A
        jsr serial_output
.endif

        lda #$00
        sta sd_bank_flags
        rts

; ------------------------------------------------------------------------
; Clear IRQ flag
; ------------------------------------------------------------------------
                
disk_clear:
        lda #$00
        sta disk_irq
        jmp irq_issue

.ifdef DEBUG
disk_banner1:
        .byt "Disk command ", 0
disk_banner2:
        .byt " issued to unit ", 0
disk_banner3:
        .byt "Command status: ", 0
read_banner:
        .byt "Disk read:", 0
write_banner:
        .byt "Disk write:", 0
sector_banner1:
        .byt " sector ", 0
sector_banner2:
        .byt ", count ", 0
sector_banner3:
        .byt " to location ", 0
sector_banner4:
        .byt "Physical sector: ", 0
.endif

; ------------------------------------------------------------------------
; SD card access primitives
; ------------------------------------------------------------------------

sd_output:
        ldy #7
        sta (CHIPSET),y
        lda (CHIPSET),y
        rts

sd_read_loop:
        ldy #3
        lda #<sd_bank
        sta scratchpad
        lda #>sd_bank
        sta scratchpad+1
@loop:
        lda sd_bank,y
        sta (scratchpad),y
        dey
        bpl @loop
        jmp sd_read_bank15

sd_write_loop:
        ldy #3
        lda #<sd_bank
        sta scratchpad
        lda #>sd_bank
        sta scratchpad+1
@loop:
        lda sd_bank,y
        sta (scratchpad),y
        dey
        bpl @loop
        jmp sd_write_bank15
                
.include "../sd/init.asm"
.include "../sd/access.asm"
