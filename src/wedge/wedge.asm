
.include "defs.asm"

.code

.ifdef PRG
.include "../cbm2/stub.asm"
.res ($0400-*), $FF
.endif

.org $0400
        jmp wedge_start
        jmp wedge_warm
        jmp wedge_irq
        jmp wedge_nmi
        jmp wedge_cbmlink_serial
        jmp wedge_cbmlink_c2n232
        jmp WedgeHook

wedge_start:
        sei
        jsr init_irq
        jsr jump_bas_init_1
        jsr jump_bas_init_2
        lda IndReg
        pha
        jsr detect_basic
        ; From now on, IndReg = $0F
        bit basic_type
        bpl @banner_128
        lda #<banner_256
        ldy #>banner_256
        bne @banner_256
@banner_128:
        lda #<banner_128
        ldy #>banner_128
@banner_256:
        jsr print_string
        lda #<banner_wedge
        ldy #>banner_wedge
        jsr print_string
        jsr setup_warmstart
        jsr setup_func_keys
        jsr setup_wedge_irq
        jsr WedgeInstall
        pla
        sta IndReg
        cli
        jmp jump_bas_init_3

wedge_warm:
        jmp jump_8003
        
; --------------------------------------------------------
; BASIC type detection (basic_type bit 7 = 0 - BASIC 128)
; --------------------------------------------------------
    
detect_basic:
        lda #$0F
        sta IndReg
        lda #$01
        sta mem_ptr
        lda #$80
        sta mem_ptr+1
        ldy #$00
        lda (mem_ptr),y
        sta basic_type
        rts        

; --------------------------------------------------------
; IRQ handler routines in bank 0 - redirect to bank 15
; --------------------------------------------------------
                
init_irq:
        lda #<IRQ
        sta $FFFE
        lda #>IRQ
        sta $FFFF
        lda #<NMI
        sta $FFFA
        lda #>NMI
        sta $FFFB
        rts

IRQ:
        jsr jump_irq
        rti
NMI:
        jsr jump_nmi
        rti

; --------------------------------------------------------
; Set up warm start at $102E
; This location in the EPROM page 1 call the wedge
;  code at $0403 (jmp wedge_warm)
; --------------------------------------------------------

setup_warmstart:
        lda #$F8
        sta mem_ptr
        lda #$03
        sta mem_ptr+1
        ldy #0
        lda #$2E
        sta (mem_ptr),y
        iny
        lda #$10
        sta (mem_ptr),y
        iny
        lda #$A5
        sta (mem_ptr),y
        iny
        lda #$5A
        sta (mem_ptr),y
        rts

; --------------------------------------------------------
; Custom IRQ handler
; --------------------------------------------------------

setup_wedge_irq:
        lda #$03
        sta mem_ptr+1
        lda #$00
        sta mem_ptr
        tay
        lda #$10
        sta (mem_ptr),y
        iny
        lda #$11
        sta (mem_ptr),y
        rts
                
wedge_irq:
        jmp jump_irq_handle
        
wedge_nmi:
        jmp jump_rti


; --------------------------------------------------------
; Start CBMLINK 
; --------------------------------------------------------

wedge_cbmlink_serial:
        lda #<cbmlink_serial_bin
        sta src_ptr
        lda #>cbmlink_serial_bin
        sta src_ptr+1
        lda #$00
        sta mem_ptr
        lda #$04
        sta mem_ptr+1
        ldx #0
        ldy #0
        lda #$0F
        sta IndReg
@loop1:
        lda (src_ptr,x)
        sta (mem_ptr),y
        inc src_ptr
        bne @notzero1
        inc src_ptr+1
@notzero1:
        iny
        bne @loop1
        inc mem_ptr+1
@loop2:
        lda (src_ptr,x)
        sta (mem_ptr),y
        inc src_ptr
        bne @notzero2
        inc src_ptr+1
@notzero2:
        iny
        bne @loop2
        jmp jump_0400

wedge_cbmlink_c2n232:
        lda #<cbmlink_c2n232_bin
        sta src_ptr
        lda #>cbmlink_c2n232_bin
        sta src_ptr+1
        lda #$00
        sta mem_ptr
        lda #$04
        sta mem_ptr+1
        ldx #0
        ldy #0
        lda #$0F
        sta IndReg
@loop1:
        lda (src_ptr,x)
        sta (mem_ptr),y
        inc src_ptr
        bne @notzero1
        inc src_ptr+1
@notzero1:
        iny
        bne @loop1
        inc mem_ptr+1
