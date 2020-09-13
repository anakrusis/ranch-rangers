AiUpdate:
	lda computerMustMakeMove
	cmp #$01
	beq AiUpdateBegin
	jmp AiDone
	
AiUpdateBegin:
; The first priority is ensuring that the farmer is not threatened.
; We iterate through all of player 1's units and find the nearest.

; param10 temporarily stores the nearest distance.

CheckFarmerSafety:
FindEnemyUnitNearestToFarmer:
	lda #$00
	sta AINearestEnemyUnitToFarmer
	
	lda #$FF
	sta <param10
	
	ldx #$00
FindNearestEnemyUnitLoop:
	; param1+2 unit to be checked x/y
	; param9   its type to be used later on if needed
	lda p1PiecesX, x
	sta <param1
	lda p1PiecesY, x
	sta <param2
	lda p1PiecesType, x
	sta <param9
	
	; param3+4 farmer x/y (always first in the units list)
	lda p2PiecesX+0
	sta <param3
	lda p2PiecesY+0
	sta <param4
	
	jsr chebyshevDistance
	cmp <param10
	bcs FindNearestEnemyUnitLoopTail
	
	sta <param10
	stx AINearestEnemyUnitToFarmer ; stores the index to be accessed later
	
FindNearestEnemyUnitLoopTail:
	inx
	cpx p1UnitCount
	bne FindNearestEnemyUnitLoop
	
	; if the nearest distance found is less than 3 then get farmer to safety!
	lda <param10
	cmp #$03
	bcs CheckFarmerSafetyDone
	
	jmp farmerAttemptMoveToSafety
CheckFarmerSafetyDone:

; If the farmer is safe or otherwise cannot do anything to protect themselves then
; The next thing to check is if there's enough money to get units to do something! If there's less than 2 gold
; then the AI must place down a farm!

CheckMoney:
	lda p2Gold
	cmp #$02
	bcs CheckEnemyUnitCount
	
	jmp PlaceFarmAtRightmostTile
	
CheckEnemyUnitCount:
	jsr compareEnemyFriendlyUnitsInTerritory
	cmp #$00
	beq CheckEnemyUnitCountDone
	jmp PlaceNewUnitThreateningly
	
CheckEnemyUnitCountDone:
	jmp EndTurnAiDone

AiDone:
	lda #$00
	sta computerMustMakeMove
	rts
	
EndTurnAiDone:
	jsr endTurn
	lda #$00
	sta computerMustMakeMove
	rts
	
; param10+11 will now contain a tile x/y of an enemy unit that is threatening the farmer
; param9 contains its Type, which will be used later for making avoidance-pattern moves
; (avoiding straight lines for cows and diagonals for chickens)
farmerAttemptMoveToSafety:
	; calculateUnitMoves clobbers much of the lower params so thats why it moveses up here
	lda <param1
	sta <param10
	lda <param2
	sta <param11

	lda #$00
	sta attackMode
	
	ldy #$00
	sty unitSelected
	
	lda p2PiecesX, y
	sta unitSelectedX
	
	lda p2PiecesY, y
	sta unitSelectedY
	
	lda p2PiecesType, y
	sta unitSelectedType
	
	jsr calculateUnitMoves
	
	; if the farmer is trapped then go on to the next move in the queue
	lda validMovesCount
	cmp #$00
	bne farmerMoveToSafety
	jmp CheckFarmerSafetyDone

; Iterates through all the possible moves and finds the one furthest away from the threatening unit.
; this isn't the best way to do this, but it will work for now while getting the rest of the AI priorities sorted out.

