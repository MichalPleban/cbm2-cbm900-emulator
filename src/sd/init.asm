

sd_init:
        ; Step 1: start up the card by sending dummy bytes
        lda #10
        sta sd_loop+1
        lda #0
        sta sd_loop
@loop1:
        SD_WRITE $FF
        SD_WRITE $FF
        dec sd_loop
        bne @loop1
        dec sd_loop+1
        bne @loop1
        
@step2:        
        ; Step 2: send CMD0
        SD_WRITE $40
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $95
        SD_WRITE $FF
        SD_WRITE $FF
        pha
        SD_WRITE $FF
        pla
        cmp #$01
        beq @step3
        lda #$01
        jmp @error

@step3:
        ; Step 3: send CMD8
        SD_WRITE $48
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $01
        SD_WRITE $AA
        SD_WRITE $87
        SD_WRITE $FF
        SD_WRITE $FF
        cmp #$05
        beq @step3_skip
        cmp #$01
        beq @step3_noskip
        lda #$02
        jmp @error
@step3_noskip:        
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
@step3_skip:
        SD_WRITE $FF

        lda #100
        sta sd_loop+1
        lda #0
        sta sd_loop
@loop2:
        ; Step 4A: send CMD55
        SD_WRITE $77
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $01
        SD_WRITE $FF        
        SD_WRITE $FF
        pha        
        SD_WRITE $FF
        pla
        ; cmp #$05
        cmp #$01
        beq @step4
        lda #$03
        jmp @error

@step4:
        ; Step 4B: send ACMD41
        SD_WRITE $69
        SD_WRITE $40
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $77
        SD_WRITE $FF        
        SD_WRITE $FF
        pha        
        SD_WRITE $FF
        pla
        ; cmp #$05
        cmp #$00
        beq @step5
        cmp #$01
        beq @loop3
        lda #$04
        jmp @error
@loop3:
        dec sd_loop
        bne @loop2
        dec sd_loop+1
        bne @loop2
        lda #$05
        jmp @error        

@step5:
        ; Step 5: Send CMD58
        SD_WRITE $7A
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $01
        SD_WRITE $FF
        SD_WRITE $FF
        cmp #$00
        bne @error
        SD_WRITE $FF
        pha
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        pla
        and #$40
        bne @finished
                        
        ; Step 6: Send CMD16 (only if not SDHC)
        SD_WRITE $50
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $00
        SD_WRITE $02
        SD_WRITE $01
        SD_WRITE $FF
        SD_WRITE $FF
        pha
        SD_WRITE $FF
        pla
        cmp #0
        beq @finished
        lda #$06
        
@finished:
        lda #$00
        clc
        rts

@error:
        sec
        rts

        