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
	cmp #$01
	beq InputBDoNothing ; does nothing
	cmp #$03
	beq InputBUnitScreen
	cmp #$07
	beq InputBDoNothing
	cmp #$08
	beq InputBDoNothing
	cmp #$0c
	beq InputBDoNothing
	cmp #$10
	beq InputBDoNothing
	cmp #$11
	beq InputBDoNothing
	
	; If unsure what to do then just go back to the main guimode, that's B button default behavior
	lda #$01
	sta guiMode
	jsr closeCurrentTextBox
	
	lda #$01
	ldx #$00
	jsr FamiToneSfxPlay
	
	jmp InputBDone

	; Unit screen leads back to build screen
InputBUnitScreen:
	lda #$02
	sta guiMode
	jsr closeCurrentTextBox
	jsr openTextBox
	jmp InputBDone
	
	; does nothing, screens you can't skip
InputBDoNothing:
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
	cmp #$04
	beq InputAFarmerScreen
	cmp #$05
	beq InputAChickenScreen
	cmp #$06
	beq InputACowScreen
	cmp #$09
	beq InputAMoveScreen
	cmp #$0a
	beq InputAAttackScreen
	cmp #$10
	beq InputADebugMenuScreen
	
	jmp InputADone
	
InputAMainScreen:
	jsr AButtonMainScreenHandler
	jmp InputADone
	
InputAPauseScreen:
	jmp InputADone
	
InputAMoveScreen:
	jsr moveSelectedUnitToCursorPos
	jmp InputADone

InputAAttackScreen:
	jsr moveSelectedUnitToCursorPos
	jmp InputADone
	
InputABuildScreen:
	jsr AButtonBuildScreenHandler
	jmp InputADone
	
InputADebugMenuScreen:
	lda menuCursorPos
	cmp #$00
	beq startgameDebug
	jmp startgameNormal

startgameDebug:
	lda #$80
	sta gameMode
	jsr initGameState
	jmp InputADone
	
startgameNormal:
	jsr initGameState
	jmp InputADone
	
InputAUnitScreen:
	jsr AButtonUnitScreenHandler
	jmp InputADone
	
InputACowScreen:
	jsr AButtonCowScreenHandler
	jmp InputADone
	
InputAFarmerScreen:
MoveFarmer:
	lda #$00
	sta attackMode
	lda #$09
	sta guiMode
	jsr calculateUnitMoves
	jsr closeCurrentTextBox
	jmp InputADone
	
InputAChickenScreen:
	lda menuCursorPos
	cmp #$00
	beq MoveChicken
	cmp #$01
	beq AttackChicken
	cmp #$02
	beq DeleteChicken
	jmp InputADone

MoveChicken:
	lda #$00
	sta attackMode
	lda #$09
	sta guiMode
	jsr calculateUnitMoves
	jsr closeCurrentTextBox	
	jmp InputADone
	
AttackChicken:
	lda #$01
	sta attackMode
	lda #$0a
	sta guiMode
	jsr calculateUnitMoves
	jsr closeCurrentTextBox
	jmp InputADone

DeleteChicken:
	lda <unitSelected
	sta <param3
	lda <turn
	sta <param4
	jsr removeUnit
	jsr removeUnitAnimationSfxInit
	
	lda #$01
	sta guiMode
	jsr closeCurrentTextBox
	jmp InputADone
	
InputADone:
DpadCheckGuimode:
	lda guiMode
	cmp #$01
	beq DpadMainScreen
	cmp #$09
	beq DpadMainScreen
	cmp #$0a
	beq DpadMainScreen
	jmp DpadMenuScreen
	
DpadMainScreen:
	lda buttons1
	and #$0f
	cmp #$00
	bne DpadHandleTimer
	jmp InputHandlerDone

DpadHandleTimer:
	dec dpadInputTimer
	
	lda prevButtons1
	and #$0f
	cmp #$00
	beq DpadResetTimer
	jmp DpadHandleInputs
	
