InputHandler:
	lda globalTick
	and #$03
	cmp #$00
	beq InputB
	jmp InputHandlerDone
	
InputB:
	lda buttons1
	and #$40
	cmp #$40
	bne InputBDone
	
	lda tileBufferLength
	cmp #$00
	bne InputBDone
	
	lda #$01
	sta guiMode
	jsr closeCurrentTextBox

InputBDone:

InputA:
	lda buttons1
	and #$80
	cmp #$80
	bne InputADone
	
	lda tileBufferLength
	cmp #$00
	bne InputADone
	
	lda guiMode
	cmp #$00
	beq InputAPauseScreen
	cmp #$01
	beq InputAMainScreen
	cmp #$02
	beq InputABuildScreen
	jmp InputADone
	
InputAMainScreen:
	lda #$02
	sta guiMode
	jsr textboxBuildOpen
	jmp InputADone
	
InputAPauseScreen:
	jmp InputADone
	
InputABuildScreen:
	jmp InputADone
	
	;                ; this code adds a farm tile directly to the gfx buffer (DOESNT EDIT THE MAP)
	; lda #$03
	; sta tileBuffer
	; lda #$01
	; sta tileBufferLength
	; lda cursorX
	; sta tileBuffer + 1
	; lda cursorY
	; clc
	; adc #$03
	; sta tileBuffer + 2
	
InputADone:

InputRight:
	lda buttons1
	and #$01
	cmp #$01
	bne InputRightDone
	inc cursorX
	lda cursorX
	and #$0f
	sta cursorX
InputRightDone:

InputLeft:
	lda buttons1
	and #$02
	cmp #$02
	bne InputLeftDone
	dec cursorX
	lda cursorX
	and #$0f
	sta cursorX
InputLeftDone:

InputUp:
	lda buttons1
	and #$08
	cmp #$08
	bne InputUpDone
	
	lda guiMode
	cmp #$01
	beq InputUpMainScreen
	jmp InputUpMenuScreen
	
InputUpMenuScreen:
	dec menuCursorPos ; cursor pos--; if its greater than or equal to the amt of items then set it to menuSize-1 
	lda menuCursorPos
	cmp menuSize
	bcc InputUpDone
	lda menuSize
	sec
	sbc #$01
	sta menuCursorPos
	
	jmp InputUpDone	
	
InputUpMainScreen:
	dec cursorY
	lda cursorY
	cmp #$0c
	bcc InputUpDone
	lda #$0b
	sta cursorY
InputUpDone

InputDown:
	lda buttons1
	and #$04
	cmp #$04
	bne InputDownDone
	
	lda guiMode
	cmp #$01
	beq InputDownMainScreen
	jmp InputDownMenuScreen

InputDownMenuScreen:
	inc menuCursorPos ; cursor pos++; if its greater than or equal to the amt of items then set it to 0 
	lda menuCursorPos
	cmp menuSize
	bcc InputDownDone
	lda #$00
	sta menuCursorPos
	jmp InputDownDone

InputDownMainScreen:
	inc cursorY
	lda cursorY
	cmp #$0c
	bcc InputDownDone
	lda #$00
	sta cursorY
InputDownDone:

InputHandlerDone:
	rts