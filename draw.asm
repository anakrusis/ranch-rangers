; no arguments, fills both nametables with 24 (blank blue character). bulk drawing only! wayyy too much for vblank!	
clearScreen:

initPalette:
	lda $2002
	lda #$3F
	sta $2006   
	lda #$10
	sta $2006 
	
	ldx #$00
SpritePaletteLoop:          ; sprites first
	lda spritePalette, x
	sta $2007
	inx
	cpx #$10
	bne SpritePaletteLoop
	
	lda $2002
	lda #$3F
	sta $2006   
	lda #$00
	sta $2006 
	
	ldx #$00
BGPaletteLoop:              ; then the background palettes
	lda dawnPalette, x
	sta $2007
	inx
	cpx #$10
	bne BGPaletteLoop

initNametables:
	lda $2002
	lda #$20
	sta $2006
	lda #$00
	sta $2006
	
	ldx #$00
BGLoop:
	lda #$24 ; blank blue tile
	sta $2007
	sta $2007
	sta $2007
	sta $2007
	inx
	cpx #$f0
	bne BGLoop 
	
loadAttr:
	lda $2002   
	lda #$23
	sta $2006   
	lda #$C0
	sta $2006   
	ldx #$00
attrLoop:
	lda #$00 ; all the first palette
	sta $2007 
	inx
	cpx #$40
	bne attrLoop
	
	lda $2002
	lda #$24
	sta $2006
	lda #$00
	sta $2006
	
	ldx #$00
SecondBGLoop:
	lda #$24 ; blank blue tile
	sta $2007
	sta $2007
	sta $2007
	sta $2007
	inx
	cpx #$f0
	bne SecondBGLoop 
	
loadSecondAttr:
	lda $2002   
	lda #$27
	sta $2006   
	lda #$C0
	sta $2006   
	ldx #$00
secondAttrLoop:
	lda #$00 ; all the first palette
	sta $2007 
	inx
	cpx #$40
	bne secondAttrLoop
	
	rts
	
changeSeasonPalette:

	;lda #%00000110 ; background and sprites disabled
	;lda $2001

	lda $2002
	lda #$3F
	sta $2006   
	lda #$00
	sta $2006 
	
	lda season
	asl a
	asl a
	asl a
	asl a
	tay
	
	ldx #$00
seasonPaletteLoop:
	lda dawnPalette, y
	sta $2007
	inx
	iny
	cpx #$10
	bne seasonPaletteLoop
	
	;lda #%00011110 ; background and sprites enabled
	;lda $2001
	
	rts

; tile type in param1, X and Y position of tile in param2 and param3
; attr in param8? maybe it should be optional? (it was added on later don't judge xD)

; you should only call this during vblank or while bulk drawing with ppu off
drawTile:
	tya ; This is Y clobber prevention so that you can keep using Y to do other things if you like.
	pha
	
	jsr setAttributes

	lda #$20 ; initial address of 2000 and nametable 0, the only nametable of this game >:)
	sta tilePPUAddress
	
	lda param3 ; y*2
	asl a
	lsr a      ; shifted right 3 times for just the high 2 bits
	lsr a
	lsr a
	ora tilePPUAddress
	sta tilePPUAddress
	
	lda param3 ; y*2 again
	asl a 
	
	asl a ; this time shifted left 5 times for the low 3 bits on top 
	asl a
	asl a
	asl a
	asl a
	sta tilePPUAddress+1
	
	lda param2 ; x*2
	asl a
	ora tilePPUAddress+1
	sta tilePPUAddress+1
	
drawTileTop:
	lda $2002
	lda tilePPUAddress
	sta $2006
	lda tilePPUAddress + 1
	sta $2006	
	
	lda param1
	asl a
	asl a
	tay
	
	lda MetaTiles, y
	sta $2007
	iny
	lda MetaTiles, y
	sta $2007
	iny
	
	clc ; go down a row
	lda tilePPUAddress + 1
	adc #$20
	sta tilePPUAddress + 1
	
	bcc drawTileBottom
	inc tilePPUAddress
	
drawTileBottom:
	lda $2002
	lda tilePPUAddress
	sta $2006
	lda tilePPUAddress + 1
	sta $2006	

	lda MetaTiles, y
	sta $2007
	iny
	lda MetaTiles, y
	sta $2007
	iny
	
drawTileDone:
	pla ; This is the second and concluding portion of the Y clobber prevention.
	tay

	rts
	
; param2 and param3 should still hold the X and Y values passed in from DrawTile
; y would be clobbered but since this is only called inside a function that pushes y to the stack, its safe
setAttributes:

	lda param2
	lsr a ; x divided by 0x02
	sta param8
	
	lda #$00
	sta tilePPUAddress
	
	lda param3
	lsr a ; y divided by 0x02
	clc
	asl a ; then multiplied by 0x08
	asl a
	asl a
	sta tilePPUAddress + 1
	
	clc ; x and y are added together
	lda param8
	adc tilePPUAddress + 1
	sta tilePPUAddress + 1
	sta param8                  ; param8 has the low byte of the ppu address index before it gets added to $23c0
								; so that it can be used to index the attribute buffer in RAM
	
	bcc setAttributeAddDone
	inc tilePPUAddress
setAttributeAddDone:
	
	clc	; the sum of x and y are added to the value $23c0 which is the start of the attribute table
	lda tilePPUAddress + 1
	adc #$c0
	sta tilePPUAddress + 1	
	
	lda tilePPUAddress
	adc #$23			
	sta tilePPUAddress
	
	lda $2002
	lda tilePPUAddress
	sta $2006
	lda tilePPUAddress + 1
	sta $2006
	
loadAttributeByte:
	; param1 still has the tile value which will soon be drawn
	; param2 and param3 still have the x and y values when they were passed in!
	
; this code is based on a description given by rainwarrior here on this thread: https://forums.nesdev.com/viewtopic.php?t=13950

; however the janky implementation is entirely my fault ;)
	
