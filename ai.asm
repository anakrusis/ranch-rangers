AiUpdate:
	lda computerMustMakeMove
	cmp #$01
	beq AiUpdateBegin
	jmp AiDone
	
AiUpdateBegin:
; The first priority is ensuring that the farmer is not threatened.
; We iterate through all of player 1's units and make sure none of them are within chebyshev distance 2.
CheckFarmerSafety:
	ldx #$00
farmerSafeP1UnitsLoop:
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
	
	; if the distance between these two units is less than 3 then break out of the loop and get farmer to safety!
	jsr chebyshevDistance
	cmp #$03
	bcs farmerSafeP1UnitsLoopTail
	
	jmp farmerAttemptMoveToSafety
	
farmerSafeP1UnitsLoopTail:
	inx
	cpx p1UnitCount
	bne farmerSafeP1UnitsLoop
	
CheckFarmerSafetyDone:
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
