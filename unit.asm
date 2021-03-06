; X and Y pos: param4 and param5
; unit type: param6
; allegiance: param7 $00 = player 1, $01 = player 2
placeUnit:

	lda param7
	cmp #$00
	beq p1UnitLoad
	jmp p2UnitLoad

p1UnitLoad:

	ldx <p1UnitCount
	
	lda param4
	sta p1PiecesX, x
	
	lda param5
	sta p1PiecesY, x
	
	lda param6
	sta p1PiecesType, x
	
	inc <p1UnitCount

	lda param6
	clc
	adc #$04
	jmp UnitLoaded
p2UnitLoad:

	ldx <p2UnitCount
	
	lda param4
	sta p2PiecesX, x
	
	lda param5
	sta p2PiecesY, x
	
	lda param6
	sta p2PiecesType, x
	
	inc <p2UnitCount

	lda param6
	clc 
	adc #$11
	
UnitLoaded:
	sta param1
	
	lda param4 ; transfer x and y coordinates
	sta param2
	lda param5
	clc
	adc #MAP_DRAW_Y
	sta param3
	
	jsr placeTileInBuffer

	rts
	
; same as above with params but checks if you have sufficient funds and does the proper sfx
buyUnit:
	ldy param7 ; unit allegiance
	lda p1Gold, y
	
	ldx param6 ; unit type
	cmp UnitPrices, x
	bcs buyUnitSuccess
	
	lda #$02
	ldx #$00
	jsr FamiToneSfxPlay
	
	rts
	
buyUnitSuccess:
	; todo animation with sprite? idk
	jsr placeUnit
	
	ldy param7
	lda p1Gold, y
	sec
	sbc UnitPrices, x
	sta p1Gold, y
	
	jsr closeCurrentTextBox
	lda #$02
	sta guiMode
	jsr openTextBox
	jsr closeCurrentTextBox
	jsr endTurn
	
	rts
	
; no params, just uses cursorpos and unitSelected
; clobbers y
moveSelectedUnitToCursorPos:
moveUnitCheckGrass:
	lda cursorY ; this code is redundant lol
	asl a       ; it makes sure units can only move on grass, but that's already decided by the validMoves arrays
	asl a       ; also removing it will make this stuff more flexible lol :3
	asl a
	asl a
	clc
	adc cursorX
	tax
	lda MapData, x
	cmp #$02
	beq moveUnitCheckValidMoves
	jmp moveUnitInvalidInput

moveUnitCheckValidMoves:
	; zero moves means no input can be valid
	ldx #$00
	cpx validMovesCount
	bne moveUnitCheckValidMovesLoop
	jmp moveUnitInvalidInput
	
moveUnitCheckValidMovesLoop:

	lda validMovesX, x
	cmp cursorX
	bne moveUnitCheckValidMovesLoopTail
	
	lda validMovesY, x
	cmp cursorY
	bne moveUnitCheckValidMovesLoopTail
	
	jmp ValidMoveFound

moveUnitCheckValidMovesLoopTail:
	inx
	cpx validMovesCount
	bne moveUnitCheckValidMovesLoop
	
ValidMoveNotFound:
	jmp moveUnitInvalidInput
	
ValidMoveFound:

	; for attack moves, only removing a unit if there is one currently on the space.
	; this cannot happen with regular movement moves.
	lda cursorX
	sta param1
	lda cursorY
	sta param2
	jsr removeUnitIfPresent
	; removeUnitIfPresent returns a 0 if there is no unit which means it would be movement not attack
	cmp #$00
	beq MoveUnitCheckAllegiance
	
	; if there is a unit there, then it must be an attack!
	; a unit that has a seperate attack/movement move would not want to move when attacking!
	ldy unitSelectedType
	lda UnitHasCombinedAttackMove, y
	cmp #$00
	bne MoveUnitCheckAllegiance
	
	jsr initChickenAtkAnim
	jmp moveUnitDone

MoveUnitCheckAllegiance:
	ldy unitSelected
	lda turn
	cmp #$00
	beq MoveP1Unit
	jmp MoveP2Unit
	