attributeClearMaskLoad: ;first bitmask for bits that stay the same

	lda param2
	and #$01
	cmp #$01
	beq attrClrXOdd
	jmp attrClrXEven
	
attrClrXOdd:
	lda param3
	and #$01
	cmp #$01
	beq attrClrXOddYOdd
attrClrXOddYEven:
	lda #%00001100
	sta param9
	jmp attrClearMaskLoadDone
	
attrClrXOddYOdd:
	lda #%11000000
	sta param9
	jmp attrClearMaskLoadDone

attrClrXEven:
	lda param3
	and #$01
	cmp #$01
	beq attrClrXEvenYOdd
attrClrXEvenYEven:
	lda #%00000011
	sta param9
	jmp attrClearMaskLoadDone

attrClrXEvenYOdd:
	lda #%00110000
	sta param9
	
	; param8 has the index to access the target value from attributesBuffer
	; param9 has the bitmask to be used on the target value
	
attrClearMaskLoadDone:

	lda param7 ; param7 temporarily used
	pha
	
	lda param9
	eor #%11111111 ; oops I have to invert it again, maybe will remove this and fix later
	sta param9     ; this bitmask is used for the bits that are staying the same

	ldy param8
	lda attributesBuffer, y ; target value loaded
	and param9              ; bitmasked target value to be put in param7
	sta param7   
	
	lda param9
	eor #%11111111 ; inverted bitmask for bits that are changing
	sta param9
	
	ldy param1
	lda MetaTileAttributes, y ; new value loaded
	and param9                ; bitmasked target value
	
	ora param7                ; or together new value and target value
	
	ldy param8
	sta attributesBuffer, y ; back to its original position in the attributes buffer, and into the ppu
	sta $2007
	
	pla
	sta param7 ; restore param7
	
	rts
	
; no arguments, draws the entire map (bulk drawing only! this is far too much to fit in vblank!)
drawMap:

	ldx #$00
mapByteLoop:
	
	lda MapData, x
	cmp #TILE_GRASS
	beq mapByteLoopDrawGrass
	cmp #TILE_WATER
	beq mapByteLoopDrawWater
	
	jmp drawMapTileRegular
	
mapByteLoopDrawGrass:
	jsr HandleGrassDraw
	sta <param1
	jmp drawMapTransform
	
mapByteLoopDrawWater:
	jsr HandleWaterDraw
	sta <param1
	jmp drawMapTransform

drawMapTileRegular:	
	lda MapData, x
	sta currentMapByte
	sta <param1

drawMapTransform:
	txa ; x coordinate (modulo 16)
	and #%00001111
	sta param2
	
	txa ; y coordinate (divided by 16 and floored)
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #MAP_DRAW_Y ; 3 metatiles added on to the position of the tile because hotbar
	sta param3
	
	jsr drawTile
	
	inx
	cpx #$c0
	bne mapByteLoop
	
