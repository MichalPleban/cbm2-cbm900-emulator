
fat32_init:
        jsr sd_init
        bcc @init_ok
        rts
@init_ok:

        BANK_SAVE
fat32_init_step1:
        ; Step 1 - read MBR and check partition table
        jsr fat32_set_buffer
        lda #$00
        sta sd_sector
        sta sd_sector+1
        sta sd_sector+2
        sta sd_sector+3
        jsr sd_read
        lda fat32_buffer+510
        cmp #$55
        beq firstbyte_ok
        lda #$31
fat32_init_error:
        BANK_RESTORE
        sec
        rts
firstbyte_ok:
        lda fat32_buffer+511
        cmp #$AA
        beq @secondbyte_ok
        lda #$31
        bne fat32_init_error
@secondbyte_ok:
        lda fat32_buffer+450
        cmp #$0B
        beq @partition_ok
        cmp #$0C
        beq @partition_ok
        lda #$32
        bne fat32_init_error
@partition_ok:
        ldy #3
@copy_part_start:        
        lda fat32_buffer+454,y
        sta fat32_pointers+PARTITION_START,y
        dey
        bpl @copy_part_start

fat32_init_step2:
        ; Step 2 - read partition boot sector
        ldy #PARTITION_START
        jsr fat32_load_sector
        bcs fat32_init_error
        lda fat32_buffer+510
        cmp #$55
        beq @firstbyte_ok
        lda #$33
        bne fat32_init_error
@firstbyte_ok:
        lda fat32_buffer+511
        cmp #$AA
        beq @secondbyte_ok
        lda #$33
        bne fat32_init_error
@secondbyte_ok:
        lda fat32_buffer+11
        beq @lsb_bytes_ok
        lda #$33
        bne fat32_init_error
@lsb_bytes_ok:
        lda fat32_buffer+12
        cmp #$02
        beq @msb_bytes_ok
        lda #$33
        bne fat32_init_error
@msb_bytes_ok:        

fat32_init_step3:
        ; Step 3 - read partition data
        lda fat32_buffer+13
        sta fat32_cluster_sectors
        lda fat32_buffer+16
        sta fat32_fat_copies
        lda fat32_buffer+14
        sta fat32_pointers+RESERVED_SECTORS
        lda fat32_buffer+15
        sta fat32_pointers+RESERVED_SECTORS+1
        lda #$00
        sta fat32_pointers+RESERVED_SECTORS+2
        sta fat32_pointers+RESERVED_SECTORS+3
        ldy #3
@copy_data:        
        lda fat32_buffer+36,y
        sta fat32_pointers+FAT_SECTORS,y
        lda fat32_buffer+44,y
        sta fat32_pointers+ROOT_CLUSTER,y
        dey
        bpl @copy_data
        
fat32_init_step4:
        ; Step 4 - calculate disk pointers
        ldx #PARTITION_START
        ldy #FAT_START
        jsr int32_copy
        ldx #RESERVED_SECTORS
        jsr int32_add
        ldx #FAT_START
        ldy #DATA_START
        jsr int32_copy
        lda fat32_fat_copies
        sta scratchpad
        ldx #FAT_SECTORS
@add_fats:
        jsr int32_add
        dec scratchpad
        bne @add_fats

        BANK_RESTORE
        lda #$00
        clc 
        rts        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Search for specified file
; Input:
;   A:Y - pointer to the name of the file to be found
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
fat32_find_file:
        BANK_SAVE
        sta scratchpad
        sty scratchpad+1
        ldx #ROOT_CLUSTER
        ldy #CURRENT_CLUSTER
        jsr int32_copy
        
        ; Load a root directory cluster 
@load_cluster:        
        ldx #CURRENT_CLUSTER
        ldy #CURRENT_SECTOR
        jsr fat32_cluster_to_sector
        lda #0
        sta fat32_sector_number
        
        ; Load next sector from the cluster
@load_sector:        
        jsr fat32_load_sector
        lda #<fat32_buffer
        sta scratchpad+2
        lda #>fat32_buffer
        sta scratchpad+3
        
        ; Search one directory entry
        ldy #10
