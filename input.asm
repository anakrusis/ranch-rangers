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
	
InputBGuimodeCheck:
	lda guiMode
	cmp #$03
	beq InputBUnitScreen
	cmp #$07
	beq InputBTurnChangeScreen
	cmp #$08
	beq InputBTurnChangeScreen
	
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
	
	; Turn change screen does nothing, you can't skip it
InputBTurnChangeScreen:
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
	lda turn
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

	; firstly checks if a unit of YOURS occupies the space

ABtnYourUnitCheck:
	lda turn
	cmp #$00
	beq ABtnLoadP1PiecesData
	jmp ABtnLoadP2PiecesData
	
	; loading pieces data: param1 and param2 store the pointer to the start of the pieces (X positions come first)
	
ABtnLoadP1PiecesData:
	lda #LOW(p1PiecesX)
	sta param1
	lda #HIGH(p1PiecesX)
	sta param2
	jmp ABtnScanPieces

ABtnLoadP2PiecesData:
	lda #LOW(p2PiecesX)
	sta param1
	lda #HIGH(p2PiecesX)
	sta param2
	jmp ABtnScanPieces
	
ABtnScanPieces:

	ldy #$00
ABtnScanPiecesLoop:
	lda [param1], y
	sty teste
	cmp cursorX
	bne ABtnScanPiecesLoopTail
	
	tya ; adding 8 on to iterator to check Y values (offset of 8 bytes)
	clc
	adc #$08
	tay
	
	lda [param1], y
	cmp cursorY
	bne subtractBeforeTail
	
AButtonMainScreenHasUnit:

	tya ; adding 8 more on to iterator to check piece types (offset of 16 bytes)
	clc
	adc #$08
	tay

	lda [param1], y
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
	lda #$05
	sta guiMode
	jsr openTextBox
	jmp AButtonMainScreenDone
	
openCowWindow:
	jmp AButtonMainScreenDone
	
subtractBeforeTail:
	tya ; subtracting the old 8 on from before so that we have the original iterator value
	sec
	sbc #$08
	tay

ABtnScanPiecesLoopTail:
	iny
	
	lda turn
	cmp #$00
	beq compareP1Units
	jmp compareP2Units

compareP1Units:
	cpy p1UnitCount
	bne ABtnScanPiecesLoop
	jmp ABtnAnyUnitCheck

compareP2Units:
	cpy p2UnitCount
	bne ABtnScanPiecesLoop
	
	
	; Now checking for any unit! If it's not yours, it must be someone else's. In that case,
	; you cannot alter the tile where the other player's unit stands. that would be very bad. Skip to the end.
ABtnAnyUnitCheck:
	
	; PLAYER 1 units get checked again...
	ldy #$00
ABtnScanP1PiecesLoop:
	lda p1PiecesX, y
	cmp cursorX
	bne ABtnScanP1PiecesLoopTail
	lda p1PiecesY, y
	cmp cursorY
	bne ABtnScanP1PiecesLoopTail	
	jmp AButtonMainScreenDone
ABtnScanP1PiecesLoopTail:
	iny
	cpy p1UnitCount
	bne ABtnScanP1PiecesLoop
	
	; PLAYER 2 units get checked also again...
	ldy #$00
ABtnScanP2PiecesLoop:
	lda p2PiecesX, y
	cmp cursorX
	bne ABtnScanP2PiecesLoopTail
	lda p2PiecesY, y
	cmp cursorY
	bne ABtnScanP2PiecesLoopTail
	jmp AButtonMainScreenDone
ABtnScanP2PiecesLoopTail:
	iny
	cpy p2UnitCount
	bne ABtnScanP2PiecesLoop

	; if no unit occupies the space, we can treat it like a normal tile which you can place farms or spawn units on...

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