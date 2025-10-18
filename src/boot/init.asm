.include "kernal.asm"
.include "defs.asm"
.include "../cbm2/defs.asm"
.include "../chipset.asm"

.ifdef PRG
.data
.byt $00, $10
.endif

.code
.org $1000

; --------------------------------------------------------
; Cold and warm start
; --------------------------------------------------------

        jmp do_init
        jmp do_warm
        .byt $43, $C2, $CD, $31

; --------------------------------------------------------
; Routines to run code in the second bank
; --------------------------------------------------------

        ; Cold reset in bank 0
        sei
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        jmp do_init

vec_warm:
        ; Warm reset in bank 0
        sei
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        jmp do_warm

        ; Wedge cold start in bank 1
start_wedge:
        sei
        lda CHIPSET_BASE + REG_IO_PINS
        ora #IO_BANK
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 1 (wedge start)
        nop
        nop
        nop

        ; Wedge warm start in bank 1
        sei
        lda CHIPSET_BASE + REG_IO_PINS
        ora #IO_BANK
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 1 (wedge start)
        nop
        nop
        nop

basic_prompt:
        ; BASIC prompt in bank 1
        sei
        lda CHIPSET_BASE + REG_IO_PINS
        ora #IO_BANK
        sta CHIPSET_BASE + REG_IO_PINS
        ; Next instruction is executed in bank 1 (BASIC prompt)
        nop
        nop
        nop

ram_sizes:
        .byte "  0", 0
        .byte " 64", 0
        .byte "128", 0
        .byte "192", 0
        .byte "256", 0
        .byte "320", 0
        .byte "384", 0
        .byte "448", 0
        .byte "512", 0
        .byte "576", 0
        .byte "640", 0
        .byte "704", 0
        .byte "768", 0
        .byte "832", 0
        .byte "894", 0

; --------------------------------------------------------
; Initialization routine after RESET
; --------------------------------------------------------

do_warm:
        ; Check if C= key pressed
        ldx #$FF
        stx $DF03
        stx $DF04
        stx $DF01
        inx 
        stx $DF05
        lda #$F7
        sta $DF00
@check:
        lda $DF02
        cmp $DF02
        bne @check
        and #$10
        beq do_init
        ; Reset IRQ vector if it points to ROM code in bank 1
        lda $0301
        and #$F0
        cmp #$10
        bne @dont_reset_irq
        lda #$fb
        sta $0301
        lda #$e9
        sta $0300
@dont_reset_irq:
        jmp WarmBASIC
                
do_init:
        sei
        cld
        jsr do_ioinit
        
        ; Clear the chipset registers
        lda #$00
        sta CHIPSET_BASE + REG_IO_PINS
        lda #$03 ; Reset Z8000 + enable external RAM
        sta CHIPSET_BASE + REG_CONTROL
        
        ; Clear the TPI interrupt flag which is not cleared afer reset
        sta $DE07
        lda #$F0
        sta PgmKeyBuf+1
        
        ; Initialize IO and screen
        jsr jmp_scrinit
        jsr disable_ram
        jsr MyRamTas
        lda SysMemTop+2
        pha
        jsr enable_ram
        jsr MyRamTas
        jsr Delay
        jsr do_restor
        jsr jmp_scrinit
        pla
        sta mem_size
        
        ; Disable warm boot
        lda #$00
        sta WstFlag
        lda #$0F
        sta IndReg
        
        ; Re-initialize function keys
        jsr set_keys
        
        ; Check cartridge presence
        ldx #$00
        stx cart_addr
        dex
        stx cart_addr+1
        jsr Check2000
        bne @not_2000
        lda #$20
        sta cart_addr+1
        bne menu_start
@not_2000:
        jsr Check4000
        bne @not_4000
        lda #$40
        sta cart_addr+1
        bne menu_start
@not_4000:
        jsr Check6000
        bne menu_start
        lda #$60
        sta cart_addr+1
        
