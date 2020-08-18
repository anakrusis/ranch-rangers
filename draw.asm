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
	lda springPalette, x
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
	lda springPalette, y
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

	lda param2
	asl a ; x multiplied by 0x02
	sta param2
	
	lda #$00
	sta tilePPUAddress
	lda param3
	sta tilePPUAddress + 1
	
	asl tilePPUAddress + 1 ; y multiplied by 0x40 (16 bit left shift six times)
	rol tilePPUAddress
	asl tilePPUAddress + 1
	rol tilePPUAddress 
	asl tilePPUAddress + 1 
	rol tilePPUAddress
	asl tilePPUAddress + 1
	rol tilePPUAddress 
	asl tilePPUAddress + 1
	rol tilePPUAddress 
	asl tilePPUAddress + 1
	rol tilePPUAddress
	
	clc ; x and y are added together
	lda param2
	adc tilePPUAddress + 1
	sta tilePPUAddress + 1
	bcc drawTileAddDone
	inc tilePPUAddress
drawTileAddDone:
	
	clc	; the sum of x and y are added to the value $20c0 which is the top part of the map screen
	lda tilePPUAddress + 1
	adc #$00
	sta tilePPUAddress + 1	
	
	lda tilePPUAddress
	adc #$20			
	sta tilePPUAddress
	
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
	
	lda tilePPUAddress
	sta teste
	lda tilePPUAddress + 1
	sta teste + 1
	
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
	sta currentMapByte
	sta param1
	
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
	sta param1 ; param1 holds the tiletype for now, which was previously loaded into A
	stx param2 ; param2 holds the x position for a little while, since X is occupied
	sty param3
	
	;sta param1 ; these lines uncommented would produce a bulk drawing result.
	;stx param2 ; maybe in the future there can be an additional parameter to switch between
	;sty param3 ; buffered textbox drawing and bulk textbox drawing. that would be pretty cool.
	;jsr drawTile
	
	txa ; x is temporarily used for indexing the tile buffer
	pha
	
	jsr placeTileInBuffer
	
	pla ; the old x returns
	tax
	
	lda param4 ; param2 = (x + width)
	clc
	adc param6
	sta param2
	
	inx
	cpx param2
	bne drawTextBoxXLoop

	lda param5 ; param3 = (y + height)
	clc
	adc param7
	sta param3

	iny
	cpy param3
	bne drawTextBoxYLoop
	
	rts
	
loadTextboxTileToA:
	lda param4 ; param2 = (x + width)
	clc
	adc param6
	sta param2
	lda param5 ; param3 = (y + height)
	clc
	adc param7
	sta param3

checkX:
	cpx param4
	bne checkXSummed
	
	lda #$08
	cpy param5
	beq textBoxTileLoaded
	
	lda #$0e
	dec param3
	cpy param3
	beq textBoxTileLoaded
	
	lda #$0b
	jmp textBoxTileLoaded
	
checkXSummed:
	dec param2 ; its evaluating (width+x)-1
	lda param2

	cpx param2
	bne checkXOther
	
	lda #$0a
	cpy param5
	beq textBoxTileLoaded
	
	lda #$10
	dec param3
	cpy param3
	beq textBoxTileLoaded
	
	lda #$0d
	jmp textBoxTileLoaded
	
checkXOther:
	lda #$09
	cpy param5
	beq textBoxTileLoaded
	
	lda #$0f
	dec param3
	cpy param3
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

	ldy param5
drawMapChunkYLoop:

	ldx param4
drawMapChunkXLoop:

	stx param2 ; param2 and param3 temporarily hold the x and y values for now
	sty param3 
	
	txa
	pha
	
	; Hey, this first portion of the map chunk rendering attempts to bypass the typical tile drawing by
	; iterating through each players units and seeing if their coordinates match up with the X/Y iterators.
	; If so, it loads those metatiles to the buffer and skips the tile rendering.
	
	; first iterating through PLAYER 1 UNITS:
	
	ldx #$00
scanP1PiecesLoop:
	lda p1PiecesX, x
	cmp param2
	bne scanP1PiecesLoopTail
	
	lda p1PiecesY, x
	clc
	adc #MAP_DRAW_Y
	cmp param3
	bne scanP1PiecesLoopTail
	
	lda p1PiecesType, x           ; if both the X and Y coordinates match, then add the unit to the buffer
	clc 
	adc #$04
	sta param1
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
	
	ldx #$00    ; here the x register is used to iterate through all of player 2's units