drawMapDone:
	rts
	
; this is simply buffering metatiles and can be called whenever!
; param4/5: x and y position
; param6/7: width and height

; param2 temporarily used as the sum of the x+plus width
; param3 temporarily used as the sum of the y+plus height
drawTextBox:

	ldy param5
drawTextBoxYLoop:

	ldx param4
drawTextBoxXLoop:

	jsr loadTextboxTileToA
	sta <param1 ; param1 holds the tiletype for now, which was previously loaded into A
	stx <param2 ; param2 holds the x position for a little while, since X is occupied
	sty <param3
	
	;sta param1 ; these lines uncommented would produce a bulk drawing result.
	;stx param2 ; maybe in the future there can be an additional parameter to switch between
	;sty param3 ; buffered textbox drawing and bulk textbox drawing. that would be pretty cool.
	;jsr drawTile
	
	txa ; x is temporarily used for indexing the tile buffer
	pha
	
	jsr placeTileInBuffer
	
	pla ; the old x returns
	tax
	
	lda <param4 ; param2 = (x + width)
	clc
	adc <param6
	sta <param2
	
	inx
	cpx <param2
	bne drawTextBoxXLoop

	lda <param5 ; param3 = (y + height)
	clc
	adc <param7
	sta <param3

	iny
	cpy <param3
	bne drawTextBoxYLoop
	
	rts
	
loadTextboxTileToA:
	lda <param4 ; param2 = (x + width)
	clc
	adc <param6
	sta <param2
	lda <param5 ; param3 = (y + height)
	clc
	adc <param7
	sta <param3

checkX:
	cpx <param4
	bne checkXSummed
	
	lda #$08
	cpy <param5
	beq textBoxTileLoaded
	
	lda #$0e
	dec <param3
	cpy <param3
	beq textBoxTileLoaded
	
	lda #$0b
	jmp textBoxTileLoaded
	
checkXSummed:
	dec <param2 ; its evaluating (width+x)-1
	lda <param2

	cpx <param2
	bne checkXOther
	
	lda #$0a
	cpy <param5
	beq textBoxTileLoaded
	
	lda #$10
	dec <param3
	cpy <param3
	beq textBoxTileLoaded
	
	lda #$0d
	jmp textBoxTileLoaded
	
checkXOther:
	lda #$09
	cpy <param5
	beq textBoxTileLoaded
	
	lda #$0f
	dec <param3
	cpy <param3
	beq textBoxTileLoaded
	
	lda #$0c
	
textBoxTileLoaded:	
	rts
	
; drawString works like this: you set stringPtr and strPPUAddress
; before you call this subroutine. As long as you do that, you're good to go!
; Oh, and make sure all your strings end in $ff, or else you get corrupto!!
; Also, newline character is $fe.

; todo make it buffered also lol it used to clobber everything, I didn't know how to use ram hardly when I wrote this

drawString:
	txa
	pha
	tya
	pha

	ldy #$00
	
setStringAddr:
	ldx strPPUAddress
	stx $2006
	ldx strPPUAddress + 1
	stx $2006

drawStringLoop:
	lda [stringPtr], y
	cmp #$ff
	beq drawStringDone
	
	cmp #$fe
	beq newLine
	
writeChar: 
	sta $2007
	iny

	jmp drawStringLoop

; newLine adds 40 to the initial nametable address where text starts rendering,
; moving it down 2 tiles = 16 pixels
newLine:	
	clc
	lda strPPUAddress + 1
	adc #$40
	sta strPPUAddress + 1
	
	bcc newLineDone
	inc strPPUAddress
	
newLineDone:
	iny
	jmp setStringAddr
	
drawStringDone:
	pla 
	tay
	pla
	tax

	rts
	
; drawMapChunk behaves just like drawTextBox! it can be called whenever, it's buffered!
; param4/5: x and y position
; param6/7: width and height

; param2 temporarily used as the sum of the x+plus width
; param3 temporarily used as the sum of the y+plus height
drawMapChunk:

	ldy <param5
drawMapChunkYLoop:

	ldx <param4