menu_start:
        ; Show startup banner
        lda #<msg_init
        ldy #>msg_init
        jsr output_banner

        ; Show RAM size        
        lda mem_size
        asl a
        asl a
        clc
        adc #<ram_sizes
        ldy #>ram_sizes
        jsr output_banner
        
        ; Show menu keys
        lda #<msg_menu
        ldy #>msg_menu
        jsr output_banner

        ; Output cartridge location
        bit cart_addr+1
        bmi @no_cart
        lda #<msg_cart
        ldy #>msg_cart
        jsr output_banner
        lda cart_addr+1
        lsr a
        lsr a
        lsr a
        lsr a
        ora #$30
        jsr BSOUT
        lda #$30
        jsr BSOUT
        lda #$30
        jsr BSOUT
        lda #$30
        jsr BSOUT
        lda #$0D
        jsr BSOUT
        
@no_cart:
        lda #$0D
        jsr BSOUT
        jsr disable_cursor
        cli
menu_loop:
        ; Check for F1-F4 key press
        ldx #$01
        jsr CHKIN
        jsr GETIN
        beq menu_loop
        cmp #$85
        beq init_emulation
        cmp #$89
        bne not_F2
        lda #$A5
        sta WstFlag
        jmp InitBASIC
not_F2:        
        cmp #$86
        beq init_wedge
        bit cart_addr+1
        bmi menu_loop
        cmp #$8A
        bne menu_loop
        jmp (cart_addr)

init_emulation:
        lda #<msg_load
        ldy #>msg_load
        jsr output_banner
        sei
        
        ; Disable expansion RAM
        jsr disable_ram

@load:
        ; Load the file from SD card
        lda #<emul_filename
        sta filename
        lda #>emul_filename
        sta filename+1
        ldx #$01
        stx load_addr
        stx load_addr+2
        dex
        stx load_addr+1
        jsr boot_file
        bcs display_error
        
        ; Start the emulation code at $010400
        lda #$A9
        sta $03FC
        lda #$01    ; LDA #$01
        sta $03FD
        lda #$85
        sta $03FE
        lda #$00    ; STA $00
        sta $03FF
        jmp $03FC
        
init_wedge:
        lda #<msg_load2
        ldy #>msg_load2
        jsr output_banner
        sei
        
@load:
        ; Load the file from SD card
        lda #<wedge_filename
        sta filename
        lda #>wedge_filename
        sta filename+1
        ldx #$00
        stx load_addr+2
        stx load_addr+1
        inx
        stx load_addr
        jsr boot_file
        bcs display_error
        jmp start_wedge

display_error:        
        ; Display error message
        jsr disk_error
        jsr output_banner
        lda #<msg_error
        ldy #>msg_error
        jsr output_banner
        jsr enable_ram
        
        ; Wait for Return key
        cli
@loop:
        ldx #$01
        jsr CHKIN
        jsr GETIN
        beq @loop
        cmp #$0D
        bne @loop
        jmp menu_start
        

                
; --------------------------------------------------------
; Output string to screen
; --------------------------------------------------------
        
output_banner:
        sta screen_ptr
        sty screen_ptr+1
        ldx #$03
        jsr CHKOUT
@loop:
        ldy #0
        lda (screen_ptr),y
        beq disable_cursor
        jsr BSOUT
        inc screen_ptr
        bne @loop
        inc screen_ptr+1
        bne @loop

; Disable cursor by moving it off screen
disable_cursor:
        lda #14
        sta $D800
        lda #$FF
        sta $D801
        lda #15
        sta $D800
        lda #$FF
        sta $D801
        rts

disable_ram:
        lda CHIPSET_BASE + REG_CONTROL
        and #($FF - CTRL_RAMEN)
        sta CHIPSET_BASE + REG_CONTROL
        rts

enable_ram:
        lda CHIPSET_BASE + REG_CONTROL
        ora #CTRL_RAMEN
        sta CHIPSET_BASE + REG_CONTROL
        rts

        