scanP2PiecesLoop:
	lda p2PiecesX, x
	cmp param2
	bne scanP2PiecesLoopTail
	
	lda p2PiecesY, x
	clc
	adc #MAP_DRAW_Y
	cmp param3
	bne scanP2PiecesLoopTail
	
	lda p2PiecesType, x           ; if both the X and Y coordinates match, then add the unit to the buffer
	clc 
	adc #$11
	sta param1
	; param2 and param3 are already set up and good to go
	
	jsr placeTileInBuffer
	
	pla ; before leaving the player unit iteration loop, we have to restore the original x and y registers!
	tax
	
	jmp drawMapChunkXLoopTail
	
scanP2PiecesLoopTail:
	inx
	cpx p2UnitCount
	bne scanP2PiecesLoop
	
	pla
	tax

	; map tile has to get to A so here goes...
	tya
	sec
	sbc #MAP_DRAW_Y
	
	asl a
	asl a
	asl a
	asl a 
	stx param2
	clc
	adc param2 ; mapdata index = (y*16)+x
	sta param2 ; param2 stores the mapdata index temporarily
	
	txa ; frees x to be used for indexing the mapdata
	pha
	
	ldx param2
	lda MapData, x ; now A has the tile value, which is now given to param1
	sta param1
	
	pla ; x is back in business
	tax

	stx param2 ; param2 holds the x position and param3 holds the y position
	sty param3
	
	txa ; (x is clobbered by the following subroutine)
	pha
	
	; param1 2 and 3 get passed into here
	jsr placeTileInBuffer
	
	pla ; the old x returns
	tax
	
drawMapChunkXLoopTail: ; here the temp variables in param2&3 are generated to determine whether the rectangle has been fully achieved.
	
	lda param4 ; param2 = (x + width)
	clc
	adc param6
	sta param2
	
	inx
	cpx param2
	beq drawMapRowDone
	jmp drawMapChunkXLoop

drawMapRowDone:
	lda param5 ; param3 = (y + height)
	clc
	adc param7
	sta param3

	iny
	cpy param3
	beq drawMapChunkDone
	jmp drawMapChunkYLoop

drawMapChunkDone:	
	rts
	
drawCursor:
	lda guiMode
	cmp #$01
	bne hideMapCursor

	lda cursorX ; set cursor x position on screen (will be made better soon (read: without oam hardcoding))
	asl a       ; multiplied by 16 (coarse)
	asl a
	asl a
	asl a
	sta $0203
	sta $020b
	clc
	adc #$08
	sta $0207
	sta $020f
	
	lda cursorY
	clc
	adc #MAP_DRAW_Y ; position is offset by 3 metatiles by default
	asl a           ; multiplied by 16 (coarse)
	asl a
	asl a
	asl a
	sec
	sbc #$01        ; seems to render 1 pixel too low lol so subtract 1
	sta $0200
	sta $0204
	clc
	adc #$08
	sta $0208
	sta $020c
	
	lda #$80 ; the rectangly icon tile
	sta $0201
	
	; lda #%00000011 ; all that flippy stuff lol
	; sta $0202
	; lda #%01000011
	; sta $0206
	; lda #%10000011
	; sta $020a
	; lda #%11000011
	; sta $020e
	
	jmp drawCursorDone
	
hideMapCursor:
	lda #$fe
	sta $0200
	sta $0204
	sta $0208
	sta $020c
	
	; A menu with 0 options (a plain textbox) means no cursor is drawn.
	ldx guiMode
	lda GuiMenuSizes, x
	cmp #$00
	bne drawMenuCursor
	jmp drawCursorDone

drawMenuCursor:
	lda activeGuiX
	asl a
	asl a
	asl a
	asl a
	clc
	adc #$08 ; plus 8 pixels
	sta $0203
	lda activeGuiY
	asl a
	asl a
	asl a
	asl a
	clc
	adc #$10   ; plus 16 pixels
	sta param1 ; temporarily store the top position
	
	lda menuCursorPos ; (cursorpos * 16) + top position
	asl a
	asl a
	asl a
	asl a
	clc
	adc param1
	
	sta $0200
	
	lda #$81 ; cursor icon
	sta $0201
	
drawCursorDone:
	rts
	
; You know how it goes, param1 type, param2 Xposition, param3 Yposition
; clobbers X
placeTileInBuffer:
	lda tileBufferLength ; bufferlength * 4 is the start position of the new item in the buffer to place
	asl a
	asl a
	tax 
	lda param1
	sta tileBuffer, x ; tiletype stored in param1 for now
	inx
	lda param2
	sta tileBuffer, x ; x value stored in param2 for now 
	inx
	lda param3
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
	lda #$63
	sta strPPUAddress + 1
	
	lda #LOW(text_EngineTitle)
    sta stringPtr
    lda #HIGH(text_EngineTitle)
    sta stringPtr+1
	
	rts