@loop2:
        lda (src_ptr,x)
        sta (mem_ptr),y
        inc src_ptr
        bne @notzero2
        inc src_ptr+1
@notzero2:
        iny
        bne @loop2
        jmp jump_0400

; --------------------------------------------------------
; Redefine function keys
; --------------------------------------------------------

setup_func_keys:
        lda #$F0
        sta mem_ptr
        lda #$00
        sta mem_ptr+1
        tay
        lda #key_f11_end - key_f11
        sta (mem_ptr),y
        iny
        lda #<key_f11
        sta (mem_ptr),y
        iny
        lda #>key_f11
        sta (mem_ptr),y
        iny
        lda $00
        sta (mem_ptr),y
        lda #$F0
        ldy #11
        jsr jump_do_funkey
        ldy #0
        lda #key_f12_end - key_f12
        sta (mem_ptr),y
        iny
        lda #<key_f12
        sta (mem_ptr),y
        iny
        lda #>key_f12
        sta (mem_ptr),y
        iny
        lda $00
        sta (mem_ptr),y
        lda #$F0
        ldy #12
        jsr jump_do_funkey
        rts
                        
; --------------------------------------------------------
; Print null terminated string
; --------------------------------------------------------

print_string:
        sta screen_ptr
        sty screen_ptr+1
@loop:
        ldx #0
        lda (screen_ptr,x)
        beq @end
        jsr jump_bsout_crt
        inc screen_ptr
        bne @loop
        inc screen_ptr+1
        bne @loop
@end:
        rts

; --------------------------------------------------------
; Startup banners and other texts
; --------------------------------------------------------

banner_256:
        .byt $93, "*** commodore basic 256, v4.0 ***", $0D, 0
banner_128:
        .byt $93, "*** commodore basic 128, v4.0 ***", $0D, 0
banner_wedge:
        .byt "simple bank 0 wedge v0.1 installed", $0D
        .byt "f11: cbmlink serial, f12: cbmlink c2n232", $0D, 0

key_f11:
        .byt "sys4416", $0D
key_f11_end:

key_f12:
        .byt "sys4424", $0D
key_f12_end:
        
; --------------------------------------------------------
; Return from bank 15 call - set Z flag accordingly
; --------------------------------------------------------

.res ($1100-*),$FF

CallReturn:
        beq @zero
        ; Zero flag not set
        ; CPU register at $00 contains $00 - incrementing will yield $FF with Z=0
        dec $00
        ; Continued from bank 15 - no need to do anything
        rts
@zero:
        ; Zero flag set
        dec $00
        ; Continued from bank 15 - need to set zero flag
        ; Save A value
        sta acc_save
        ; Set A to $00 to ensure Z=1
        lda #$00
        ; Push flags with Z=1
        php
        ; Restore old A value
        lda acc_save
        ; Restore flags with Z=1
        plp
        rts

.res ($1120-*),$FF

.macro  CALL address
        dec $00
        jsr address
        jmp CallReturn
.endmacro

.macro  JUMP address
        dec $00
        jmp address
        nop
        nop
        nop
.endmacro

jump_reset:
        CALL $0400+3*0          ; Initialize wedge
jump_warm_start:
        CALL $0400+3*1          ; READY prompt [not implemented yet]
jump_bas_init_1:
        JUMP $0400+3*2          ; Custom IRQ handler
jump_bas_init_2:
        JUMP $0400+3*3          ; Custom NMI handler
jump_bas_init_3:
        CALL $0400+3*4          ; Start CBMLINK serial
jump_irq:
        CALL $0400+3*5
jump_nmi:
        CALL $0400+3*6
jump_irq_handle:
        CALL $0400+3*7
jump_irq_end:
        CALL $0400+3*8
jump_rti:
        CALL $0400+3*9
jump_8003:
        CALL $0400+3*10
jump_0400:
        CALL $0400+3*11
jump_jsrseg:
        CALL $0400+3*12
jump_setwst:
        CALL $0400+3*13
jump_runcopro:
        CALL $0400+3*14
jump_funkey:
        CALL $0400+3*15
jump_copro:
        CALL $0400+3*16
jump_ioinit:
        CALL $0400+3*17
jump_scrinit:
        CALL $0400+3*18
jump_getmem:
        CALL $0400+3*19
jump_vector:
        CALL $0400+3*20
jump_restor:
        CALL $0400+3*21
jump_setfnr:
        CALL $0400+3*22
jump_chgfpar:
        CALL $0400+3*23