MoveP1Unit:
	lda p1PiecesX, y ; old unit position before moving, already in place for drawMapChunk
	sta param4
	lda p1PiecesY, y
	clc
	adc #MAP_DRAW_Y
	sta param5

	lda cursorX     ; updating unit position
	sta p1PiecesX, y
	lda cursorY
	sta p1PiecesY, y
	
	jmp moveUnitDrawUpdate
	
MoveP2Unit:
	lda p2PiecesX, y ; old unit position before moving, already in place for drawMapChunk
	sta param4
	lda p2PiecesY, y
	clc
	adc #MAP_DRAW_Y
	sta param5

	lda cursorX
	sta p2PiecesX, y
	lda cursorY
	sta p2PiecesY, y
	
moveUnitDrawUpdate:
	lda #$01        ; drawing box with width and height 1 (single tile update)
	sta <param6      ; at the site of the old unit place
	sta <param7
	sta showAnimSpriteFlag ; this enables the sprite animation for units moving
	
	jsr drawMapChunk
	
	; now the sprite update setting its initial position to the old position set in param4/5
	lda param4
	asl a
	asl a
	asl a
	asl a
	sta moveAnimX
	lda param5
	asl a
	asl a
	asl a
	asl a
	sta moveAnimY
	
	jmp moveUnitDone
	
moveUnitInvalidInput:
	lda #$02
	ldx #$00
	jsr FamiToneSfxPlay
	rts
	
moveUnitDone:
	jsr endTurn
	rts
	
; no params, takes in unitSelected and makes an array of moves that are possible
; param 6 and 7 used internally for the endpoints of each loop x and y
calculateUnitMoves:
	lda #$00
	sta validMovesCount

calcRange:
	lda unitSelectedType
	asl a
	sta <param8

	lda attackMode ; attack is 01, move is 00
	cmp #$00
	beq calcMovesMoveMode
	jmp calcMovesAttackMode
	
calcMovesMoveMode:
	clc
	adc param8
	tay
	
	lda UnitRanges, y ; param8 has the "radius" of sorts 
	sta param8
	; these are the endpoints which will be used to compare the loop
	lda unitSelectedX ; x endpoint set
	clc
	adc param8
	sta param6
	
	lda unitSelectedY ; y endpoint set
	clc
	adc param8
	sta param7
	
	inc param6 ; the reason for this is by nature of the loops, stopping when they equal these values!
	inc param7
	
	; these are the startpoints used to begin the loop
	lda unitSelectedY
	sec
	sbc param8
	tay
calcMovesYLoop:

	sty <param2

	; ditto
	lda <unitSelectedX
	sec
	sbc <param8
	tax
calcMovesXLoop:
	
	stx param1
	
	tya
	pha
	
calcMovesCheckUnit:
	; param1 and param2 already setup!
	jsr checkUnitOnTile
	jsr mapDecideUnitMoveValid
	cmp #$00
	beq calcMovesXLoopTail
	
	; if so, place a new move into the valid moves list at the proper index
	ldy validMovesCount
	lda <param1
	sta validMovesX, y
	lda <param2
	sta validMovesY, y
	
	inc validMovesCount	

calcMovesXLoopTail:
	pla
	tay

	inx
	cpx <param6
	bne calcMovesXLoop

calcMovesYLoopTail:
	iny
	cpy <param7
	bne calcMovesYLoop

calcMovesDone:
	rts
	
; attack mode functions differently from the other modes, it uses fixed (relative) tables to determine the attack pattern of each mob
calcMovesAttackMode:
	ldx #$00
