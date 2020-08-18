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
	cmp #$03
	beq InputBUnitScreen
	
	; If unsure what to do then just go back to the main guimode, that's B button default behavior
	lda #$01
	sta guiMode
	jsr closeCurrentTextBox
	jmp InputBDone

	; Unit screen leads back to build screen
InputBUnitScreen:
	lda #$02
	sta guiMode
	jsr closeCurrentTextBox
	jsr openTextBox
	jmp InputBDone

InputBDone:

InputA:
	lda buttons1
	and #$80
	cmp #$80
	beq InputACheckPrev
	jmp InputADone
	
InputACheckPrev:
	lda prevButtons1
	and #$80
	cmp #$80
	bne InputABufferCheck
	jmp InputADone
	
InputABufferCheck:
	lda tileBufferLength
	cmp #$00
	beq InputAGuimodeCheck
	jmp InputADone
	
InputAGuimodeCheck:
	lda guiMode
	cmp #$00
	beq InputAPauseScreen
	cmp #$01
	beq InputAMainScreen
	cmp #$02
	beq InputABuildScreen
	cmp #$03
	beq InputAUnitScreen
	
	jmp InputADone
	
InputAMainScreen:
	jsr AButtonMainScreenHandler
	jmp InputADone
	
InputAPauseScreen:
	jmp InputADone
	
InputABuildScreen:

	lda menuCursorPos
	cmp #$01
	beq PlaceFarm
	cmp #$00
	beq UnitMenu
	
InputAUnitScreen:
	lda menuCursorPos
	cmp #$00
	beq PlaceChicken

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
	jsr endTurn
	
	jmp InputADone
	
UnitMenu:
	lda #$03
	sta guiMode
	jsr openTextBox
	jmp InputADone
	
PlaceChicken:
	lda cursorX
	sta param4
	lda cursorY
	sta param5
	lda #$01
	sta param6
	lda #$00
	sta param7
	jsr placeUnit
	
	lda #$02
	sta guiMode
	jsr closeCurrentTextBox
	jsr endTurn
	
	jmp InputADone
	
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
	
AButtonMainScreenHandler:

	; firstly checks if a unit occupies the space
	
	ldx #$00
ABtnScanPiecesLoop:
	lda p1PiecesX, x
	cmp cursorX
	bne ABtnScanPiecesLoopTail
	
	lda p1PiecesY, x
	cmp cursorY
	bne ABtnScanPiecesLoopTail
	
AButtonMainScreenHasUnit:

	lda p1PiecesType, x
	cmp #$00
	beq openFarmerWindow
	cmp #$01
	beq openChickenWindow
	cmp #$02
	beq openCowWindow
	
openFarmerWindow:
	lda #$04
	sta guiMode
	jsr openTextBox
	jmp AButtonMainScreenDone
	
openChickenWindow:
	jmp AButtonMainScreenDone
	
openCowWindow:
	jmp AButtonMainScreenDone
	
ABtnScanPiecesLoopTail:
	inx
	cpx p1UnitCount
	bne ABtnScanPiecesLoop

	; if no unit occupies the space...

AButtonMainScreenNoUnit:
	lda cursorY ; ensures the build menu only opens on grass tiles
	asl a
	asl a
	asl a
	asl a
	clc
	adc cursorX
	tax
	lda MapData, x
	cmp #$02
	bne AButtonMainScreenDone

	lda #$02
	sta guiMode
	jsr openTextBox
	
AButtonMainScreenDone:
	rts