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
	
	lda #$01
	sta <param6
	
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
	lda #$00
	sta <param6
	
	jsr drawMetasprite

	dec unitHeavenTimer

drawHeavenSpriteDone:

	lda showAnimSpriteFlag
	cmp #$01
	beq drawTurnAnim
	jmp drawTurnAnimDone
drawTurnAnim:
	jsr doUnitMovementStep

	lda moveAnimX
	sta <param2
	lda moveAnimY
	sta <param3
	
	lda turn
	sta <param4 ; sprite palette matches unit allegiance (00 and 01!)
	
	lda unitSelectedType
	asl a
	asl a
	asl a
	sta <param9
	
	; todo offset this by unit type
	lda moveAnimDir
	asl a
	clc
	adc #$04 ; start of unit move metasprites is 04
	adc <param9
	sta <param9
	
	lda globalTick ; staggered by which frame of the animation its on, globalTick/8's LSB determines
	lsr a
	lsr a
	lsr a
	and #$01
	clc
	adc <param9
	
	sta <param5
	
	lda moveAnimFlip
	sta <param6

	jsr drawMetasprite
	
drawTurnAnimDone:
	
	lda showEggSpriteFlag
	cmp #$00
	bne drawEggAnim
	jmp drawEggAnimDone

drawEggAnim:
drawEggAnimCheckDone:
	lda moveAnimX
	cmp moveAnimTargetX
	bne drawEggAnimNotDone
	
	lda moveAnimY
	cmp moveAnimTargetY
	bne drawEggAnimNotDone
	
	lda eggAnimOffset
	cmp #$00
	bne drawEggAnimNotDone
	
	lda #$00
	sta showEggSpriteFlag

drawEggAnimNotDone:
	jsr doUnitMovementStep
	lda #$80 ; egg
	sta <param1
	
	lda moveAnimX
	clc
	adc #$04 ; middle of the metatile
	sta <param2
	
	; gets divided by two because the resulting arc is too big
eggAnimOffsetSgnCheck:
	lda eggAnimOffset
	; cmp #$80
	; bcs eggAnimOffsetNegative
	
	; lsr a
	
	; jmp eggAnimOffsetDivideDone
	
; eggAnimOffsetNegative:
	; eor #$ff
	; clc
	; adc #$01
	; lsr a
	; eor #$ff
	; clc
	; adc #$01
	
eggAnimOffsetDivideDone:

	clc
	adc moveAnimY
	clc
	adc #$04 ; ditto
	sta <param3
	
	lda #$02 ;palette
	sta <param4
	jsr drawSprite

drawEggAnimDone:
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
	
; param5 metasprite
; param2/3 X and Y position
; param4 color attribute
; param6 hflip (00 for none and 01 for enabled)
drawMetasprite:
	ldx #$00
drawMetaSpriteLoop:
	stx <param9

	lda <param5
	asl a
	asl a
	clc
	adc <param9
	eor <param6 ; when param6=$01, it flips sprite indices so that 0 1 becomes 1 0 and 2 3 becomes 3 2
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
	
	lda <param6 ; horizontal flip set if not already in param4
	ror a
	ror a
	ror a
	ora <param4
	sta <param4
	
	jsr drawSprite
	
	lda <param8 ; restore old X and Y for next iteration
	sta <param2
	lda <param9
	sta <param3

	inx
	cpx #$04
	bne drawMetaSpriteLoop

	rts
	
doUnitMovementStep:
	; eggimation only updates every other frame.
	lda globalTick
	and #$01
	cmp #$00
	bne doUnitAnimEggStepDone
doUnitEggAnimStep:
	lda eggAnimOffset
	clc
	adc eggAnimYVelocity
	sta eggAnimOffset

	inc eggAnimYVelocity ; only makes a difference with egg animation
doUnitAnimEggStepDone:

	lda cursorX
	asl a
	asl a
	asl a
	asl a
	sta moveAnimTargetX
	lda cursorY
	clc
	adc #MAP_DRAW_Y
	asl a
	asl a
	asl a
	asl a
	sta moveAnimTargetY
	
doMovX:
	lda moveAnimX
	cmp moveAnimTargetX
	beq doMovY
	bcc doMovAddX
	bcs doMovSubX
	jmp doMovY
	
doMovAddX: ; moving right
	lda #$00
	sta moveAnimFlip
	lda #$01
	sta moveAnimDir
	inc moveAnimX
	jmp doMovY
doMovSubX: ; moving left
	lda #$01
	sta moveAnimFlip
	sta moveAnimDir
	dec moveAnimX	
	
doMovY:
	lda moveAnimY
	cmp moveAnimTargetY
	beq doUnitMovementStepDone
	bcc doMovAddY
	bcs doMovSubY
	jmp doUnitMovementStepDone
	
doMovAddY: ; moving down
	lda #$00
	sta moveAnimDir
	inc moveAnimY
	jmp doUnitMovementStepDone
doMovSubY: ; moving up
	lda #$02
	sta moveAnimDir
	dec moveAnimY
doUnitMovementStepDone:	
	rts
	
initChickenAtkAnim:
	; for right now only the chicken has a seperate attack and movement
	; but this can be handled here too later if we must account for other 
	lda #$01
	sta showEggSpriteFlag
	
	; turn * 32
	lda turn
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc unitSelected
	tay
	
	lda p1PiecesX, y
	sta <param4
	lda p1PiecesY, y
	sta <param5
	
	; now the sprite update setting its initial position to the old position set in param4/5
	lda <param4
	asl a
	asl a
	asl a
	asl a
	sta moveAnimX
	lda <param5
	clc
	adc #MAP_DRAW_Y
	asl a
	asl a
	asl a
	asl a
	sta moveAnimY
	
	lda <cursorX
	asl a
	asl a
	asl a
	asl a
	sta moveAnimTargetX
	
	lda #$00
	sta eggAnimOffset
	
	; the calc for eggAnimYVelocity gets the distance in tiles between the target and start
	; multiplies it by 16 to get a per-pixel measurement
	; divides it by two to get the midpoint 
	; divides it by two again to get half of that
	; and subtracts that value so that (for instance 16 pixels would go -8...0...7) and end up in an arc that finishes properly
	
	lda <unitSelectedX
	sta <param1
	lda <unitSelectedY
	sta <param2
	lda <cursorX
	sta <param3
	lda <cursorY
	sta <param4
	jsr chebyshevDistance
	
	asl a
	asl a
	asl a
	asl a
	
	lsr a
	lsr a
	sta <param5
	
	lda #$00
	sec
	sbc <param5
	
	sta eggAnimYVelocity
	
	rts