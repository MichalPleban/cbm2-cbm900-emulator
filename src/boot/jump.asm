
.ifdef PRG
.include "../cbm2/defs.asm"
.include "../chipset.asm"
.data
.byt $00, $10
.endif

.code
.org $1000

; --------------------------------------------------------
; Cold and warm start
; --------------------------------------------------------

        jmp cold_reset
        jmp jump_wedge_1
.byt $43, $C2, $CD, $31

; --------------------------------------------------------
; Routines to run code in the first bank
; --------------------------------------------------------

        ; Cold reset in EPROM page 0
cold_reset:
        sei
        lda CHIPSET_BASE + REG_IO_PINS
        and #($FF - IO_BANK)
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 0 (cold reset)
        nop
        nop
        nop

        ; Warm reset in EPROM page 0
warm_reset:
        sei
        lda CHIPSET_BASE + REG_IO_PINS
        and #($FF - IO_BANK)
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 0 (warm reset)
        nop
        nop
        nop

        ; Wedge start in EPROM page 1 - points to wedge function #0
        sei
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        jmp jump_wedge_0

        ; Warm reset in EPROM page 1 - points to wedge function #1
        sei
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        jmp jump_wedge_1

; --------------------------------------------------------
; Initialize BASIC (first part)
; --------------------------------------------------------

InitBASICStart:
        bit $8001
        bpl Init128_

Init256_:
        jsr $bb29
        ldx #2
Init256l1_:
        lda $b460,x
        sta $02,x
        dex
        bpl Init256l1_
        sta $61
        ldx #4
Init256l2_:
        lda $bb34,x
        sta $0259,x
        dex
        bne Init256l2_
        jsr InitCommon
        jsr $b9f5
        jsr $b9ee
Init256l2b_:
        ldy #0
        tya
        sta ($2d),y
        inc $2d
        bne Init256l3_
        inc $2e
Init256l3_:
        rts

Init128_:
        jsr $bbbc
        ldx #2
Init128l1_:
        lda $b4fe,x
        sta $02,x
        dex
        bpl Init128l1_
        sta $61
        ldx #4
Init128l2_:
        lda $bbc7,x
        sta $0259,x
        dex
        bne Init128l2_
        jsr InitCommon
        jsr $ba93
        jsr $ba8c
        jmp Init256l2b_

InitCommon:
        stx $78
        stx $1a
        stx $16
        stx $0258
        stx $1d
        dex
        stx $1e
        stx $1f
        inx
        stx $31
        ldx #$80
        stx $32
        sec
        jsr $ff9c
        stx $39
        sty $3a
        stx $35
        sty $36
        stx $2d
        sty $2e
        rts
        
; --------------------------------------------------------
; Initialize BASIC (second part)
; --------------------------------------------------------

InitBASICMiddle:
        ; Need to save the stack pointer because the BASIC routine changes it
        tsx
        stx $FF
        bit $8001
        bpl InitBASICMiddle128
        jsr $8a12 
InitBASICMiddleFinish:
        ldx #$39
        ldy #$bb
        jsr $ff6f
        ldx $FF
        txs
        rts
InitBASICMiddle128:        
        jsr $8a2b 
        jmp InitBASICMiddleFinish

; --------------------------------------------------------
; Initialize BASIC (third part)
; --------------------------------------------------------

InitBASICEnd:
        bit $8001
        bpl InitBASICEnd128
        
        jmp $85b8
InitBASICEnd128:
        jmp $85c0
        
; --------------------------------------------------------
; Call the original IRQ & NMI routines
; --------------------------------------------------------

CallIRQ:
        php
        nop
        nop
        nop
        nop
        nop
        ; This must be a JSR, so that the IRQ routine can properly get the flags from the stack
        ;  and determine whether this is an IRQ or a BRK.
        jsr do_CallIRQ
        rts       
CallNMI:
        php
        jmp ($FFFB)

do_CallIRQ:
        jmp ($FFFE)

do_rti:
        rti

        

; --------------------------------------------------------
; Return from bank 0 call - set Z flag accordingly
; --------------------------------------------------------

.res ($1100-*),$FF

CallReturn:
        beq @zero
        ; Zero flag not set
        ; $00 contains $0F - incrementing will yield $10 with Z=0
        inc $00
        ; Continued from bank 0 - no need to do anything
        rts
@zero:
        ; Zero flag set
        inc $00
        ; Continued from bank 0 - need to set zero flag
        ; Decrement $01 value to yield $00 with Z=1
        ; This works ONLY if the code is in EPROM, so that the value stays at $01!
        dec @one
        rts
@one:
        .byt $01
        
; --------------------------------------------------------
; IRQ handler stub
; --------------------------------------------------------

.res ($1110-*),$FF

        nop
        lda $01
        pha
        cld
        lda $DE07
        beq @irq_end
        jmp jump_wedge_2
@irq_end:
        jmp $FCA2

; --------------------------------------------------------
; Calls from bank 0 
; --------------------------------------------------------

.res ($1120-*),$FF

.macro  CALL address
        inc $00
        jsr address
        jmp CallReturn
.endmacro

.macro  JUMP address
        inc $00
        jmp address
        nop
        nop
        nop
.endmacro

jump_wedge_0:
        CALL cold_reset
jump_wedge_1:
        CALL warm_reset
jump_wedge_2:
        CALL InitBASICStart
jump_wedge_3:
        CALL InitBASICMiddle
jump_wedge_4:
        CALL InitBASICEnd
jump_wedge_5:
        CALL CallIRQ
jump_wedge_6:
        CALL CallNMI        
jump_wedge_7:
        JUMP $FBF5              ; IRQ handler start
