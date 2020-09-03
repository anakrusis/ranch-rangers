drawSprites:
	
allSpritesOffscreen:
	ldx #$00
	stx spriteDrawCount ; resets OAM pointer every frame
	
allSpritesOffscreenLoop:
	txa
	asl a
	asl a
	tay

	lda #$fe
	sta $0200, y ; with no offset it just places the y variable offscreen, this is fine enough
	
	lda #%00011111
	and $0202, y
	sta $0202, y
	
	inx
	cpx #$40
	bne allSpritesOffscreenLoop
	
drawCursor:
	lda guiMode
	cmp #$01
	beq drawMapCursor
	cmp #$09
	beq drawMapCursor
	cmp #$0a
	beq drawMapCursor
	jmp drawMapCursorDone

drawMapCursor:
	lda cursorX ; set cursor x position on screen
	asl a       ; multiplied by 16 (coarse)
	asl a
	asl a
	asl a
	sta <param2
	
	lda cursorY
	clc
	adc #MAP_DRAW_Y ; position is offset by 3 metatiles by default
	asl a           ; multiplied by 16 (coarse)
	asl a
	asl a
	asl a
	sec
	sbc #$01        ; seems to render 1 pixel too low lol so subtract 1
	sta <param3
	
	lda #$00
	sta <param5
	
	lda globalTick
	lsr a
	and #$03
	sta <param4
	
	jsr drawMetasprite
	
drawMapCursorDone:
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
	sta <param2
	
	lda activeGuiY
	asl a
	asl a
	asl a
	asl a
	clc
	adc #$10   ; plus 16 pixels
	sta param9 ; temporarily store the top position
	
	lda menuCursorPos ; (cursorpos * 16) + top position
	asl a
	asl a
	asl a
	asl a
	clc
	adc param9
	
	sta <param3
	
	lda #$81 ; cursor icon
	sta <param1
	lda #$00
	sta <param4
	
	jsr drawSprite
	
drawCursorDone:

	lda guiMode
	cmp #$09
	beq drawValidMoveIndicators
	cmp #$0a
	beq drawValidMoveIndicators
	cmp #$11
	beq drawValidMoveIndicators
	jmp drawValidMoveIndicatorsDone
	
drawValidMoveIndicators:

	ldx #$00
	cpx validMovesCount
	bne validMoveIndicatorLoop
	jmp drawValidMoveIndicatorsDone
	
validMoveIndicatorLoop:
	lda validMovesX, x ; position*16
	asl a
	asl a
	asl a
	asl a
	clc
	adc #$04      ; so it shows up in the middle of the tile
	sta <param2
	
	lda validMovesY, x
	clc
	adc #MAP_DRAW_Y
	asl a
	asl a
	asl a
	asl a
	clc
	adc #$04 ; ditto
	sta <param3
	
	; tile
	lda globalTick
	lsr a
	lsr a
	lsr a
	and #$03
	tay
	lda IndicatorSpriteAnimation, y
	sta <param1
	
	; colors swapping
	lda globalTick
	lsr a
	;lsr a
	and #$03
	sta <param4
	
	jsr drawSprite

validMoveIndicatorLoopTail:	
	inx
	cpx validMovesCount
	bne validMoveIndicatorLoop

drawValidMoveIndicatorsDone:
	ldx #$00
	lda unitHeavenTimer
	cmp #$00
	bne drawHeavenSprite
	jmp drawHeavenSpriteDone
	
drawHeavenSprite:

	lda unitHeavenTimer
	sta <param3
	
	lda unitHeavenXpos
	sta <param2
	
	lda unitHeavenType
	clc
	adc #$01
	sta <param5
	
	; color and flipping (none)
	lda #$00
	sta <param4
	
	jsr drawMetasprite

	dec unitHeavenTimer

drawHeavenSpriteDone:
drawSpritesDone:
	rts
	
; param1 tile
; param2/3 X and Y position
; param4 color attribute
drawSprite:
	lda <spriteDrawCount
	asl a
	asl a
	tay
	
	lda <param3
	sta $0200, y
	lda <param2
	sta $0203, y
	lda <param1
	sta $0201, y
	lda <param4
	sta $0202, y
	
	inc <spriteDrawCount
	rts
	
;param5 metasprite
;param2/3 X and Y position
; param4 color attribute
drawMetasprite:
	ldx #$00
drawMetaSpriteLoop:
	stx <param9

	lda <param5
	asl a
	asl a
	clc
	adc <param9
	tay
	
	lda MetaSprites, y
	sta <param1
	
	lda <param2 ; add on the offsets to the X and Y
	sta <param8 ; old X
	clc
	adc MetaSpriteX, x
	sta <param2
	
	lda <param3
	sta <param9 ; old Y
	clc
	adc MetaSpriteY, x
	sta <param3
	
	jsr drawSprite
	
	lda <param8 ; restore old X and Y for next iteration
	sta <param2
	lda <param9
	sta <param3

	inx
	cpx #$04
	bne drawMetaSpriteLoop

	rts