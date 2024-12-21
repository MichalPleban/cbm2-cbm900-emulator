
.include "defs.asm"

.code

.ifdef PRG
.include "cbm2/stub.asm"
.res ($0400-*), $FF
.endif

.org $0400

start:
        sei
        cld
        ldx #$FF
        txs
        lda #$0F
        sta IND_REG
        
        jsr machine_init
        
        ; Pull /RESET low
        ldy #6
        lda (CHIPSET),y
        ora #$01
        sta (CHIPSET),y
        lda #0
        sta z8000_started
        
        jsr screen_init
        lda #<banner
        ldy #>banner
        jsr screen_string
        jsr kbd_init
        jsr serial_init
        jsr emul_init
        jsr irq_init
        jsr load_files
        jsr irq_restart
        cli
        
        ; Pull /RESET high
        ldy #6
        lda (CHIPSET),y
        and #$FE
        sta (CHIPSET),y
        lda #$80
        sta z8000_started
        
        ; Main loop
@loop:
        jsr disk_handle
        lda kbd_stop
        bpl @loop
        jsr menu_show
        lda #$00
        sta kbd_stop
        jmp @loop


        
banner:
        .byt "Commodore C900 emulation layer version 0.5.1, (C) Michal Pleban", $0D, $0A, $0D, $0A, 0

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
        ora #$12
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
        and #$CD
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
        ora #$12
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
        and #$CD
        sta $D906
        lda #$0F
        sta IND_REG
        lda #$01
        sta EXEC_REG
        rts

sd_read_bank15:
        lda #$0F
        sta EXEC_REG
        ; Enable access to RAM & XOR address lines if necessary
        bit sd_bank
        bmi @computer_ram
        lda $D906
        ora #$02
;        ora sd_bank_flags
        sta $D906
@computer_ram:
        lda sd_bank
        sta IND_REG
        sta $07FF
        lda sd_ptr
        sta $07FD
        lda sd_ptr+1
        sta $07FE
        ; Read bytes in a loop
        lda #2
        sta sd_loop+1
        lda #0
        sta sd_loop
@loop:
        lda #$FF
        sta $D907
        lda $D907
        ldy sd_loop
        sta (sd_ptr),y
        iny
        sty sd_loop
        bne @loop
        inc sd_ptr+1
        dec sd_loop+1
        bne @loop
        ; Disable access to RAM
        lda $D906
        and #$CD
        sta $D906
        lda #$0F
        sta IND_REG
        lda #$01
        sta EXEC_REG
        rts

sd_write_bank15:
        lda #$0F
        sta EXEC_REG
        ; Enable access to RAM & XOR address lines if necessary
        bit sd_bank
        bmi @computer_ram
        lda $D906
        ora #$02
;        ora sd_bank_flags
        sta $D906
@computer_ram:
        lda sd_bank
        sta IND_REG
        ; Read bytes in a loop
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
        ; Disable access to RAM
        lda $D906
        and #$CD
        sta $D906
        lda #$0F
        sta IND_REG
        lda #$01
        sta EXEC_REG
        rts
        
        .res ($0600-*), $FF
        
.include "cbm2.asm"
.include "emul.asm"

load_files:
        lda #$00
        sta can_enter_menu

        lda #<banner_sd
        ldy #>banner_sd
        jsr screen_string
        jsr fat32_init
        bcc @init_ok
        jmp @disk_error
@init_ok:
        lda #<msg_ok
        ldy #>msg_ok
        jsr screen_string

        lda #<banner_config
        ldy #>banner_config
        jsr screen_string
        lda #<config_filename
        ldy #>config_filename
        jsr fat32_find_file
        bcs @disk_error
        lda #<config_mapping
        ldy #>config_mapping
        jsr fat32_scan_file
        bcs @disk_error
        jsr load_config
        bcs @disk_error
        lda #<msg_ok
        ldy #>msg_ok
        jsr screen_string
        
        lda #$80
        sta can_enter_menu

        bit floppy_present
        bpl @no_floppy
        lda #<banner_fd
        ldy #>banner_fd
        jsr screen_string
        lda #<fd_filename
        ldy #>fd_filename
        jsr filename_print
        lda #<msg_ellipsis
        ldy #>msg_ellipsis
        jsr screen_string
        lda #<fd_filename
        ldy #>fd_filename
        jsr fat32_find_file
        bcs @disk_error
        lda #<fd_mapping
        ldy #>fd_mapping
        jsr fat32_scan_file
        bcs @disk_error
        lda #<msg_ok
        ldy #>msg_ok
        jsr screen_string
@no_floppy:

        lda #<banner_hd
        ldy #>banner_hd
        jsr screen_string
        lda #<hd_filename
        ldy #>hd_filename
        jsr filename_print
        lda #<msg_ellipsis
        ldy #>msg_ellipsis
        jsr screen_string
        lda #<hd_filename
        ldy #>hd_filename
        jsr fat32_find_file
        bcs @disk_error
        lda #<hd_mapping
        ldy #>hd_mapping
        jsr fat32_scan_file
        bcs @disk_error
        lda #<msg_ok
        ldy #>msg_ok
        jsr screen_string        
        rts
        
@disk_error:
        jsr disk_error
        jsr screen_string
        lda #$0D
        jsr screen_output
        lda #$0A
        jsr screen_output
        bit can_enter_menu
        bmi @can_menu
        lda #<banner_retry
        ldy #>banner_retry
        bne @show_banner
@can_menu:
        lda #<banner_retry2
        ldy #>banner_retry2
@show_banner:
        jsr screen_string
        jsr irq_restart
        cli

@disk_loop:
        bit can_enter_menu
        bpl @cant_menu
        bit kbd_stop
        bmi @stop
@cant_menu:
        jsr kbd_fetch
        cmp #$0D
        bne @disk_loop
        sei
        lda #$0D
        jsr screen_output
        lda #$0A
        jsr screen_output
        lda #0
        sta kbd_stop
        jmp load_files

@stop:
        jsr menu_show
        lda #0
        sta kbd_stop
        sei
        lda #$0D
        jsr screen_output
        lda #$0A
        jsr screen_output
        jmp load_files
        

.include "menu/menu.asm"
.include "menu/config.asm"
        
banner_sd:      .byt "Initializing SD card... ", 0
banner_config:  .byt "Loading configuration file CONFIG.CFG...", 0
banner_fd:      .byt "Loading floppy disk image ", 0
banner_hd:      .byt "Loading hard disk image ", 0
msg_ellipsis:   .byt "... ", 0
msg_ok:         .byt "OK", $0D, $0A, 0
banner_retry:   .byt "Press Enter to retry.", $0D, $0A, 0
banner_retry2:  .byt "Press Enter to retry, Run/Stop to configure.", $0D, $0A, 0

config_filename: .byt "CONFIG  CFG",0

.ifdef PRG
.res 16, $AA
.endif
