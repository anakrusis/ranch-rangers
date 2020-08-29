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
	lda globalTick
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