jump_setst:
        CALL $0400+3*24
jump_second:
        CALL $0400+3*25
jump_tksa:
        CALL $0400+3*26
jump_memtop:
        CALL $0400+3*27
jump_membot:
        CALL $0400+3*28
jump_scnkey:
        CALL $0400+3*29
jump_settmo:
        CALL $0400+3*30
jump_acptr:
        CALL $0400+3*31
jump_ciout:
        CALL $0400+3*32
jump_untalk:
        CALL $0400+3*33
jump_unlsn:
        CALL $0400+3*34
jump_listen:
        CALL $0400+3*35
jump_talk:
        CALL $0400+3*36
jump_readst:
        CALL $0400+3*37
jump_setlfs:
        CALL $0400+3*38
jump_setnam:
        CALL $0400+3*39
jump_open:
        CALL $0400+3*40
jump_close:
        CALL $0400+3*41
jump_chkin:
        CALL $0400+3*42
jump_chkout:
        CALL $0400+3*43
jump_clrch:
        CALL $0400+3*44
jump_basin:
        CALL $0400+3*45
jump_bsout:
        CALL $0400+3*46
jump_load:
        CALL $0400+3*47
jump_save:
        CALL $0400+3*48
jump_settim:
        CALL $0400+3*49
jump_rdtim:
        CALL $0400+3*50
jump_chkstop:
        CALL $0400+3*51
jump_getin:
        CALL $0400+3*52
jump_clall:
        CALL $0400+3*53
jump_udtim:
        CALL $0400+3*54
jump_screen:
        CALL $0400+3*55
jump_plot:
        CALL $0400+3*56
jump_iobase:
        CALL $0400+3*57
jump_monitor:
        CALL $0400+3*58
jump_do_scrinit:
        CALL $0400+3*59
jump_getkey:
        CALL $0400+3*60
jump_basin_crt:
        CALL $0400+3*61
jump_bsout_crt:
        CALL $0400+3*62
jump_do_screen:
        CALL $0400+3*63
jump_do_scnkey:
        CALL $0400+3*64
jump_setcurs:
        CALL $0400+3*65
jump_do_plot:
        CALL $0400+3*66
jump_do_iobase:
        CALL $0400+3*67
jump_escseq:
        CALL $0400+3*68
jump_do_funkey:
        CALL $0400+3*69
jump_do_second:
        CALL $0400+3*70
jump_do_tksa:
        CALL $0400+3*71
jump_do_acptr:
        CALL $0400+3*72
jump_do_ciout:
        CALL $0400+3*73
jump_do_untlk:
        CALL $0400+3*74
jump_do_unlsn:
        CALL $0400+3*75
jump_do_listen:
        CALL $0400+3*76
jump_do_talk:
        CALL $0400+3*77
jump_do_open:
        CALL $0400+3*78
jump_do_close:
        CALL $0400+3*79
jump_do_chkin:
        CALL $0400+3*80
jump_do_ckout:
        CALL $0400+3*81
jump_do_clrch:
        CALL $0400+3*82
jump_do_basin:
        CALL $0400+3*83
jump_do_bsout:
        CALL $0400+3*84
jump_do_load:
        CALL $0400+3*85
jump_do_save:
        CALL $0400+3*86
jump_do_stop:
        CALL $0400+3*87
jump_do_getin:
        CALL $0400+3*88
jump_do_clall:
        CALL $0400+3*89
jump_85E2:
        CALL $0400+3*90
jump_85EA:
        CALL $0400+3*91
jump_8542:
        CALL $0400+3*92
jump_854D:
        CALL $0400+3*93
jump_8555:
        CALL $0400+3*94
jump_85B8:
        CALL $0400+3*95
jump_85C0:
        CALL $0400+3*96
jump_86DB:
        CALL $0400+3*97
jump_86E3:
        CALL $0400+3*98
jump_85EB:
        CALL $0400+3*99
jump_85F3:
        CALL $0400+3*100
jump_B98B:
        CALL $0400+3*101
jump_BA29:
        CALL $0400+3*102
jump_B988:
        CALL $0400+3*103
jump_BA26:
        CALL $0400+3*104
jump_tmp:
        CALL $0400+3*105

                
cbmlink_serial_bin:
        .incbin "cbmlink/serial.bin"
cbmlink_serial_end:
                        
cbmlink_c2n232_bin:
        .incbin "cbmlink/c2n232.bin"
cbmlink_c2n232_end:

.include "disk.asm"

.ifdef PRG
.res 128, $AA
.endif
        