calcMovesAttackModeLoop:
	ldy unitSelectedType
	
	; 11/12 store the beginning byte into UnitThreats, the spaces where a unit can threaten
	lda UnitThreatOffsetsX, y
	sta <param11
	lda UnitThreatOffsetsY, y
	sta <param12
	
	; get the relative X value
	txa
	clc
	adc <param11
	tay
	lda UnitThreats, y
	; add on the units X
	clc
	adc <unitSelectedX
	sta <param1
	
	; get the relative Y value
	txa
	clc
	adc <param12
	tay
	lda UnitThreats, y
	; add on the units Y
	clc
	adc <unitSelectedY
	sta <param2
	
	; param1 and param2 already setup!
	jsr checkUnitOnTile
	jsr mapDecideUnitMoveValid
	cmp #$00
	beq calcMovesAttackModeLoopTail

	ldy validMovesCount
	lda <param1
	sta validMovesX, y
	lda <param2
	sta validMovesY, y
	
	inc validMovesCount	
	
calcMovesAttackModeLoopTail:
	inx
	cpx #$08
	bne calcMovesAttackModeLoop
	
	rts
	
; input: whatever checkUnitOnTile outputs, and guiMode which is set before
; output: validity of move in A
mapDecideUnitMoveValid:
mapDecideCheckTerrain:
	lda <param2
	asl a       
	asl a      
	asl a
	asl a
	clc
	adc <param1
	tay
	lda MapData, y
	cmp #$02
	beq mapDecideModeEval
	jmp MoveInvalid

mapDecideModeEval:
	; attack mode?
	lda attackMode
	cmp #$01
	beq AtkModeEval
	jmp MovModeEval
	
AtkModeEval:
	; is there a unit on this tile?
	lda param3
	cmp #$ff
	beq AtkModeNoUnit
	
	; is it friendly or enemy?
	lda param4
	cmp turn
	beq MoveInvalid
	jmp MoveValid
	
AtkModeNoUnit:
	; no unit? if so, then does the unit have a combined move-attack?
	ldy unitSelectedType
	lda UnitHasCombinedAttackMove, y
	cmp #$01
	beq MoveValid
	jmp MoveInvalid
	
MoveValid:
	lda #$01
	rts
	
MoveInvalid:
	lda #$00
	rts
	
MovModeEval:
	; is there a unit on this tile?
	lda param3
	cmp #$ff
	beq MoveValid
	jmp MoveInvalid
	
; param1/2 X and Y position of tile to check
; output:
; unit index in param3, allegiance in param4, type in param5
; index of FF means no unit found
checkUnitOnTile:
		
	; PLAYER 1 units get checked...
	ldy #$00
	cpy <p1UnitCount
	beq scanp2
	
ScanP1PiecesLoop:
	lda p1PiecesX, y
	cmp <param1
	bne ScanP1PiecesLoopTail
	lda p1PiecesY, y
	cmp <param2
	bne ScanP1PiecesLoopTail	
	jmp P1UnitFound
ScanP1PiecesLoopTail:
	iny
	cpy <p1UnitCount
	bne ScanP1PiecesLoop
	
scanp2:
	; PLAYER 2 units get checked...
	ldy #$00
	cpy <p2UnitCount
	beq NoUnitFound
	
ScanP2PiecesLoop:
	lda p2PiecesX, y
	cmp <param1
	bne ScanP2PiecesLoopTail
	lda p2PiecesY, y
	cmp <param2
	bne ScanP2PiecesLoopTail
	jmp P2UnitFound
ScanP2PiecesLoopTail:
	iny
	cpy <p2UnitCount
	bne ScanP2PiecesLoop
		
NoUnitFound:
	lda #$ff
	sta <param3
	rts
	
P1UnitFound:
	sty <param3
	lda #$00
	sta <param4
	lda p1PiecesType, y
	sta <param5
	rts

P2UnitFound:
	sty <param3
	lda #$01
	sta <param4
	lda p2PiecesType, y
	sta <param5
	rts
	
; param1 param2: x1, y1
; param3 param4: x2, y2
; output in param5 (and A)
chebyshevDistance:
subtractX1X2:
	lda param3
	sec
	sbc param1
	
	; a value above $80 is negative, we presume, so we want to turn it positive by flipping the bits and adding 1
	cmp #$80
	bcc subtractX1X2Done
	
	eor #$ff
	clc
	adc #$01
	
subtractX1X2Done:
	sta param6
	
