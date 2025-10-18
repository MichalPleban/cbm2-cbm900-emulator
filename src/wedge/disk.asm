
; --------------------------------------------------------
; Install wedge routine hook into BASIC
; The trampoline address is #1150 (wedge function #6)
;  and the vector is $0282 (warm start link)
; --------------------------------------------------------
WedgeInstall:
        lda #$82
        sta mem_ptr
        lda #$02
        sta mem_ptr+1
        ldy #0
        lda #$50
		sta (mem_ptr),y
		iny
		lda #$11
		sta (mem_ptr),y
		lda #8
		sta WedgeDevice
		rts
		
; --------------------------------------------------------
; Hook into BASIC "process next line" routine
; --------------------------------------------------------
WedgeHook:
        ; Write $FF to the following BASIC variables: $43, $8F, $0298/99
        lda IndReg
        pha
        lda #$0f
        sta IndReg
        lda #$0f
        sta 1
		lda #$ff
        ldx #$43
        stx mem_ptr
        ldx #$00
        stx mem_ptr+1
        ldy #0
        sta (mem_ptr),y
        ldx #$8F
        stx mem_ptr
        sta (mem_ptr),y
        ldx #$98
        stx mem_ptr
        ldx #$02
        stx mem_ptr+1
        sta (mem_ptr),y
        iny
        sta (mem_ptr),y
        pla
        sta IndReg
        
        ; Get one line from the editor
		jsr BasicInputLine
		
		; Store the returned variables in $85-87
		sta WedgeBuffer
		sty WedgeBuffer+1
		stx WedgeBuffer+2
		jsr WedgeBufferTo85
		
		jsr Chrget
		tax
		beq WedgeHook
		bcc WedgeLineNumber
		cmp #'@'
		beq WedgeExecute
		bit basic_type
		bmi WedgeFollow256
		jmp jump_85EA
WedgeFollow256:
		jmp jump_85E2
WedgeLineNumber:
		bit basic_type
		bmi WedgeLineNumber256
		jmp jump_85F3
WedgeLineNumber256:
		jmp jump_85EB
		
; --------------------------------------------------------
; Execute wedge command
; --------------------------------------------------------
WedgeExecute:
        ; Reset device status
		jsr ClearStatus
		
		; Load the variables $85-87 back to our bank
		lda IndReg
		pha
		lda #$0F
		sta IndReg
		lda #$85
		sta mem_ptr
		ldy #$00
		sty mem_ptr+1
		lda (mem_ptr),y
		sta WedgeBuffer
		iny
		lda (mem_ptr),y
		sta WedgeBuffer+1
		iny
		lda (mem_ptr),y
		sta WedgeBuffer+2

		; Get next character		
		lda WedgeBuffer+2
		sta IndReg
		lda #0
		sta WedgeTmp
		ldy #1
		lda (WedgeBuffer),y
		beq WedgeStatus
		
		; Interpret the command
		cmp #$5F        ; left arrow
		beq WedgeChangeNumber
		cmp #'0'
		bcc WedgeExecute1
		cmp #'9'+1
		bcc WedgeSetNumber
WedgeExecute1:
		jsr WedgeCommand
WedgeEnd:
		pla
		sta IndReg
		jsr ReadStatus
		; bit Status
		bpl WedgeEnd1
		ldx #10
		jmp BasicPrintError		
WedgeEnd1:
		jmp BasicPrintReady

; --------------------------------------------------------
; Set drive number
; --------------------------------------------------------
WedgeChangeNumber:
		iny
		lda (WedgeBuffer),y
		jsr WedgeGetNumber
		cmp #8
		bcc WedgeError
		cmp #32
		bcs WedgeError
		sta WedgeTmp
		lda #<CommandSetNumber
		sta WedgeBuffer
		lda #>CommandSetNumber
		sta WedgeBuffer+1
		lda 0
		sta IndReg
		ldy #0
		jsr WedgeCommand
		jsr ReadStatus
		; bit Status
		bmi WedgeChangeNumber1
		lda WedgeTmp
		sta WedgeDevice
		; lda #0
		; sta IECStatus
		; sta IECStatus2
WedgeChangeNumber1:
		jmp WedgeEnd
		
; --------------------------------------------------------
; Show drive status
; --------------------------------------------------------
WedgeStatus:
		jmp WedgeEnd	
			
; --------------------------------------------------------
; "ILLEGAL DEVICE NUMBER"
; --------------------------------------------------------
WedgeError:
		pla
		sta IndReg
		ldx #18
		jmp BasicPrintError
				
; --------------------------------------------------------
; Change current drive number
; --------------------------------------------------------
WedgeSetNumber:
		jsr WedgeGetNumber
		cmp #$72
		beq WedgeSet8050
		cmp #$3A
		beq WedgeSet8250
		cmp #8
		bcc WedgeError
		cmp #32
		bcs WedgeError
		sta WedgeDevice
		jmp WedgeEnd

