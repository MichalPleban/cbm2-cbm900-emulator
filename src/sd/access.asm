
sd_read:        
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF

        ; Send CMD17
        SD_WRITE $51
        SD_WRITE_MEM sd_sector+3
        SD_WRITE_MEM sd_sector+2
        SD_WRITE_MEM sd_sector+1
        SD_WRITE_MEM sd_sector+0
        SD_WRITE $01
       
        ; Wait for 00 response
        lda #10
        sta sd_loop+1
        lda #0
        sta sd_loop
@loop1:
        SD_WRITE $FF
        cmp #$00
        beq @continue1
        dec sd_loop
        bne @loop1
        dec sd_loop+1
        bne @loop1
        lda #$11
        jmp @error

@continue1:
        ; Wait for data token
        lda #10
        sta sd_loop+1
        lda #0
        sta sd_loop
@loop2:
        SD_WRITE $FF
        cmp #$FE
        beq @continue2
        dec sd_loop
        bne @loop2
        dec sd_loop+1
        bne @loop2
        lda #$12
        jmp @error
        
        ; Read data bytes      
@continue2:
        jsr sd_read_loop
       
        ; Read CRC
        SD_WRITE $FF
        SD_WRITE $FF

        clc
        lda #$00
        rts
@error:
        sec
        rts

sd_write:        
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF
        SD_WRITE $FF

        ; Send CMD24
        SD_WRITE $58
        SD_WRITE_MEM sd_sector+3
        SD_WRITE_MEM sd_sector+2
        SD_WRITE_MEM sd_sector+1
        SD_WRITE_MEM sd_sector+0
        SD_WRITE $01
       
        ; Wait for 00 response
        lda #10
        sta sd_loop+1
        lda #0
        sta sd_loop
@loop1:
        SD_WRITE $FF
        cmp #$00
        beq @continue1
        dec sd_loop
        bne @loop1
        dec sd_loop+1
        bne @loop1
        lda #$21
        jmp @error

@continue1:
        ; Write data token
        SD_WRITE $FF
        SD_WRITE $FE

        ; Send data bytes      
        jsr sd_write_loop

        ; Send dummy CRC
        SD_WRITE $00
        SD_WRITE $00
        
        ; Check response
        SD_WRITE $FF
        pha
        SD_WRITE $FF
        pla
        and #$1F
        cmp #$05
        beq @continue2
        lda #$22
        jmp @error

@continue2:
        ; Wait while the card is busy
        lda #100
        sta sd_loop+1
        lda #0
        sta sd_loop
@loop2:
        SD_WRITE $FF
        cmp #$FF
        beq @finished
        dec sd_loop
        bne @loop2
        dec sd_loop+1
        bne @loop2
        lda #$23
        jmp @error

@finished:       
        clc
        lda #$00
        rts
@error:
        sec
        rts
        