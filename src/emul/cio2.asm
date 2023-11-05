
cio2_handle:
        lda z8000_status
        asl a
        lda z8000_addr
        and #$7E
        adc #$00
        asl a
        tax
        lda cio2_table,x
        sta io_jump
        lda cio2_table+1,x
        sta io_jump+1
        jsr io_handle
        jmp nmi_end
        
cio2_save:
        lda z8000_addr
        lsr a
        and #$3F
        tax
        lda z8000_data
        sta cio2_registers,x
        rts

cio2_load:
        lda z8000_addr
        lsr a
        and #$3F
        tax
        lda cio2_registers,x
        sta z8000_data
        rts
                                
cio2_table:
        .word undefined, undefined      ; 00
        .word cio2_save, cio2_load      ; 01
        .word cio2_save, cio2_load      ; 02
        .word cio2_save, cio2_load      ; 03
        .word cio2_save, cio2_load      ; 04
        .word cio2_save, cio2_load      ; 05
        .word cio2_save, cio2_load      ; 06
        .word cio2_save, cio2_load      ; 07
        .word undefined, undefined      ; 08
        .word undefined, undefined      ; 09
        .word cio2_save, cio2_load      ; 0A
        .word cio2_save, cio2_load      ; 0B
        .word cio2_save, cio2_load      ; 0C
        .word cio2_save, cio2_load      ; 0D
        .word cio2_save, cio2_load      ; 0E
        .word undefined, undefined      ; 0F
        .word undefined, undefined      ; 10
        .word undefined, undefined      ; 11
        .word undefined, undefined      ; 12
        .word undefined, undefined      ; 13
        .word undefined, undefined      ; 14
        .word undefined, undefined      ; 15
        .word cio2_save, cio2_load      ; 16
        .word cio2_save, cio2_load      ; 17
        .word cio2_save, cio2_load      ; 18
        .word cio2_save, cio2_load      ; 19
        .word cio2_save, cio2_load      ; 1A
        .word cio2_save, cio2_load      ; 1B
        .word cio2_save, cio2_load      ; 1C
        .word cio2_save, cio2_load      ; 1D
        .word cio2_save, cio2_load      ; 1E
        .word undefined, undefined      ; 1F
        .word cio2_save, cio2_load      ; 20
        .word cio2_save, cio2_load      ; 21
        .word cio2_save, cio2_load      ; 22
        .word cio2_save, cio2_load      ; 23
        .word cio2_save, cio2_load      ; 24
        .word cio2_save, cio2_load      ; 25
        .word cio2_save, cio2_load      ; 26
        .word cio2_save, cio2_load      ; 27
        .word cio2_save, cio2_load      ; 28
        .word cio2_save, cio2_load      ; 29
        .word cio2_save, cio2_load      ; 2A
        .word cio2_save, cio2_load      ; 2B
        .word cio2_save, cio2_load      ; 2C
        .word cio2_save, cio2_load      ; 2D
        .word cio2_save, cio2_load      ; 2E
        .word cio2_save, cio2_load      ; 2F
        .word undefined, undefined      ; 30
        .word undefined, undefined      ; 31
        .word undefined, undefined      ; 32
        .word undefined, undefined      ; 33
        .word undefined, undefined      ; 34
        .word undefined, undefined      ; 35
        .word undefined, undefined      ; 36
        .word undefined, undefined      ; 37
        .word undefined, undefined      ; 38
        .word undefined, undefined      ; 39
        .word undefined, undefined      ; 3A
        .word undefined, undefined      ; 3B
        .word undefined, undefined      ; 3C
        .word undefined, undefined      ; 3D
        .word undefined, undefined      ; 3E
        .word undefined, undefined      ; 3F

        