@filename_loop:        
        lda (scratchpad),y
        cmp (scratchpad+2),y
        bne @filename_no_match
        dey
        bpl @filename_loop
        
        ; File is found!
        ldy #$14
        lda (scratchpad+2),y
        sta fat32_pointers+FILE_CLUSTER+2
        iny
        lda (scratchpad+2),y
        sta fat32_pointers+FILE_CLUSTER+3
        ldy #$1A
        lda (scratchpad+2),y
        sta fat32_pointers+FILE_CLUSTER
        iny
        lda (scratchpad+2),y
        sta fat32_pointers+FILE_CLUSTER+1
        ldx #0
@size_loop:        
        iny
        lda (scratchpad+2),y
        sta fat32_pointers+FILE_SIZE,x
        inx
        cpx #4
        bne @size_loop
        jmp @exit
        
        ; Go to next directory entry
@filename_no_match:
        clc
        lda scratchpad+2
        adc #$20
        sta scratchpad+2
        lda scratchpad+3
        adc #$00
        sta scratchpad+3
        cmp #>fat32_buffer+2
        bne @filename_loop
        
        ; Load next sector
        ldy #CURRENT_SECTOR
        jsr int32_inc
        inc fat32_sector_number
        lda fat32_sector_number
        cmp fat32_cluster_sectors
        bne @load_sector
        
        ldx #CURRENT_CLUSTER
        ldy #CURRENT_CLUSTER
        jsr fat32_next_cluster
        lda fat32_pointers+CURRENT_CLUSTER+3
        beq @load_cluster
        
        lda #$41
@error:
        BANK_RESTORE
        sec
        rts

@exit:
        BANK_RESTORE
        clc
        lda #$00
        rts
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Scans the FAT for file fragments (max 31)
; Input:
;   A:Y - pointer to the list of file fragments
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
fat32_scan_file:
        BANK_SAVE
        sta scratchpad
        sty scratchpad+1
        lda #0
        sta fat32_pointers+FILE_SECTOR
        sta fat32_pointers+FILE_SECTOR+1
        sta fat32_pointers+FILE_SECTOR+2
        sta fat32_pointers+FILE_SECTOR+3
        tay
        sta (scratchpad),y
        iny
        sta (scratchpad),y
        iny
        sta (scratchpad),y
        iny
        sta (scratchpad),y
        lda scratchpad
        clc
        adc #4
        sta scratchpad
        lda scratchpad+1
        adc #0
        sta scratchpad+1

        lda #30
        sta scratchpad+4
        
@calc_sector:
        ldx #FILE_CLUSTER
        ldy #CURRENT_SECTOR
        jsr fat32_cluster_to_sector
        lda scratchpad+4
        
        ; Copy current sector to the fragment table
        ldy #3
@copy_sector:
        lda fat32_pointers+CURRENT_SECTOR,y
        sta (scratchpad),y
        dey
        bpl @copy_sector
        lda scratchpad
        clc
        adc #4
        sta scratchpad
        lda scratchpad+1
        adc #0
        sta scratchpad+1
        
        ; Add numbbr of sector in the cluster to current position
@inc_position:
        lda fat32_cluster_sectors
        clc
        adc fat32_pointers+FILE_SECTOR
        sta fat32_pointers+FILE_SECTOR
        lda fat32_pointers+FILE_SECTOR+1
        adc #0
        sta fat32_pointers+FILE_SECTOR+1
        lda fat32_pointers+FILE_SECTOR+2
        adc #0
        sta fat32_pointers+FILE_SECTOR+2
        lda fat32_pointers+FILE_SECTOR+3
        adc #0
        sta fat32_pointers+FILE_SECTOR+3
        
        ; Calculate next cluster and compare it with old+1
        ldx #FILE_CLUSTER
        ldy #CURRENT_CLUSTER
        jsr int32_copy
        jsr int32_inc
        ldy #FILE_CLUSTER
        jsr fat32_next_cluster
        ldx #FILE_CLUSTER
        ldy #CURRENT_CLUSTER
        jsr int32_cmp
        beq @inc_position
        
        ; Copy current position to the fragment table
        ldy #3
