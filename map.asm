; credit to nesdev wiki for the prng function:
; http://wiki.nesdev.com/w/index.php/Random_number_generator

CopyMapFromRom:	
	ldx #$c0
CopyMapLoop:
	lda testMap, x
	sta MapData, x
	dex
	bne CopyMapLoop

	rts
	
prng:
	ldy #$08     ; iteration count (generates 8 bits)
	lda seed+0
prng1:
	asl a        ; shift the register
	rol seed+1
	bcc prng2
	eor #$39   ; apply XOR feedback whenever a 1 bit is shifted out
prng2:
	dey
	bne prng1
	sta seed+0
	cmp #0     ; reload flags
	rts
	
GenerateMap:
	lda #MAP_WIDTH
	sta MapWidth

	lda globalTick
	cmp #$00
	bne seedStore
	
	clc
	adc #$01 ; if the seed is 0 then add 1, prng breaks with 0
seedStore:
	sta seed

	ldx #$00
GenMapLoop:
	jsr prng
	cmp landProbabilityTable, x
	bcc PlaceGrass
	
	lda #$00
	sta MapData, x
	
	jmp GenMapLoopTail
	
PlaceGrass:
	lda #$02
	sta MapData, x
	
GenMapLoopTail:
	inx
	cpx #$c0
	bne GenMapLoop
	
	rts
	
; probability of a tile being land
landProbabilityTable:
	.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $10, $10, $10, $10, $40, $40, $40, $40, $40, $40, $10, $10, $10, $10, $00
	.db $00, $40, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $40, $00
	.db $00, $40, $7f, $7f, $c0, $c0, $c0, $c0, $c0, $c0, $c0, $c0, $7f, $7f, $40, $00
	.db $00, $40, $7f, $7f, $d0, $d0, $d0, $d0, $d0, $d0, $d0, $d0, $7f, $7f, $40, $00
	.db $00, $40, $7f, $7f, $d0, $ff, $ff, $ff, $ff, $ff, $ff, $d0, $7f, $7f, $40, $00
	.db $00, $40, $7f, $7f, $d0, $ff, $ff, $ff, $ff, $ff, $ff, $d0, $7f, $7f, $40, $00
	.db $00, $40, $7f, $7f, $d0, $d0, $d0, $d0, $d0, $d0, $d0, $d0, $7f, $7f, $40, $00
	.db $00, $40, $7f, $7f, $c0, $c0, $c0, $c0, $c0, $c0, $c0, $c0, $7f, $7f, $40, $00
	.db $00, $40, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $40, $00
	.db $00, $10, $10, $10, $10, $40, $40, $40, $40, $40, $40, $10, $10, $10, $10, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	
testMap:
	.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $02, $02, $00, $00, $00, $02, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00, $00, $00, $00, $00
	.db $00, $00, $02, $02, $02, $02, $01, $02, $02, $02, $02, $02, $02, $00, $00, $00
	.db $00, $02, $02, $02, $02, $02, $02, $01, $02, $02, $02, $02, $02, $02, $00, $00
	.db $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00
	.db $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00
	.db $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $01, $02, $02, $02, $02, $00
	.db $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $01, $01, $02, $00, $00, $00
	.db $00, $00, $00, $02, $02, $02, $02, $02, $00, $00, $02, $02, $00, $00, $00, $00
	.db $00, $00, $00, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	
; takes in cursorX and Y, and turn
placeFarmAtCursorPos:
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
	
	rts