subtractY1Y2:
	lda param4
	sec
	sbc param2
	
	; same thing as above
	cmp #$80
	bcc subtractY1Y2Done
	
	eor #$ff
	clc
	adc #$01
	
subtractY1Y2Done:	
	sta param7

compareXDistYDist:
	; if param7(Y) is less than param6(X), then
	cmp param6
	bcc chebyshevReturnX
	
chebyshevReturnY:
	lda param7
	sta param5
	sta teste
	rts

chebyshevReturnX:
	lda param6
	sta param5
	sta teste
	rts

; index param3 
; allegiance param4 thats it
removeUnit:
	ldy param3
	
	lda param4
	cmp #$00
	beq removeP1Unit
	jmp removeP2Unit
removeP1Unit:

	lda p1PiecesX, y ; preparing for drawMapChunk after unit is removed
	sta param4
	lda p1PiecesY, y
	clc
	adc #MAP_DRAW_Y
	sta param5
	lda #$01
	sta param6
	sta param7

	
removeP1UnitLoop:
	iny           ; starting with the unit one above
	cpy #$08
	beq removeP1UnitDone ; if already at the top index, then no shifting needed (the result would be very bad) so just decrement the unit count
	
	lda p1PiecesX, y
	dey
	sta p1PiecesX, y ; write x to the unit below
	iny
	
	lda p1PiecesY, y
	dey
	sta p1PiecesY, y ; write y to the unit below
	iny
	
	lda p1PiecesType, y
	dey
	sta p1PiecesType, y ; write type to the unit below
	iny
	
	cpy <p1UnitCount
	bne removeP1UnitLoop

removeP1UnitDone:
	dec <p1UnitCount

	; In attack mode, units are not drawn as being removed until the turn is over to allow for attack animation
	lda attackMode
	cmp #$01
	beq removeP1UnitDoneNoDraw
	jsr drawMapChunk
	
removeP1UnitDoneNoDraw:
	rts
	
removeP2Unit:

	lda p2PiecesX, y ; preparing for drawMapChunk after unit is removed
	sta param4
	lda p2PiecesY, y
	clc
	adc #MAP_DRAW_Y
	sta param5
	lda #$01
	sta param6
	sta param7
	
removeP2UnitLoop:
	iny           ; starting with the unit one above
	cpy #$08
	beq removeP2UnitDone ; if already at the top index, then no shifting needed (the result would be very bad) so just decrement the unit count
	
	lda p2PiecesX, y
	dey
	sta p2PiecesX, y ; write x to the unit below
	iny
	
	lda p2PiecesY, y
	dey
	sta p2PiecesY, y ; write y to the unit below
	iny
	
	lda p2PiecesType, y
	dey
	sta p2PiecesType, y ; write type to the unit below
	iny
	
	cpy <p2UnitCount
	bne removeP2UnitLoop

removeP2UnitDone:
	dec <p2UnitCount
	
	lda attackMode
	cmp #$01
	beq removeP2UnitDoneNoDraw
	jsr drawMapChunk
	
removeP2UnitDoneNoDraw:	
	rts
	
; only used when voluntarily deleting a unit, not when in battle.
removeUnitAnimationSfxInit:

	;animation init here
	lda unitSelectedX
	asl a
	asl a
	asl a
	asl a
	sta unitHeavenXpos
	lda unitSelectedY
	clc
	adc #MAP_DRAW_Y
	asl a
	asl a
	asl a
	asl a
	sta unitHeavenTimer
	
	lda unitSelectedType
	sta unitHeavenType

	lda #$05
	ldx #$00
	jsr FamiToneSfxPlay
	
	jsr updateHotbar
	
	rts

; param1/2 X/Y
; returns 1 in A if unit is present and 0 if no unit is present
removeUnitIfPresent:
	jsr checkUnitOnTile
	lda param3
	cmp #$ff
	beq noUnitPresent

	; param3 and param4 are already set from checkUnitOnTile
	jsr removeUnit
	lda #$01
	rts
	
noUnitPresent:
	lda #$00
	rts
	