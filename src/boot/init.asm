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
        .byt $43, $C2, $CD, $31+1

; --------------------------------------------------------
; Initialization routine after RESET
; --------------------------------------------------------

do_warm:
        jmp $8003        
                
do_init:
        sei
        cld
        jsr do_ioinit
        ; Clear the TPI interrupt flag which is not cleared afer reset
        sta $DE07
        lda #$F0
        sta PgmKeyBuf+1
        jsr jmp_scrinit
        jsr MyRamTas
        jsr Delay
        jsr do_restor
        jsr jmp_scrinit
        lda #$00
        sta WstFlag
        lda #$0F
        sta IndReg
        jsr set_keys
        lda #<msg_init
        ldy #>msg_init
        jsr output_banner
        cli
do_init2:
        ldx #$01
        jsr CHKIN
        jsr GETIN
        beq do_init2
        sta $1FFF
        cmp #$85
        beq init_emulation
        jmp do_init2

init_emulation:
        sei
        jmp boot_file
        
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
        beq @end
        jsr BSOUT
        inc screen_ptr
        bne @loop
        inc screen_ptr+1
        bne @loop
@end:
        rts        
        

; --------------------------------------------------------
; Redefine funciton keys
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
        lda #3
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
; Boot messages
; --------------------------------------------------------

msg_init:
        .byt "Z8000 card boot ROM v1.0 (C) 2025 Michal Pleban", $0D, $0D
        .byt " [F1] - boot Commodore 900 emulation", $0D
        .byt " [F2] - boot into BASIC", $0D
        .byt 0

func_keys:
        .byt $85, $89, $86, $8A, $87, $8B, $88, $8C

.include "boot.asm"

.res ($2000-*),$FF
