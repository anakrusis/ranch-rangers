; X and Y pos: param4 and param5
; unit type: param6
; allegiance: param7 $00 = player 1, $01 = player 2
placeUnit:

	lda param7
	cmp #$00
	beq p1UnitLoad
	jmp p2UnitLoad

p1UnitLoad:

	ldx p1UnitCount
	
	lda param4
	sta p1PiecesX, x
	
	lda param5
	sta p1PiecesY, x
	
	lda param6
	sta p1PiecesType, x
	
	inc p1UnitCount

	lda param6
	clc
	adc #$04
	jmp UnitLoaded
p2UnitLoad:

	ldx p2UnitCount
	
	lda param4
	sta p2PiecesX, x
	
	lda param5
	sta p2PiecesY, x
	
	lda param6
	sta p2PiecesType, x
	
	inc p2UnitCount

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
	ldx #$00
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
	sta param6      ; at the site of the old unit place
	sta param7
	jsr drawMapChunk
	
	lda cursorX     ; ditto now at the site of the new unit place
	sta param4
	lda cursorY
	clc
	adc #MAP_DRAW_Y
	sta param5
	jsr drawMapChunk
	
	jsr endTurn
	jmp moveUnitDone
	
moveUnitInvalidInput:
	lda #$02
	ldx #$00
	jsr FamiToneSfxPlay
	
moveUnitDone:
	rts
	
; no params, takes in unitSelected and makes an array of moves that are possible
calculateValidUnitMoves:
	lda unitSelectedX
	sec
	sbc #$20
	tax
	sta param9 ; param9 contains an index two rows above

	lda #$00
	sta validMovesCount
	
mapValidCalcLoop:

	; valid moves can only be on grass tile, firstly!
mapCheckTerrainValue:
	lda MapData, x
	cmp #$02
	beq mapCheckUnit
	jmp mapValidCalcLoopTail
	
mapCheckUnit:
	txa
	and #$0f
	sta param1 ; x value is index % 16
	txa
	lsr a      ; y value is floor(index/16)
	lsr a
	lsr a
	lsr a
	sta param2
	jsr checkUnitOnTile
	
	; is there a unit on this tile?
	lda param3
	cmp #$ff
	bne mapValidCalcLoopTail
	
	lda unitSelectedX
	sta param3
	lda unitSelectedY
	sta param4
	jsr chebyshevDistance
	
	;is the distance from the unit to this tile 1? (todo unique stuff based on unit based stuff)
	lda param5
	cmp #$01
	bne mapValidCalcLoopTail
	
	; if so, place a new move into the valid moves list at the proper index
	ldy validMovesCount
	lda param1
	sta validMovesX, y
	lda param2
	sta validMovesY, y
	
	inc validMovesCount
	
mapValidCalcLoopTail:
	inx
	cpx #$b0
	bne mapValidCalcLoop
	
	rts
	
; param1/2 X and Y position of tile to check
; output:
; unit index in param3, allegiance in param4, type in param5
; index of FF means no unit found
checkUnitOnTile:
		
	; PLAYER 1 units get checked...
	ldy #$00
ScanP1PiecesLoop:
	lda p1PiecesX, y
	cmp param1
	bne ScanP1PiecesLoopTail
	lda p1PiecesY, y
	cmp param2
	bne ScanP1PiecesLoopTail	
	jmp P1UnitFound
ScanP1PiecesLoopTail:
	iny
	cpy p1UnitCount
	bne ScanP1PiecesLoop
	
	; PLAYER 2 units get checked...
	ldy #$00
ScanP2PiecesLoop:
	lda p2PiecesX, y
	cmp param1
	bne ScanP2PiecesLoopTail
	lda p2PiecesY, y
	cmp param2
	bne ScanP2PiecesLoopTail
	jmp P2UnitFound
ScanP2PiecesLoopTail:
	iny
	cpy p2UnitCount
	bne ScanP2PiecesLoop
		
NoUnitFound:
	lda #$ff
	sta param3
	rts
	
P1UnitFound:
	sty param3
	lda #$00
	sta param4
	lda p1PiecesType, y
	sta param5
	rts

P2UnitFound:
	sty param3
	lda #$01
	sta param4
	lda p2PiecesType, y
	sta param5
	rts
	
; param1 param2: x1, y1
; param3 param4: x2, y2
; output in param5
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