@copy_position:
        lda fat32_pointers+FILE_SECTOR,y
        sta (scratchpad),y
        dey
        bpl @copy_position
        lda scratchpad
        clc
        adc #4
        sta scratchpad
        lda scratchpad+1
        adc #0
        sta scratchpad+1
                
        lda fat32_pointers+FILE_CLUSTER+3
        bne @file_end
        dec scratchpad+4
             
        bpl @calc_sector
        lda #$51
        sec
        bcs @error

        ; End of file reached        
@file_end:
        ldy #7
        lda #$80
@copy_end:
        sta (scratchpad),y
        dey
        bpl @copy_end

@exit:
        lda #$00
        clc
@error:
        BANK_RESTORE
        rts       
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Translates logocal file sector to physical disk sector
; Input:
;   A:Y - pointer to the list of file fragments
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
fat32_translate:
        BANK_SAVE
        sta scratchpad
        sty scratchpad+1
        
@find_fragment:
        ; Find first file fragment after current sector
        ldy #11
@compare_loop:
        lda sd_sector-8,y
        cmp (scratchpad),y
        beq @continue
        bcc @found
        bcs @is_greater
@continue:
        dey
        cpy #8
        bne @compare_loop
        lda sd_sector-8,y
        cmp (scratchpad),y
        bcs @is_greater

@found:
        ; Subtract sector start from the previous fragment
        ldy #0
        sec
        php
@subtract_loop:
        plp
        lda sd_sector,y
        sbc (scratchpad),y
        php
        sta sd_sector,y
        iny
        cpy #4
        bne @subtract_loop 
        plp
        
        ; Add physical sector from the previous fragment
        ldy #4
        clc
        php
@add_loop:
        plp
        lda sd_sector-4,y
        adc (scratchpad),y
        php
        sta sd_sector-4,y
        iny
        cpy #8
        bne @add_loop 
        plp
        tax
        bpl @exit
        lda #$52
        sec
        bcs @error
        
@is_greater:
        lda scratchpad
        clc
        adc #8
        sta scratchpad
        lda scratchpad+1
        adc #0
        sta scratchpad+1
        jmp @find_fragment
        
@exit:
        lda #$00
        clc
@error:
        BANK_RESTORE
        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Calculates sector number for the cluster
; Y := sector (X)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat32_cluster_to_sector:

        ; Subtract root cluster # from the current cluster
        jsr int32_copy
        ldx #ROOT_CLUSTER
        jsr int32_sub
        
        ; Multiply by number of sectors in cluster
        lda fat32_cluster_sectors
        lsr
        bcs @end
        sta scratchpad+2
@loop:
        jsr int32_shl
        lsr scratchpad+2
        bcc @loop

@end:        
        ; Add starting sector number
        ldx #DATA_START
        jsr int32_add
        rts
                
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Retrieve next cluster from FAT
; Y := next cluster (X)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat32_next_cluster:
        tya
        pha
        txa
        pha

        ; Divide cluster number by 128
        lda fat32_pointers,x
        asl
        lda fat32_pointers+1,x
        rol
        sta fat32_pointers+CURRENT_SECTOR
        lda fat32_pointers+2,x
        rol
        sta fat32_pointers+CURRENT_SECTOR+1
        lda fat32_pointers+3,x
        rol
        sta fat32_pointers+CURRENT_SECTOR+2
        lda #0
        sta fat32_pointers+CURRENT_SECTOR+3
        
        ; Load appropriate FAT sector
        ldx #FAT_START
        ldy #CURRENT_SECTOR
        jsr int32_add
        lda sd_sector
        cmp fat32_pointers+CURRENT_SECTOR
        bne @not_in_cache
        lda sd_sector+1
        cmp fat32_pointers+CURRENT_SECTOR+1
        bne @not_in_cache
        lda sd_sector+2
        cmp fat32_pointers+CURRENT_SECTOR+2
        bne @not_in_cache
        lda sd_sector+3
        cmp fat32_pointers+CURRENT_SECTOR+3
        beq @in_cache