DpadResetTimer:
	lda #$00
	sta dpadInputTimer

DpadHandleInputs:
	lda dpadInputTimer
	and #$07
	cmp #$00
	beq MainScrnInputRight
	jmp InputHandlerDone
	
MainScrnInputRight:
	lda buttons1
	and #$01
	cmp #$01
	bne MainScrnInputRightDone
	
	inc cursorX
	lda cursorX
	and #$0f       ; cursor position modulo 16, cannot exceed 15
	sta cursorX
	
MainScrnInputRightDone:
MainScrnInputLeft:
	lda buttons1
	and #$02
	cmp #$02
	bne MainScrnInputLeftDone
	
	dec cursorX
	lda cursorX
	and #$0f     ; cursor position modulo 16, cannot exceed 15
	sta cursorX
MainScrnInputLeftDone:
MainScrnInputDown:
	lda buttons1
	and #$04
	cmp #$04
	bne MainScrnInputDownDone
	
	inc cursorY
	lda cursorY
	cmp #$0c               
	bcc MainScrnInputDownDone  ; if greater than or equal to 0c (went too low) then replace with 00
	lda #$00
	sta cursorY
	
MainScrnInputDownDone:
MainScrnInputUp:
	lda buttons1
	and #$08
	cmp #$08
	bne MainScrnInputUpDone

	dec cursorY
	lda cursorY
	cmp #$0c        ; if greater than or equal to 0c (too high, underflowed to FF presumably) then replace with 0b
	bcc MainScrnInputUpDone
	lda #$0b
	sta cursorY
MainScrnInputUpDone:

	jmp InputHandlerDone
	
DpadMenuScreen:
MenuScrnInputUp:
	lda buttons1
	and #$08
	cmp #$08
	bne MenuScrnInputUpDone
	
	lda prevButtons1
	and #$08
	cmp #$08
	beq MenuScrnInputUpDone
	
	dec menuCursorPos ; cursor pos--; if its greater than or equal to the amt of items then set it to menuSize-1 
	lda menuCursorPos
	cmp menuSize
	bcc MenuScrnInputUpDone
	lda menuSize
	sec
	sbc #$01
	sta menuCursorPos
	
	jmp MenuScrnInputUpDone
	
MenuScrnInputUpDone:
MenuScrnInputDown:
	lda buttons1
	and #$04
	cmp #$04
	bne MenuScrnInputDownDone	

	lda prevButtons1
	and #$04
	cmp #$04
	beq MenuScrnInputDownDone

	inc menuCursorPos ; cursor pos++; if its greater than or equal to the amt of items then set it to 0 
	lda menuCursorPos
	cmp menuSize
	bcc MenuScrnInputDownDone
	lda #$00
	sta menuCursorPos
	
	jmp MenuScrnInputDownDone

MenuScrnInputDownDone:
	jmp InputHandlerDone

InputHandlerDone:
	rts
	
AButtonMainScreenHandler:

	lda <cursorX
	sta <param1
	lda <cursorY
	sta <param2
	; is a unit present on the space?
	jsr checkUnitOnTile
	lda <param3
	cmp #$ff
	beq AButtonMainScreenNoUnit
	
	; is it friendly or enemy unit? Can't open up menu on enemy units.
	lda <param4
	cmp <turn
	bne AButtonMainScreenInvalidInput
	jmp AButtonMainScreenHasUnit
	
	; if no unit occupies the space, we can treat it like a normal tile which you can place farms or spawn units on...

AButtonMainScreenNoUnit:

	; first, you can only place tiles or units within your borders
	; (you can interact with units of yours outside your borders but you have to spawn them in your border)
	lda <cursorX
	lsr a
	lsr a
	lsr a
	cmp turn
	bne AButtonMainScreenInvalidInput

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
	bne AButtonMainScreenInvalidInput

	lda #$02
	sta guiMode
	jsr openTextBox
	
	lda #$00
	ldx #$00
	jsr FamiToneSfxPlay
	
	jmp AButtonMainScreenDone
	
