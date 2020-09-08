AiUpdate:
	lda computerMustMakeMove
	cmp #$01
	beq AiUpdateBegin
	jmp AiDone
	
AiUpdateBegin:
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
	
	lda validMovesCount
	cmp #$00
	bne AiMove
	jmp AiDone
	
;param1 and param2 temporarily store the units new position
AiMove:
	ldx #$00
	lda validMovesX, x
	sta cursorX
	lda validMovesY, x
	sta cursorY
	
	jsr moveSelectedUnitToCursorPos

AiDone:
	lda #$00
	sta computerMustMakeMove
	
	rts