; --------------------------------------------------------
; Redefine function keys
; --------------------------------------------------------
        
set_keys:        
        lda #1
        sta $F0
        lda #$0F
        sta $F3
        lda #<func_keys
        sta $F1
        lda #>func_keys
        sta $F2
        lda #$F0
        ldy #1
        jsr jmp_funkey
        inc $F1
        lda #$F0
        ldy #2
        jsr jmp_funkey
        inc $F1
        lda #$F0
        ldy #3
        jsr jmp_funkey
        inc $F1
        lda #$F0
        ldy #4
        jsr jmp_funkey
        rts

        
; --------------------------------------------------------
; Fast RAM initialization & test
; --------------------------------------------------------

MyRamTas:
        lda     #$00
        tax
MyRamTas1:
        .byte   $9D,$02,$00     ; STA $0002,X - no zeropage mode to avoid rewriting $00/$01
        sta     $0200,x         ; Clear page 0, 2 and 3
        sta     $02F8,x         ;
        inx
        bne     MyRamTas1
        lda     #$01
        sta     IndReg
        sta     UsrMemBot+2
        sta     SysMemBot+2
        lda     #$02
        sta     UsrMemBot
        sta     SysMemBot
        dec     IndReg
LFAAB:
        inc     IndReg          ; Teste auf Ram in allen Bänken
        lda     IndReg
        cmp     #$0F
        beq     LFAD8
        ldy     #$FE
        lda     (SaveAdrLow),y
        pha
        iny
        lda     (SaveAdrLow),y
        tax
        dey
        lda     #$55
        sta     (SaveAdrLow),y
        iny
        asl     a
        sta     (SaveAdrLow),y
        dey
        lda     (SaveAdrLow),y
        cmp     #$55
        bne     LFAD7           
        iny
        lda     (SaveAdrLow),y
        cmp     #$AA
        bne     LFAD7
        txa
        sta     (SaveAdrLow),y
        pla
        dey
        sta     (SaveAdrLow),y
        jmp     LFAAB           ; alle Bänke testen
LFAD7:
        pla
LFAD8:
        ldx     IndReg          ; Einsprung nach Speichertest
        dex                     ; letztes belegtes Segment
        txa
        ldx     #$FF
        ldy     #$FD
        sta     SysMemTop+2     ; Zeiger auf Ende des freien Speichers setzen
        sty     SysMemTop+1
        stx     SysMemTop
        ldy     #$FA
        clc
        jsr     do_memtop
        dec     rs232BufPtrSeg
        dec     TapeBufPtrSeg
        lda     #<do_tape       ; Tape-Pointer setzen
        sta     TapeVec
        lda     #>do_tape
        sta     TapeVec+1
        rts

; --------------------------------------------------------
; Wait for the VGA card to initialize
; --------------------------------------------------------

Delay:
        lda #4
        ldy #0
        ldx #0
Delay1:
        nop
        dex
        bne Delay1
        dey
        bne Delay1
        sec
        sbc #1
        bne Delay1
        rts        

; --------------------------------------------------------
; Check cartridge presence
; --------------------------------------------------------

Check6000:
        lda $6009
        cmp #$36
        bne CheckCart1
        ldx $6008
        ldy $6007
        lda $6006
        and #$7F
        jmp CheckCart
Check4000:
        lda $4009
        cmp #$34
        bne CheckCart1
        ldx $4008
        ldy $4007
        lda $4006
        and #$7F
Check2000:
        lda $2009
        cmp #$32
        bne CheckCart1
        ldx $2008
        ldy $2007
        lda $2006
        and #$7F
CheckCart:
        cpx #$CD
        bne CheckCart1
        cpy #$C2
        bne CheckCart1
        cmp #$43
CheckCart1:
        rts

        
; --------------------------------------------------------
; Boot messages
; --------------------------------------------------------