AButtonMainScreenInvalidInput:
	lda #$02
	ldx #$00
	jsr FamiToneSfxPlay
	
AButtonMainScreenDone:
	rts
	
AButtonMainScreenHasUnit:
	
	; the param variables were set earlier from the subroutine checkUnitOnTile

	lda param3 ; what index is it
	sta unitSelected
	lda param5 ; what type is it
	sta unitSelectedType
	
	lda cursorX
	sta unitSelectedX 
	lda cursorY
	sta unitSelectedY
	
	lda unitSelectedType ; what type unit is it?
	cmp #$00
	beq openFarmerWindow
	cmp #$01
	beq openChickenWindow
	cmp #$02
	beq openCowWindow
	
	jmp AButtonMainScreenDone
	
openFarmerWindow:
	lda #$04
	sta guiMode
	jsr openTextBox
	
	lda #$00
	ldx #$00
	jsr FamiToneSfxPlay
	
	jmp AButtonMainScreenDone
	
openChickenWindow:
	lda #$05
	sta guiMode
	jsr openTextBox
	
	lda #$00
	ldx #$00
	jsr FamiToneSfxPlay
	
	jmp AButtonMainScreenDone
	
openCowWindow:
	lda #$06
	sta guiMode
	jsr openTextBox
	
	lda #$00
	ldx #$00
	jsr FamiToneSfxPlay	
	
	jmp AButtonMainScreenDone
	
	
	
AButtonUnitScreenHandler:
	lda menuCursorPos
	cmp #$00
	beq PlaceChicken
	cmp #$01
	beq PlaceCow
	jmp AButtonUnitScreenHandlerDone
	
PlaceChicken:
	lda cursorX
	sta param4
	lda cursorY
	sta param5
	lda #$01
	sta param6
	lda <turn
	sta param7
	jsr buyUnit
	
	jmp AButtonUnitScreenHandlerDone
	
PlaceCow:
	lda <cursorX
	sta <param4
	lda <cursorY
	sta <param5
	lda #$02
	sta <param6
	lda <turn
	sta <param7
	jsr buyUnit
	
	jmp AButtonUnitScreenHandlerDone	
	
AButtonUnitScreenHandlerDone:
	rts
	
AButtonBuildScreenHandler:
	lda menuCursorPos
	cmp #$01
	beq PlaceFarm
	cmp #$00
	beq UnitMenu
	
UnitMenu:
	lda #$03
	sta guiMode
	jsr openTextBox
	jmp AButtonBuildScreenHandlerDone
	
PlaceFarm:
	ldy <turn
	lda p1FarmCount, y
	clc
	adc #$01
	sta p1FarmCount, y
	
	; place new farm tile in map
	lda <cursorY 
	asl a
	asl a
	asl a
	asl a
	clc
	adc <cursorX
	tax
	lda #$03
	sta MapData, x 
	
	; render new farm tile
	lda <cursorX
	sta <param4
	lda <cursorY
	clc
	adc #MAP_DRAW_Y
	sta <param5
	lda #$01
	sta <param6
	sta <param7
	jsr drawMapChunk

	lda #$01
	sta <guiMode
	jsr closeCurrentTextBox
	jsr endTurn
	
	jmp AButtonBuildScreenHandlerDone
	
AButtonBuildScreenHandlerDone:
	rts
	
AButtonCowScreenHandler:
	lda menuCursorPos
	cmp #$00
	beq AttackCow
	jmp RemoveCow
	
AttackCow:
	lda #$01 
	sta attackMode
	lda #$0a
	sta guiMode
	jsr calculateUnitMoves
	jsr closeCurrentTextBox
	rts
	
RemoveCow:
	lda unitSelected
	sta param3
	lda turn
	sta param4
	jsr removeUnit
	jsr removeUnitAnimationSfxInit
	
	lda #$01
	sta guiMode
	jsr closeCurrentTextBox
	rts