jump_wedge_8:
        JUMP $FC9F              ; IRQ handler end
jump_wedge_9:
        JUMP do_rti             ; Simple RTI instruction
jump_wedge_10:
        JUMP $8003              ; Warm reset
jump_wedge_11:
        CALL $0400              ; Start cbmlink
jump_wedge_12:
        CALL $FF6C              ; JSRSEG
jump_wedge_13:
        CALL $FF6F              ; SETWST
jump_wedge_14:
        CALL $FF72              ; RUNCOPRO
jump_wedge_15:
        CALL $FF75              ; FUNKEY
jump_wedge_16:
        CALL $FF78              ; COPRO
jump_wedge_17:
        CALL $FF7B              ; IOINIT
jump_wedge_18:
        CALL $FF7E              ; SCRINIT
jump_wedge_19:
        CALL $FF81              ; GETMEM
jump_wedge_20:
        CALL $FF84              ; VECTOR
jump_wedge_21:
        CALL $FF87              ; RESTOR
jump_wedge_22:
        CALL $FF8A              ; SETFNR
jump_wedge_23:
        CALL $FF8D              ; CHGFPAR
jump_wedge_24:
        CALL $FF90              ; SETST
jump_wedge_25:
        CALL $FF93              ; SECOND
jump_wedge_26:
        CALL $FF96              ; TKSA
jump_wedge_27:
        CALL $FF99              ; MEMTOP
jump_wedge_28:
        CALL $FF9C              ; MEMBOT
jump_wedge_29:
        CALL $FF9F              ; SCNKEY
jump_wedge_30:
        CALL $FFA2              ; SETTMO
jump_wedge_31:
        CALL $FFA5              ; ACPTR
jump_wedge_32:
        CALL $FFA8              ; CIOUT
jump_wedge_33:
        CALL $FFAB              ; UNTALK
jump_wedge_34:
        CALL $FFAE              ; UNLSN
jump_wedge_35:
        CALL $FFB1              ; LISTEN
jump_wedge_36:
        CALL $FFB4              ; TALK
jump_wedge_37:
        CALL $FFB7              ; READST
jump_wedge_38:
        CALL $FFBA              ; SETLFS
jump_wedge_39:
        CALL $FFBD              ; SETNAM
jump_wedge_40:
        CALL $FFC0              ; OPEN
jump_wedge_41:
        CALL $FFC3              ; CLOSE
jump_wedge_42:
        CALL $FFC6              ; CHKIN
jump_wedge_43:
        CALL $FFC9              ; CHKOUT
jump_wedge_44:
        CALL $FFCC              ; CLRCH
jump_wedge_45:
        CALL $FFCF              ; BASIN
jump_wedge_46:
        CALL $FFD2              ; BSOUT
jump_wedge_47:
        CALL $FFD5              ; LOAD
jump_wedge_48:
        CALL $FFD8              ; SAVE
jump_wedge_49:
        CALL $FFDB              ; SETTIM
jump_wedge_50:
        CALL $FFDE              ; RDTIM
jump_wedge_51:
        CALL $FFE1              ; CHKSTOP
jump_wedge_52:
        CALL $FFE4              ; GETIN
jump_wedge_53:
        CALL $FFE7              ; CLALL
jump_wedge_54:
        CALL $FFEA              ; UDTIM
jump_wedge_55:
        CALL $FFED              ; SCREEN
jump_wedge_56:
        CALL $FFF0              ; PLOT
jump_wedge_57:
        CALL $FFF3              ; IOBASE
jump_wedge_58:
        CALL $E000              ; monitor
jump_wedge_59:
        CALL $E004              ; do_scrinit
jump_wedge_60:
        CALL $E007              ; getkey
jump_wedge_61:
        CALL $E00A              ; basin_crt
jump_wedge_62:
        CALL $E00D              ; bsout_crt
jump_wedge_63:
        CALL $E010              ; do_screen
jump_wedge_64:
        CALL $E013              ; do_scnkey
jump_wedge_65:
        CALL $E016              ; setcurs
jump_wedge_66:
        CALL $E019              ; do_plot
jump_wedge_67:
        CALL $E01C              ; do_iobase
jump_wedge_68:
        CALL $E01F              ; escseq
jump_wedge_69:
        CALL $E022              ; do_funkey
jump_wedge_70:
        CALL $F274              ; do_second
jump_wedge_71:
        CALL $F280              ; do_tksa
jump_wedge_72:
        CALL $F30A              ; do_acptr
jump_wedge_73:
        CALL $F297              ; do_ciout
jump_wedge_74:
        CALL $F2AB              ; do_untlk
jump_wedge_75:
        CALL $F2AF              ; do_unlsn
jump_wedge_76:
        CALL $F234              ; do_listen
jump_wedge_77:
        CALL $F230              ; do_talk
jump_wedge_78:
        CALL $F6BF              ; do_open
jump_wedge_79:
        CALL $F5ED              ; do_close
jump_wedge_80:
        CALL $F549              ; do_chkin
jump_wedge_81:
        CALL $F5A3              ; do_ckout
jump_wedge_82:
        CALL $F6A6              ; do_clrch
jump_wedge_83:
        CALL $F49C              ; do_basin
jump_wedge_84:
        CALL $F4EE              ; do_bsout
jump_wedge_85:
        CALL $F746              ; do_load
jump_wedge_86:
        CALL $F84C              ; do_save
jump_wedge_87:
        CALL $F96B              ; do_stop
jump_wedge_88:
        CALL $F43D              ; do_getin
jump_wedge_89:
        CALL $F67F              ; do_clall
        
        
                
.res ($2000-*),$FF