drawMapChunkXLoop:
	
	stx <param2
	sty <param3
	
	txa ; the following subroutines clobber x
	pha
	
	; this first portion of the map chunk rendering attempts to bypass the typical tile drawing by
	; iterating through each players units and seeing if their coordinates match up with the X/Y iterators.
	; If so, it loads those metatiles to the buffer and skips the tile rendering.
	ldx #$00
	cpx <p1UnitCount
	bne scanP1Pieces
	jmp scanP2Pieces
	
scanP1Pieces:	
scanP1PiecesLoop:
	lda p1PiecesX, x
	cmp <param2
	bne scanP1PiecesLoopTail
	
	lda p1PiecesY, x
	clc
	adc #MAP_DRAW_Y
	cmp <param3
	bne scanP1PiecesLoopTail
	
	lda p1PiecesType, x           ; if both the X and Y coordinates match, then add the unit to the buffer
	clc 
	adc #P1_UNITS_START_OFFSET
	sta <param1
	; param2 and param3 are already set up and good to go
	
	jsr placeTileInBuffer
	
	pla ; before leaving the player unit iteration loop, we have to restore the original x and y registers!
	tax
	
	jmp drawMapChunkXLoopTail
	
scanP1PiecesLoopTail:
	inx
	cpx p1UnitCount
	bne scanP1PiecesLoop
	
	; Now checking PLAYER 2 UNITS:
scanP2Pieces:	
	ldx #$00    ; here the x register is used to iterate through all of player 2's units
	cpx <p2UnitCount
	bne scanP2PiecesLoop
	jmp scanP2PiecesDone
	
scanP2PiecesLoop:
	lda p2PiecesX, x
	cmp <param2
	bne scanP2PiecesLoopTail
	
	lda p2PiecesY, x
	clc
	adc #MAP_DRAW_Y
	cmp <param3
	bne scanP2PiecesLoopTail
	
	lda p2PiecesType, x           ; if both the X and Y coordinates match, then add the unit to the buffer
	clc 
	adc #P2_UNITS_START_OFFSET
	sta <param1
	; param2 and param3 are already set up and good to go
	
	jsr placeTileInBuffer
	
	pla ; before leaving the player unit iteration loop, we have to restore the original x and y registers!
	tax
	
	jmp drawMapChunkXLoopTail
	
scanP2PiecesLoopTail:
	inx
	cpx <p2UnitCount
	bne scanP2PiecesLoop

scanP2PiecesDone:	
	pla
	tax

drawTileNoUnit:
	; map tile has to get to A so here goes...
	tya
	sec
	sbc #MAP_DRAW_Y
	
	asl a
	asl a
	asl a
	asl a 
	stx <param2
	clc
	adc <param2 ; mapdata index = (y*16)+x
	sta <param2 ; param2 stores the mapdata index temporarily
	
	txa ; frees x to be used for indexing the mapdata
	pha
	
	ldx <param2
	lda MapData, x ; now A has the tile value, which is now given to param1
	
	; grass is handled uniquely when drawing tiles
	; water is also now!
	cmp #TILE_GRASS
	beq GrassDraw
	cmp #TILE_WATER
	beq WaterDraw
	
	jmp NormalTileDraw
	
GrassDraw:
	jsr HandleGrassDraw
	jmp NormalTileDraw

WaterDraw:
	jsr HandleWaterDraw
	
NormalTileDraw:
	sta <param1
	
	pla ; x is back in business
	tax

	stx <param2 ; param2 holds the x position and param3 holds the y position
	sty <param3
	
	txa ; (x is clobbered by the following subroutine)
	pha
	
	; param1 2 and 3 get passed into here
	jsr placeTileInBuffer
	
	pla ; the old x returns
	tax
	
drawMapChunkXLoopTail: ; here the temp variables in param2&3 are generated to determine whether the rectangle has been fully achieved.
	
	lda <param4 ; param2 = (x + width)
	clc
	adc <param6
	sta <param2
	
	inx
	cpx <param2
	beq drawMapRowDone
	jmp drawMapChunkXLoop

drawMapRowDone:
	lda <param5 ; param3 = (y + height)
	clc
	adc <param7
	sta <param3

	iny
	cpy <param3
	beq drawMapChunkDone
	jmp drawMapChunkYLoop

drawMapChunkDone:	
	rts
	
; input: iterator in X (either X position or combined Y*16+X, either work)
; output: tile value in A
HandleGrassDraw:
	; if a grass tile, lets check to see if its on the edge of the border
	txa
	and #$0f
	cmp #$07
	beq drawBorderLeft
	cmp #$08
	beq drawBorderRight
	lda #$02
	rts
	