; --------------------------------------------------------
; Send special commands to the drive
; --------------------------------------------------------
WedgeSet8050:
		lda #<CommandSet8050
		sta WedgeBuffer
		lda #>CommandSet8050
		sta WedgeBuffer+1
		bne WedgeSet
WedgeSet8250:
		lda #<CommandSet8250
		sta WedgeBuffer
		lda #>CommandSet8250
		sta WedgeBuffer+1
WedgeSet:
		lda 0
		sta IndReg
		ldy #0
		jsr WedgeCommand
;            jmp WedgeEnd
		lda #<CommandSoftReset
		sta WedgeBuffer
		lda #>CommandSoftReset
		sta WedgeBuffer+1
		ldy #0
		jsr WedgeCommand
		jmp WedgeEnd
		
; --------------------------------------------------------
; Send command to the drive
; --------------------------------------------------------
WedgeCommand:
        sei
		lda WedgeDevice
		jsr jump_listen
		lda #$FF
		jsr jump_second
WedgeCommand2:
		lda (WedgeBuffer),y
		beq WedgeCommand1
	    jsr jump_ciout
		iny
		bne WedgeCommand2
WedgeCommand1:
		lda WedgeTmp
		beq WedgeCommand5
		lda #0
		jsr jump_ciout
		lda #2
		jsr jump_ciout
		lda WedgeTmp
		ora #32
		jsr jump_ciout
		lda WedgeTmp
		ora #64
		jsr jump_ciout
WedgeCommand5:
		jsr jump_unlsn
		jsr ClearStatus
		lda WedgeDevice
		jsr jump_talk
		lda #$6F
		jsr jump_tksa
WedgeCommand4:
		jsr jump_acptr
;		cmp #$0D
		pha
;		beq WedgeCommand3
		jsr ReadStatus
		; lda Status
		bne WedgeCommand3
		pla
		jsr jump_bsout
		jmp WedgeCommand4
WedgeCommand3:
        pla
		lda #13
		jsr jump_bsout	
		lda WedgeDevice
		jsr jump_listen
		lda #$EF
		jsr jump_second
		jsr jump_unlsn
		cli
		rts

; --------------------------------------------------------
; Retrieve a number from command line
; --------------------------------------------------------
WedgeGetNumber:
		sec
		sbc #'0'
		sta WedgeBuffer+2
WedgeGetNumber1:
		iny
		lda (WedgeBuffer),y
		beq WedgeGetNumber2
		cmp #'0'
		bcc WedgeGetNumber2
		cmp #'9'+1
		bcs WedgeGetNumber2
		sec
		sbc #'0'
		tax
		asl WedgeBuffer+2
		lda WedgeBuffer+2
		asl a
		asl a
		clc
		adc WedgeBuffer+2
		sta WedgeBuffer+2
		clc
		txa
		adc WedgeBuffer+2
		sta WedgeBuffer+2
		jmp WedgeGetNumber1
WedgeGetNumber2:
		lda WedgeBuffer+2
		sta $8000
		rts

; --------------------------------------------------------
; Special commands
; --------------------------------------------------------
CommandSoftReset:
		.byte "u9", 0
CommandSetNumber:
		.byte "m-w", 12, 0
CommandSet8050:
		.byte "m-w", 172, 16, 1, 1, 0
CommandSet8250:
		.byte "m-w", 172, 16, 1, 2, 0

Chrget:
		bit basic_type
		bmi Chrget256
		jmp jump_BA26
Chrget256:
		jmp jump_B988 

Chrgot:
		bit basic_type
		bmi Chrgot256
		jmp jump_BA29
Chrgot256:
		jmp jump_B98B 

BasicInputLine:
		bit basic_type
		bmi BasicInputLine256
		jmp jump_86E3
BasicInputLine256:
		jmp jump_86DB			

BasicPrintReady:
		bit basic_type
		bmi BasicPrintReady256
		jmp jump_85C0
BasicPrintReady256:
		jmp jump_85B8			
		
BasicPrintError:
		bit basic_type
		bmi BasicPrintError256
		jmp jump_8555
BasicPrintError256:
		jmp jump_854D			
		
ClearStatus:
        lda IndReg
        pha
        lda #$0F
        sta IndReg
        lda #$9C
        sta mem_ptr
        lda #$00
        sta mem_ptr+1
        tay
        sta (mem_ptr),y
        pla
        sta IndReg
        rts
        
ReadStatus:
        lda IndReg
        pha
        lda #$0F
        sta IndReg
        lda #$9C
        sta mem_ptr
        lda #$00
        sta mem_ptr+1
        tay
        lda (mem_ptr),y
        tay
        pla
        sta IndReg
        tya
        rts

WedgeBufferTo85:
        lda IndReg
        pha
        lda #$0f
        sta IndReg
		lda #$85
		sta mem_ptr
		ldy #$00
		sty mem_ptr+1
		lda WedgeBuffer
		sta (mem_ptr),y
		iny
		lda WedgeBuffer+1
		sta (mem_ptr),y
		iny
		lda WedgeBuffer+2
		sta (mem_ptr),y
		pla
		sta IndReg
		rts