; param10 and param11 still contain the marauding enemy unit position to avoid	
; param9 still unit type will be utilized later
; param8 temp max distance
; param7 temp index for move to select
farmerMoveToSafety:
	lda #$00
	sta <param8

	; (now back to param1+2 for a second set of chebyshevs)
	lda <param10
	sta <param1
	lda <param11
	sta <param2
	
	; if somehow you got here with zero valid moves (this shouldn't be possible) then fugedaboutit. dont worry about farmer for now. better to do nothing than to softlock lol
	ldx #$00
	cpx validMovesCount
	bne farmerCheckMovesLoop
	jmp CheckFarmerSafetyDone
	
farmerCheckMovesLoop:
	lda validMovesX, x
	sta <param3
	lda validMovesY, x
	sta <param4
	
	jsr chebyshevDistance
	
	; if it doesnt exceed the current max then skip it.
	cmp <param8
	bcc farmerCheckMovesLoopTail
	
	; otherwise set it.
	sta <param8
	stx <param7 ; move index
	
farmerCheckMovesLoopTail:
	inx
	cpx validMovesCount
	bne farmerCheckMovesLoop
	
farmerMoveFurthestAvailable:
	ldx <param7
	lda validMovesX, x
	sta cursorX
	lda validMovesY, x
	sta cursorY
	jsr moveSelectedUnitToCursorPos
	
	jmp AiDone
	
; output in A 
; 00 = more friends than enemies
; 01 = more enemies or equal
compareEnemyFriendlyUnitsInTerritory
	lda #$00
	sta <param10 ; p1 unit count in terr
	sta <param11 ; p2 unit count in terr
	
	lda <MapWidth ; map width divided by 2
	lsr a
	sta <param9 ; center of the map, mapwidth/2
	
	ldx #$00
compareEnemyLoop:
	lda p1PiecesX, x
	cmp <param9
 ; if piece position is less than mapwidth/2 (left of center) then ignore
	bcc compareEnemyLoopTail
 ; if piece is right of center then it's in the AI's territory
	inc <param10
	
compareEnemyLoopTail:
	inx
	cpx p1UnitCount
	bne compareEnemyLoop
	
; same deal but with p2's units
	ldx #$00
compareFriendlyLoop:
	lda p2PiecesX, x
	cmp <param9
	bcc compareFriendlyLoopTail
	
	inc <param11
	
compareFriendlyLoopTail:	
	inx
	cpx p2UnitCount
	bne compareFriendlyLoop
	
compareEnemyFriendlyCount:
	lda <param10
	cmp <param11
	bcs MoreOrEqualEnemies ; enemyCount >= friendlyCount
	
	lda #$00
	rts
	
MoreOrEqualEnemies:
	lda #$01
	rts
	
; param4/5 will store the X and Y position to place this unit
; param6 will be the type
; these are aligned with the buyUnit subroutine which is the core of this code
PlaceNewUnitThreateningly:

; the new unit will be placed next to whichever unit is closest to the farmer.
; the index to that unit is still stored in a variable in ram
FindTileToThreatenAMaraudingUnit:
	ldx AINearestEnemyUnitToFarmer
	lda p1PiecesType, x
	sta NearestUnitToFarmerType
	
	cmp #$01
	beq EnemyHasChicken
	cmp #$02
	beq EnemyHasCow
	jmp CheckEnemyUnitCountDone

; param12+13 stores a pointer into the Threat table wherein:
; enemy with a chicken will provide a list of positions to place a cow
; enemy with a cow will provide a list of positions to place a chicken
EnemyHasChicken:
	lda #LOW(CowThreatX)
	sta <param12
	lda #HIGH(CowThreatX)
	sta <param13
	
	jmp ThreatenPositionLoop
	
EnemyHasCow:
	lda #LOW(ChickenThreatX)
	sta <param12
	lda #HIGH(ChickenThreatX)
	sta <param13


; these are all the relative positions where an enemy could threaten the enemy of a different type
	ldy #$00
ThreatenPositionLoop:
	; x position loaded
	lda [param12], y
	sta <param1
	
	; y position at an offset of 8 bytes after
	tya
	clc
	adc #$08
	tay
	
	lda [param12], y
	sta <param2
	
	; because it's relative, to get an absolute position we must add the pos of the enemy unit
	ldx AINearestEnemyUnitToFarmer
	lda <param1
	clc
	adc p1PiecesX, x
	sta <param1
	lda <param2
	clc
	adc p1PiecesY, x
	sta <param2
	
	jsr checkUnitOnTile
	
 ; looking for the first space without a unit occupying it
	
	lda <param3
	cmp #$ff
	bne ThreatenPositionLoopTail
	
; if no unit, transfer the x/y fed into checkUnitOnTile (param1/2) to x/y to feed into buyUnit (param4/5)
	lda <param1
	sta <param4
	lda <param2
	sta <param5
; Unit to spawn type: if enemy cow then chicken otherwise cow is preferred
	lda NearestUnitToFarmerType
	cmp #$02
	beq ThreatenPositionSpawnChicken
	jmp ThreatenPositionSpawnCow

ThreatenPositionSpawnChicken:
	lda #$01
	sta <param6
	jmp PlaceUnitAtTheSpot
	
ThreatenPositionSpawnCow:
	lda #$02
	sta <param6
	jmp PlaceUnitAtTheSpot

ThreatenPositionLoopTail:
	iny
	cpy #$08
	bne ThreatenPositionLoop
	
	jmp PlaceUnitAtTheSpot

PlaceUnitAtTheSpot:	
	; allegiance 01 = player 2 (AI)
	lda #$01
	sta <param7
	jsr buyUnit
	
	jmp AiDone
	
PlaceFarmAtRightmostTile:
	ldx MapWidth
	dex
	sta <param14 ; temporarily stores the starting point of the column
FindRightmostTileLoop:

	lda MapData, x
	cmp #$02
	bne FindRightmostTileLoopTail

	jmp RightmostTileFound

FindRightmostTileLoopTail:	
	txa
	clc
	adc MapWidth
	tax
	cmp #$c0
	bcc FindRightmostTileLoop
	
	ldx <param14
	dex
	stx <param14
	
	lda MapWidth
	lsr a
	sta <param15 ; param15 = mapwidth/2
	
	lda <param14 ; if columnStart >= mapwidth/2 then continue looping
	cmp <param15
	bcs FindRightmostTileLoop
	
	jmp AiDone
	
RightmostTileFound:
	txa
	and #$0f
	sta cursorX
	txa
	lsr a
	lsr a
	lsr a
	lsr a
	sta cursorY
	jsr placeFarmAtCursorPos
	jmp AiDone
	
; tile offsets where a unit can be threatened by a chicken
ChickenThreatX:
	.db $01, $01, $ff, $ff, $02, $02, $fe, $fe
ChickenThreatY:
	.db $01, $ff, $01, $ff, $02, $fe, $02, $fe
	
CowThreatX:
	.db $fe, $ff, $01, $02, $00, $00, $00, $00
CowThreatY:
	.db $00, $00, $00, $00, $fe, $ff, $01, $02