msg_init:
        .byt $93, "Z8000 card boot ROM v1.0 (C) 2025 Michal Pleban", $0D, 0
        
msg_menu:
        .byt " kB system RAM, 1024 kB expansion RAM", $0D, $0D
        .byt " [F1] - boot Commodore 900 emulation", $0D
        .byt " [F2] - boot into BASIC", $0D
        .byt " [F3] - boot wedge program", $0D
        .byt 0

msg_cart:
        .byt " [F4] - boot cartridge at $", 0
        
msg_load:
        .byt "Loading file EMULCBM2.PRG... ", 0
msg_load2:
        .byt "Loading file WEDGE.PRG... ", 0
        
msg_error:
        .byt $0D, "Press Return to continue", 0
        
func_keys:
        .byt $85, $89, $86, $8A, $87, $8B, $88, $8C
        
.include "boot.asm"

emul_filename:
        .byt $45, $4D, $55, $4C, $43, $42, $4D, $32, $50, $52, $47 ; "EMULCBM2PRG"
wedge_filename:
        .byt $57, $45, $44, $47, $45, $20, $20, $20, $50, $52, $47 ; "WEDGE   PRG"

InitBASIC:
        bit $8001
        bpl Init128

; --------------------------------------------------------
; Initialize BASIC 256
; --------------------------------------------------------
Init256:
        jsr $bb29
        ldx #2
Init256l1:
        lda $b460,x
        sta $02,x
        dex
        bpl Init256l1
        sta $61
        ldx #4
Init256l2:
        lda $bb34,x
        sta $0259,x
        dex
        bne Init256l2
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
        jsr $b9f5
        jsr $b9ee
        ldy #0
        tya
        sta ($2d),y
        inc $2d
        bne Init256l3
        inc $2e
Init256l3:
        ldx #$26
        jsr $a32f
        jsr $8a12
        ldx #$39
        ldy #$bb
        jsr $ff6f
        lda #<vec_warm
        sta wstvec
        lda #>vec_warm
        sta wstvec+1
        cli
        jmp basic_prompt

; --------------------------------------------------------
; Initialize BASIC 128
; --------------------------------------------------------
Init128:
        jsr $bbbc
        ldx #2
Init128l1:
        lda $b4fe,x
        sta $02,x
        dex
        bpl Init128l1
        sta $61
        ldx #4
Init128l2:
        lda $bbc7,x
        sta $0259,x
        dex
        bne Init128l2
        stx $78
        stx $1a
        stx $16
        stx $0258
        stx $1d
        dex
        stx $1e
        stx $1f
        sec
        jsr $ff9c
        stx $31
        sty $32
        stx $2d
        sty $2e
        jsr $ba93
        jsr $ba8c
        ldy #0
        tya
        sta ($2d),y
        inc $2d
        bne Init128l3
        inc $2e
Init128l3:
        ldx #$26
        jsr $a3c3
        jsr $8a2b
        ldx #$cc
        ldy #$bb
        jsr $ff6f
        lda #<vec_warm
        sta wstvec
        lda #>vec_warm
        sta wstvec+1
        cli
        jmp basic_prompt

                
WarmBASIC:
        ; Break code in the ROM monitor page 1
    	lda	#$15
	    ldx	#$03
	    stx	$0302
	    sta	$0303
	    
	    ; Continue with BASIC code
        bit $8001
        bpl Warm128

; --------------------------------------------------------
; Warm start BASIC 256
; --------------------------------------------------------

        jsr $ff7b
        jsr $bb83
        jsr $ff7e
        jsr $b9ee
        jmp basic_prompt

; --------------------------------------------------------
; Warm start BASIC 128
; --------------------------------------------------------

Warm128:
        jsr $ff7b
        jsr $bc16
        jsr $ff7e
        jsr $ba8c
        jmp basic_prompt

.res ($2000-*),$FF

.define ROM

.ifndef PRG
.include "jump.asm"
.endif