@not_in_cache:
        jsr fat32_load_sector
@in_cache:
        ; Find position in the FAT sector
        pla
        tax
        lda fat32_pointers,x
        and #127
        asl
        asl
        sta scratchpad+2
        lda #>fat32_buffer
        adc #0
        sta scratchpad+3
        
        ; Copy cluster number to the destination
        pla
        tax
        ldy #0
@loop:
        lda (scratchpad+2),y
        sta fat32_pointers,x
        inx
        iny
        cpy #4
        bne @loop
        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set SD buffer pointer to the FAT32 buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat32_set_buffer:
        lda EXEC_REG
        ora #$80
        sta sd_bank
        lda #<fat32_buffer
        sta sd_ptr
        lda #>fat32_buffer
        sta sd_ptr+1
        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load sector into memory
; Input: Y - location of the int32 sector number in the FAT32 variable block.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat32_load_sector:        
        lda fat32_pointers,y
        sta sd_sector
        lda fat32_pointers+1,y
        sta sd_sector+1
        lda fat32_pointers+2,y
        sta sd_sector+2
        lda fat32_pointers+3,y
        sta sd_sector+3
        jsr fat32_set_buffer
        jmp sd_read

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copies an int32 number
; Y := X
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
int32_copy:
        lda fat32_pointers,x
        sta fat32_pointers,y
        lda fat32_pointers+1,x
        sta fat32_pointers+1,y
        lda fat32_pointers+2,x
        sta fat32_pointers+2,y
        lda fat32_pointers+3,x
        sta fat32_pointers+3,y
        rts
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Increments a int32 number
; Y := Y + 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
int32_inc:
        sec
        lda fat32_pointers,y
        adc #0
        sta fat32_pointers,y
        lda fat32_pointers+1,y
        adc #0
        sta fat32_pointers+1,y
        lda fat32_pointers+2,y
        adc #0
        sta fat32_pointers+2,y
        lda fat32_pointers+3,y
        adc #0
        sta fat32_pointers+3,y
        rts
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shifts left a int32 number
; Y := Y << 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
int32_shl:
        lda fat32_pointers,y
        asl
        sta fat32_pointers,y
        lda fat32_pointers+1,y
        rol
        sta fat32_pointers+1,y
        lda fat32_pointers+2,y
        rol
        sta fat32_pointers+2,y
        lda fat32_pointers+3,y
        rol
        sta fat32_pointers+3,y
        rts
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Adds two int32 numbers
; Y := Y + X
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
int32_add:
        clc
        lda fat32_pointers,y
        adc fat32_pointers,x
        sta fat32_pointers,y
        lda fat32_pointers+1,y
        adc fat32_pointers+1,x
        sta fat32_pointers+1,y
        lda fat32_pointers+2,y
        adc fat32_pointers+2,x
        sta fat32_pointers+2,y
        lda fat32_pointers+3,y
        adc fat32_pointers+3,x
        sta fat32_pointers+3,y
        rts
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Subtracts two int32 numbers
; Y := Y - X
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
int32_sub:
        sec
        lda fat32_pointers,y
        sbc fat32_pointers,x
        sta fat32_pointers,y
        lda fat32_pointers+1,y
        sbc fat32_pointers+1,x
        sta fat32_pointers+1,y
        lda fat32_pointers+2,y
        sbc fat32_pointers+2,x
        sta fat32_pointers+2,y
        lda fat32_pointers+3,y
        sbc fat32_pointers+3,x
        sta fat32_pointers+3,y
        rts
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Compares two int32 numbers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
int32_cmp:
        lda fat32_pointers,y
        cmp fat32_pointers,x
        bne @end
        lda fat32_pointers+1,y
        cmp fat32_pointers+1,x
        bne @end
        lda fat32_pointers+2,y
        cmp fat32_pointers+2,x
        bne @end
        lda fat32_pointers+3,y
        cmp fat32_pointers+3,x
@end:
        rts
        
        