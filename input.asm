InputHandler:
	
InputB:
	lda buttons1
	and #$40
	cmp #$40
	bne InputBDone
	
	lda prevButtons1
	and #$40
	cmp #$40
	beq InputBDone
	
	lda tileBufferLength
	cmp #$00
	bne InputBDone
	
	lda guiMode
	cmp #$02
	beq InputBMenuScreen
	cmp #$03
	beq InputBUnitScreen
	jmp InputBDone
	
InputBMenuScreen:
	lda #$01
	sta guiMode
	jsr closeCurrentTextBox
	jmp InputBDone

InputBUnitScreen:
	lda #$02
	sta guiMode
	jsr closeCurrentTextBox
	jsr textboxBuildOpen
	jmp InputBDone

InputBDone:

InputA:
	lda buttons1
	and #$80
	cmp #$80
	bne InputADone
	
	lda prevButtons1
	and #$80
	cmp #$80
	beq InputADone
	
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

	lda menuCursorPos
	cmp #$01
	beq PlaceFarm
	cmp #$00
	beq UnitMenu

PlaceFarm:
	lda cursorY
	asl a
	asl a
	asl a
	asl a
	clc
	adc cursorX
	tax
	lda #$03
	sta MapData, x
	
	lda cursorX
	sta param4
	lda cursorY
	clc
	adc #MAP_DRAW_Y
	sta param5
	lda #$01
	sta param6
	sta param7
	jsr drawMapChunk

	lda #$01
	sta guiMode
	jsr closeCurrentTextBox
	
	jmp InputADone
	
UnitMenu:
	
	lda #$03
	sta guiMode
	jsr textboxUnitOpen
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

	; Control Pad inputs only happen every 4 frames
	lda globalTick
	and #$03
	cmp #$00
	beq InputRight
	jmp InputHandlerDone

InputRight:
	lda buttons1
	and #$01
	cmp #$01
	bne InputRightDone
	
	lda guiMode
	cmp #$01
	bne InputRightDone ; left and right only work in guimode 1 main screen
	
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
	
	lda guiMode
	cmp #$01
	bne InputLeftDone ; left and right only work in guimode 1 main screen
	
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