drawBorderLeft:
	lda #$15
	rts

drawBorderRight
	lda #$16
	rts
	
; input: absolute index to mapdata in X
; output: tile value in A
HandleWaterDraw:

	lda #$00
	sta <param8 ;param8 temporarily stores index into metatile data "which tile to draw"

	txa
	stx <param9 ;param9 temporarily contains index to MapData "where is the tile in question?"
	
LandTileRightCheck: ; right tile = +01
	clc
	adc #$01
	tax
	lda MapData, x
	cmp #TILE_WATER
	beq LandTileUpCheck
	
	inc param8
	
LandTileUpCheck: ; up tile = +02
	lda <param9
	sec
	sbc #$10
	tax
	lda MapData, x
	cmp #TILE_WATER
	beq LandTileLeftCheck
	
	lda <param8
	clc
	adc #$02
	sta <param8
	
LandTileLeftCheck:
	lda <param9
	sec
	sbc #$01
	tax
	lda MapData, x
	cmp #TILE_WATER
	beq LandTileDownCheck	
	
	lda <param8
	clc
	adc #$04
	sta <param8	
	
LandTileDownCheck:
	lda <param9
	clc
	adc #$10
	tax
	lda MapData, x
	cmp #TILE_WATER
	beq LandTileCheckDone	
	
	lda <param8
	clc
	adc #$08
	sta <param8
	
LandTileCheckDone:
	lda <param9
	tax ; clobber protection is done

	lda <param8
	clc
	adc #$17
	rts
	
; You know how it goes, param1 type, param2 Xposition, param3 Yposition
; clobbers X
placeTileInBuffer:
	lda tileBufferLength ; bufferlength * 4 is the start position of the new item in the buffer to place
	asl a
	asl a
	tax 
	lda <param1
	sta tileBuffer, x ; tiletype stored in param1 for now
	inx
	lda <param2
	sta tileBuffer, x ; x value stored in param2 for now 
	inx
	lda <param3
	sta tileBuffer, x ; y value directly stored in Y
	
	inc tileBufferLength
	
	rts
	
updateHotbar:
	lda #$01
	sta param4
	lda #$01
	sta param5
	lda #$0e
	sta param6
	lda #$02
	sta param7
	
	jsr drawTextBox
	
StringTest:
	lda #$20
	sta strPPUAddress
	lda #$43
	sta strPPUAddress + 1
	
	lda #LOW(text_EngineTitle)
    sta stringPtr
    lda #HIGH(text_EngineTitle)
    sta stringPtr+1
	
updateStringBuffer:
	ldx #$00
clearStringBufferLoop:
	lda #$28 ; period character
	sta stringBuffer, x
	
	inx
	cpx #$20
	bne clearStringBufferLoop

	lda turn
	cmp #$00
	beq loadPointerPlayer1Name
	jmp loadPointerPlayer2Name
	
loadPointerPlayer1Name:
	lda #LOW(text_Player1Turn+2)
	sta param1
	lda #HIGH(text_Player1Turn+2)
	sta param1+1
	
	jmp bufferPlayerName
	
loadPointerPlayer2Name:
	lda #LOW(text_Player2Turn+2)
	sta param1
	lda #HIGH(text_Player2Turn+2)
	sta param1+1
	
bufferPlayerName:
	ldy #$00
bufferPlayerNameLoop:
	lda [param1], y

	sta stringBuffer, y
	
	iny
	cpy #$08
	bne bufferPlayerNameLoop
	
bufferGoldText:
	ldy turn
	lda p1Gold, y
	
bcdGoldDisplay:
	sta Hex0
	jsr HexToDecimal.8
	
	lda DecTens
	sta stringBuffer+11
	lda DecOnes
	sta stringBuffer+12
	lda #$10
	sta stringBuffer+13 ; "g"
	
bcdFarmCount:
	lda p1FarmCount, y
	sta Hex0
	jsr HexToDecimal.8
	
	lda #$42 ; farm symbol
	sta stringBuffer+17
	lda DecTens
	sta stringBuffer+18
	lda DecOnes
	sta stringBuffer+19

bcdUnitCount:
	lda #$2f
	sta stringBuffer+22
	ldy turn
	lda p1UnitCount,y
	sta stringBuffer+23
	lda #$27
	sta stringBuffer+24
	lda #$08
	sta stringBuffer+25
	
	rts
