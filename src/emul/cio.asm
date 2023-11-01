
cio_handle:
        lda z8000_status
        asl a
        lda z8000_addr
        and #$7E
        adc #$00
        asl a
        tax
        lda cio_table,x
        sta io_jump
        lda cio_table+1,x
        sta io_jump+1
        jsr io_handle
        jmp nmi_end

        
cio_tmp:
        lda #$00
        sta z8000_data
        rts
                
cio_table:
        .word undefined, undefined      ; 00
        .word undefined, undefined      ; 01
        .word undefined, undefined      ; 02
        .word undefined, undefined      ; 03
        .word undefined, undefined      ; 04
        .word undefined, undefined      ; 05
        .word undefined, undefined      ; 06
        .word undefined, undefined      ; 07
        .word undefined, cio_tmp      ; 08
        .word undefined, undefined      ; 09
        .word undefined, undefined      ; 0A
        .word undefined, undefined      ; 0B
        .word undefined, undefined      ; 0C
        .word undefined, undefined      ; 0D
        .word undefined, undefined      ; 0E
        .word undefined, undefined      ; 0F
        .word undefined, undefined      ; 10
        .word undefined, undefined      ; 11
        .word undefined, undefined      ; 12
        .word undefined, undefined      ; 13
        .word undefined, undefined      ; 14
        .word undefined, undefined      ; 15
        .word undefined, undefined      ; 16
        .word undefined, undefined      ; 17
        .word undefined, undefined      ; 18
        .word undefined, undefined      ; 19
        .word undefined, undefined      ; 1A
        .word undefined, undefined      ; 1B
        .word undefined, undefined      ; 1C
        .word undefined, undefined      ; 1D
        .word undefined, undefined      ; 1E
        .word undefined, undefined      ; 1F
        .word undefined, undefined      ; 20
        .word undefined, undefined      ; 21
        .word undefined, undefined      ; 22
        .word undefined, undefined      ; 23
        .word undefined, undefined      ; 24
        .word undefined, undefined      ; 25
        .word undefined, undefined      ; 26
        .word undefined, undefined      ; 27
        .word undefined, undefined      ; 28
        .word undefined, undefined      ; 29
        .word undefined, undefined      ; 2A
        .word undefined, undefined      ; 2B
        .word undefined, undefined      ; 2C
        .word undefined, undefined      ; 2D
        .word undefined, undefined      ; 2E
        .word undefined, undefined      ; 2F
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
