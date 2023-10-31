
scc_handle:
        lda z8000_status
        asl a
        lda z8000_addr
        and #$FE
        adc #$00
        asl a
        tax
        lda scc_table,x
        sta io_jump
        lda scc_table+1,x
        sta io_jump+1
        jsr io_handle
        jmp nmi_end

scc_status:
        lda #$04
        sta z8000_data
        rts
        
scc_output:
        lda z8000_data
        jmp screen_output
                
scc_table:
        .word undefined, scc_status     ; 00
        .word undefined, undefined      ; 01
        .word empty, undefined          ; 02
        .word empty, undefined          ; 03
        .word empty, undefined          ; 04
        .word empty, undefined          ; 05
        .word empty, undefined          ; 06
        .word empty, undefined          ; 07
        .word scc_output, undefined      ; 08
        .word empty, undefined          ; 09
        .word empty, undefined          ; 0A
        .word empty, undefined          ; 0B
        .word empty, undefined          ; 0C
        .word empty, undefined          ; 0D
        .word empty, undefined          ; 0E
        .word empty, undefined          ; 0F
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
