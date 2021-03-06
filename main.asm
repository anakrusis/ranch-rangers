    .inesprg 1 ;1x 16kb PRG code
    .ineschr 1 ;1x 8kb CHR data
    .inesmap 0 ; mapper 0 = NROM, no bank swapping
    .inesmir 1 ;background mirroring (vertical mirroring = horizontal scrolling)

	.rsset $0000
param1  .rs 1 ; local parameters for functions when you cant use a register
param2  .rs 1
param3  .rs 1
param4  .rs 1
param5  .rs 1
param6  .rs 1
param7  .rs 1
param8  .rs 1
param9  .rs 1
param10 .rs 1
param11 .rs 1
param12 .rs 1
param13 .rs 1
param14 .rs 1
param15 .rs 1
param16 .rs 1	
	
globalTick .rs 1 ; For everything
turn .rs 1       ; 00 = player 1, 01 = player 2
turnCount .rs 2
season .rs 1     ; 00 = spring, 01 = summer, 02 = autumn, 03 = winter
seasonTurnCounter .rs 1

; read the docs on this one lol... It Means Many Things
gameMode .rs 1
guiMode .rs 1 
menuCursorPos .rs 1
menuSize .rs 1 ; number of items in the menu to select from
activeGuiX .rs 1 ; these are used to handle the GUI stuff now
activeGuiY .rs 1
activeGuiWidth .rs 1
activeGuiHeight .rs 1

stringPtr  .rs 2 ; Where's the string we're rendering
strPPUAddress .rs 2 ; What address will the string go to in the ppu

currentMapByte .rs 1 ; what byte is being parsed of the map right now
MapWidth       .rs 1
tilePPUAddress .rs 2 ; ditto as above but for tile changes

teste .rs 2 ; my trusty logger. Now it's a big boy and it can log pointers too.
cursorX .rs 1
cursorY .rs 1

unitSelected .rs 1 ; index
unitSelectedX .rs 1 
unitSelectedY .rs 1
unitSelectedType .rs 1
p1UnitCount .rs 1
p2UnitCount .rs 1

buttons1 .rs 1
buttons2 .rs 1
prevButtons1 .rs 1
prevButtons2 .rs 1

attackMode .rs 1 ; 1 when attacking, 0 when not attacking

seed .rs 2

spriteDrawCount .rs 1
computerMustMakeMove .rs 1

	.rsset $0100 ; these are all timers/values for animations and stuff, non-essential stuff really
turnAnimTimer .rs 1
harvestAnimTimer .rs 1
dpadInputTimer .rs 1
hotbarTextNeedsRefresh .rs 1
seasonPaletteChangeFlag .rs 1
unitHeavenXpos  .rs 1 ; for the animation when a unit deads
unitHeavenType  .rs 1
unitHeavenTimer .rs 1
endTurnTimer .rs 1

moveAnimX .rs 1 ; for the animation when a unit moves
moveAnimY .rs 1
moveAnimDir .rs 1 ; forward 00 l/r 01 backwards 02
moveAnimFlip .rs 1 ; facing right (00) or left (01)
moveAnimTargetX .rs 1
moveAnimTargetY .rs 1
showAnimSpriteFlag .rs 1

showEggSpriteFlag .rs 1 ; for the animation when a chicken shoots egg
eggAnimOffset .rs 1 ; should appear to do an arc
eggAnimYVelocity .rs 1 ; used to create the arc

	.rsset $03a0
AINearestEnemyUnitToFarmer .rs 1
NearestUnitToFarmerType    .rs 1

;FULL RESERVED FOR MAP AND UNIT DATA
	.rsset $0400 ; Hey 400 page is full, dont add anything more here
MapData .rs 192 ; the whole mapa xD

p1PiecesX    .rs 8
p1PiecesY    .rs 8
p1PiecesType .rs 8
p1PiecesRes  .rs 8

p2PiecesX    .rs 8
p2PiecesY    .rs 8
p2PiecesType .rs 8
p2PiecesRes  .rs 8

	.rsset $0500
p1Gold .rs 1
p2Gold .rs 1
p1Kills .rs 1
p2Kills .rs 1
p1Deaths .rs 1
p2Deaths .rs 1
p1FarmCount .rs 1
p2FarmCount .rs 1

Hex0 .rs 1
DecOnes .rs 1
DecTens .rs 1
DecHundreds .rs 1

validMovesCount .rs 1
validMovesX .rs 32
validMovesY .rs 32

	.rsset $05fe
tileBufferLength .rs 1
tileBufferIndex  .rs 1

; RESERVED FOR TILE BUFFERING
	.rsset $0600
tileBuffer .rs 64

	.rsset $0700
attributesBuffer   .rs 64
stringBufferLength .rs 1
stringBufferIndex  .rs 1
stringBuffer       .rs 32

JOYPAD1 = $4016
JOYPAD2 = $4017

MAP_WIDTH  = $10
MAP_DRAW_Y = $03
MAX_METATILE_CHANGES = $03 ; per frame, 8 tiles per frame

; in the metatile data
P1_UNITS_START_OFFSET = $04
P2_UNITS_START_OFFSET = $11

SEASONS_LENGTH_IN_TURNS = $01 ; 3 usually for now

TILE_WATER = $00
TILE_TREES = $01
TILE_GRASS = $02
TILE_FARM  = $03

GUIMODE_PAUSED    = $00
GUIMODE_MAIN      = $01
GUIMODE_GAMEOVER  = $0f
GUIMODE_DEBUGMENU = $10
GUIMODE_AIDECIDE  = $11

;----- first 8k bank of PRG-ROM    
    .bank 0
    .org $C000
    
irq:
nmi:

	pha
    txa
    pha
    tya
    pha

	lda #%00010000   ; turning off NMI while non-drawing stuff happens
	sta $2000

RefreshHotbarText:
	lda hotbarTextNeedsRefresh
	cmp #$01
	bne TileBufferHandler
	
	lda #$20
	sta $2006
	lda #$83
	sta $2006
	ldx #$00
RefreshHotbarTextLoop:
	lda stringBuffer, x
	sta $2007
	inx
	cpx #$1a
	bne RefreshHotbarTextLoop
	
	lda #$00
	sta hotbarTextNeedsRefresh
	
TileBufferHandler:

	ldx #$00 ; empty buffer means skip tile buffer handling
	cpx tileBufferLength
	beq TileBufferHandlerDone
	
	lda tileBufferIndex ;param5 is pointer+max metatile changes
	clc
	adc #MAX_METATILE_CHANGES
	sta param5
	
	ldx tileBufferIndex
TileBufferLoop:

	stx param4
	asl param4
	asl param4 ; param4 has the index of the buffer item times 4, cus each one is 4 bytes
	
	ldy param4
	lda tileBuffer, y
	sta param1 ; tile id
	
	iny
	lda tileBuffer, y
	sta param2 ; tile x
	
	iny
	lda tileBuffer , y
	sta param3 ; tile y
	
	jsr drawTile
	
	lda param1
	cmp #$10 ; the bottom right corner tile (last to be added to the buffer for text boxes) triggers the text write)
	bne NoTextDraw
	jsr drawString
	
	lda strPPUAddress + 1
	cmp #$43
	bne NoTextDraw
	
	lda #$01
	sta hotbarTextNeedsRefresh

NoTextDraw:
	inx
	inc tileBufferIndex
	
	cpx tileBufferLength
	bcs TileBufferResetPointer
	
	cpx param5
	bne TileBufferLoop
	jmp TileBufferHandlerDone
	
TileBufferResetPointer:
	lda #$00
	sta tileBufferLength
	sta tileBufferIndex
	
TileBufferHandlerDone:
	
	lda seasonPaletteChangeFlag
	cmp #$01
	bne DrawDone
	
	jsr changeSeasonPalette
	lda #$00
	sta seasonPaletteChangeFlag
	
DrawDone:
	lda #%00011110   ; enable sprites, enable background, no clipping on left side
	sta $2001
	lda #$00  ; no scrolling
	sta $2005
	sta $2005
	
	lda #$00
	sta $2003  
	lda #$02
	sta $4014 ; oam dma
	
	jsr drawSprites
	
	; buttons from the previous frame to be compared for new presses!
	lda buttons1
	sta prevButtons1
	lda buttons2
	sta prevButtons2

; This is from the nesdev wiki: http://wiki.nesdev.com/w/index.php/Controller_reading_code
ReadControllers:
    lda #$01
    sta JOYPAD1
    sta buttons2  ; player 2's buttons double as a ring counter
    lsr a         ; now A is 0
    sta JOYPAD1
ReadControllerLoop:
    lda JOYPAD1
    and #%00000011  ; ignore bits other than controller
    cmp #$01        ; Set carry if and only if nonzero
    rol buttons1    ; Carry -> bit 0; bit 7 -> Carry
    lda JOYPAD2     ; Repeat
    and #%00000011
    cmp #$01
    rol buttons2    ; Carry -> bit 0; bit 7 -> Carry
    bcc ReadControllerLoop
	
TurnScreenTimer:
	; Little timing based code for the turn indicator
	lda guiMode
	cmp #$07
	beq TurnScreenHandler
	cmp #$08
	beq TurnScreenHandler
	jmp TurnScreenTimerDone
	
TurnScreenHandler:
	
	dec turnAnimTimer

	lda turnAnimTimer
	cmp #$00
	bne TurnScreenTimerDone
	
TurnScreenHandlerClear:
	lda #$01
	cmp computerMustMakeMove
	beq TurnScreenHandlerComputerPlayer
	
TurnScreenHandlerHumanPlayer:
	lda #$01
	sta guiMode
	jmp TurnScreenHandlerUpdateScreen

TurnScreenHandlerComputerPlayer:
	lda #GUIMODE_AIDECIDE
	sta guiMode
	
TurnScreenHandlerUpdateScreen:
	jsr closeCurrentTextBox
	jsr updateHotbar
	
	; lda #$03   ; A center chunk of the screen gets refreshed at this time because of a GUI issue with opening multiple windows
	; sta param4
	; lda #$08
	; sta param5
	; lda #$05
	; sta param6
	; lda #$01
	; sta param7
	; jsr drawMapChunk

TurnScreenTimerDone:
HarvestScreenTimer:
	lda guiMode
	cmp #$0c
	beq HarvestTimerUpdate
	jmp HarvestScreenTimerDone
HarvestTimerUpdate:
	dec harvestAnimTimer
	lda harvestAnimTimer
	cmp #$00
	bne HarvestScreenTimerDone
	
	jsr closeCurrentTextBox
	
	jsr evaluateTurn
	
	lda #$00
	jsr FamiToneMusicPlay
	
HarvestScreenTimerDone:

EndTurnTimerUpdate:
	lda endTurnTimer
	cmp #$00
	beq EndTurnTimerTrigger
	cmp #$ff
	beq EndTurnTimerDone
	
	dec endTurnTimer
	jmp EndTurnTimerDone
	
EndTurnTimerTrigger:
	jsr endTurnTimerFinished
	
EndTurnTimerDone:
; Ai only does its update in guimode 11 (all buttons locked), and once nametable buffering finishes
AICheck:
	lda guiMode
	cmp #$11
	bne AiCheckDone
	
	lda tileBufferLength
	cmp #$00
	bne AiCheckDone
	
	jsr AiUpdate
	
AiCheckDone:
SetColorBars:
	lda #%00111110
	sta $2001

	jsr InputHandler
	
	lda #%00011110
	sta $2001	

	jsr FamiToneUpdate
	inc globalTick
	
	lda #%10010000   ; re enabling NMI now that game logic stuff is finished
	sta $2000
	
	pla            ; restore regs and exit
    tay
    pla
    tax
    pla
	
    rti

reset:
    sei	
    cld
	
vblankwait1:
	bit $2002
	bpl vblankwait1
	
clearmemLoop:
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    lda #$FE
    sta $0200, x
    inx
    bne clearmemLoop
	
vblankwait2:
	bit $2002
	bpl vblankwait2
	
	jsr clearScreen
	
EndInit:
	jsr initGlobal
	jsr initDebugMenu

	lda #$90
    sta $2000   ;enable NMIs
	
	lda #%00011110 ; background and sprites enabled
	sta $2001
	
forever:
    jmp forever
	
initGlobal:
	lda #$00 ; nmi disabled
	sta $2000
	lda #%00000110 ; background and sprites disabled
	sta $2001
	
	jsr clearScreen

	lda #$ff
	sta endTurnTimer
	
	; these have to be set or else the GUI glitches when trying to close a nonexistent gui lol
	sta activeGuiWidth
	sta activeGuiHeight
	lda #$05
	sta activeGuiX
	sta activeGuiY
	
	lda #$90 ; nmi enabled
	sta $2000
	lda #%00011110 ; background and sprites enabled
	sta $2001
	
	; initialize music!!
	lda #$01 ; ntsc
	ldx #LOW(song_music_data)
	ldy #HIGH(song_music_data)
	jsr FamiToneInit
	
	ldx #LOW(sounds)
	ldy #HIGH(sounds)
	jsr FamiToneSfxInit
	
	rts
	
initDebugMenu:
	lda #$10
	sta guiMode
	jsr openTextBox
	
	;lda #$01
	jsr FamiToneMusicStop
	
	rts
	
initGameState:
	lda #$10 ; nmi disabled
	sta $2000
	lda #%00000110 ; background and sprites disabled
	sta $2001
	
	lda globalTick ; globalTick and gameMode are Noah and his family, and the stack is the ark
	pha
	lda gameMode
	pha
	
	ldx #$00
clearNonEssentialMem: ; this is the flood
    lda #$00
    sta $0000, x
    ;sta $0300, x
    sta $0400, x
    sta $0500, x
    ;sta $0600, x
    sta $0700, x
    inx
    bne clearNonEssentialMem
	
	pla
	sta gameMode
	pla
	sta globalTick ; now only Noah and his family remain

	lda #$ff
	sta endTurnTimer

	jsr GenerateMap
	jsr drawMap
	
	lda #$01
	sta guiMode ; main guimode
	
	lda #$00
	sta season ; season is set to spring
	
	lda #$01
	sta turn
	
	lda #$04     ; player 1 farmer spawned
	sta param4
	sta param5
	lda #$00
	sta param6
	sta param7
	jsr placeUnit
	
	lda #$0b    ; player 2 farmer spawned
	sta param4
	lda #$06
	sta param5
	lda #$00
	sta param6
	lda #$01
	sta param7
	jsr placeUnit
	
	lda #$00
	jsr FamiToneMusicPlay
	
	jsr giveStartingMoney
	
	jsr checkIfHarvestTime
	
	lda #$90 ; nmi enabled
	sta $2000
	lda #%00011110 ; background and sprites enabled
	sta $2001
	
	rts
	
openTextBox:
	ldx guiMode

	lda GuiX, x
	sta activeGuiX
	sta param4
	
	lda GuiY, x
	sta activeGuiY
	sta param5
	
	lda GuiWidths, x
	sta activeGuiWidth
	sta param6
	
	lda GuiHeights, x
	sta activeGuiHeight
	sta param7
	
	lda GuiMenuSizes, x
	sta menuSize
	
	lda GuiPointerLow, x
    sta stringPtr
    lda GuiPointerHigh, x
    sta stringPtr+1
	
	lda #$00
	sta menuCursorPos
	
	lda #%00100000      ; high byte of ppu address
	sta strPPUAddress
	lda param5          ; high 2 bits of Y
	asl a               ; (times 2, because Y is in metatiles)
	lsr a
	lsr a
	lsr a
	ora strPPUAddress
	sta strPPUAddress
	
	lda #$00
	sta strPPUAddress+1
	lda param5         ; low 3 bits of Y
	asl a              ; (also times 2)
	asl a
	asl a
	asl a
	asl a
	asl a
	ora strPPUAddress+1
	sta strPPUAddress+1
	
	lda param4 ; all of X (times 2)
	asl a
	ora strPPUAddress+1
	clc
	adc #$02   ; just convention, but text on textboxes always starts two tiles to the right (gives room for a cursor)
	sta strPPUAddress+1
	
	jsr drawTextBox
	
	rts
	
closeCurrentTextBox:
	lda activeGuiX
	sta param4
	lda activeGuiY
	sta param5
	lda activeGuiWidth
	sta param6
	lda activeGuiHeight
	sta param7
	
	jsr drawMapChunk
	rts
	
player1TurnStart:

	lda #$80
	sta turnAnimTimer
	
	lda #$07
	sta guiMode
	jsr openTextBox
	
	rts
	
player2TurnStart:

	lda #$80
	sta turnAnimTimer
	
	lda #$08
	sta guiMode
	jsr openTextBox
	
	; gamemode 01 is the 2 player mode
	lda #$01
	cmp gameMode
	beq player2TurnStartDone
	
	lda #$01
	sta computerMustMakeMove
	
player2TurnStartDone:
	rts
	
; sets up for the animation of the unit moving, or whatever goes on this turn
endTurn:
	lda #$40
	sta endTurnTimer

	lda turn
	eor #$01
	clc
	adc #$07 ; 7 = player1 turn, 8 = player2 turn
			 ; this gets overwritten anyways lol, but it is there
	sta guiMode
	
	rts

endTurnTimerFinished:
	; this ensures it wont go off again
	lda #$ff
	sta endTurnTimer
	lda #$00
	sta showAnimSpriteFlag
	sta showEggSpriteFlag
	
	lda #$01
	sta <param6
	sta <param7
	lda <cursorX     ; draw unit in new place now that turn is finished
	sta <param4
	lda <cursorY
	clc
	adc #MAP_DRAW_Y
	sta <param5
	jsr drawMapChunk

	inc turnCount
	inc seasonTurnCounter
	
	jsr checkIfGameOver
	cmp #$ff
	beq endTurnNonGameover
	jmp endTurnGameover

endTurnNonGameover:
	lda seasonTurnCounter
	cmp #SEASONS_LENGTH_IN_TURNS
	bne checkIfHarvestTime
	
	lda #$00
	sta seasonTurnCounter
	lda #$01
	sta seasonPaletteChangeFlag
	
	inc season
	lda season
	and #$03
	sta season ; season cannot exceed 3

checkIfHarvestTime:
	lda season
	cmp #$00
	bne evaluateTurn
	
	lda seasonTurnCounter
	cmp #$00
	bne evaluateTurn
	
HarvestTime:
	lda #$0c
	sta guiMode
	jsr openTextBox
	
	jsr giveHarvestMoney
	
	lda #$04
	jsr FamiToneMusicPlay
	
	lda #$80
	sta harvestAnimTimer
	
	rts
	
evaluateTurn:
	lda turn
	cmp #$00
	beq p1EndTurn
	cmp #$01
	beq p2EndTurn
	rts	

p1EndTurn:
	lda #$01 ; now it's player 2's turn
	sta turn
	jsr player2TurnStart
	
	rts
	
p2EndTurn:
	lda #$00 ; now it's player 1's turn
	sta turn
	jsr player1TurnStart
	
	rts
	
endTurnGameover:
	lda #$04
	jsr FamiToneMusicPlay
	
	lda #GUIMODE_GAMEOVER
	sta guiMode
	jsr openTextBox
	
	rts
	
; A: ff if no game over, 00 if p1 game over, 01 if p2 game over
checkIfGameOver:
	; the first item in the units type array should be 00 (farmer) otherwise the farmer is gone (he cant be added bacK)
	lda p1PiecesType
	cmp #$00
	bne p1GameOverFlag
	
	lda p2PiecesType
	cmp #$00
	bne p2GameOverFlag
	
	; or if no units are present that also means no farmer
	lda p1UnitCount
	cmp #$00
	beq p1GameOverFlag
	
	lda p2UnitCount
	cmp #$00
	beq p2GameOverFlag
	
noGameOverFlag:	
	lda #$ff
	rts
	
p1GameOverFlag:
	lda #$00
	rts
	
p2GameOverFlag:
	lda #$01
	rts
	
	.include "ai.asm"
	.include "map.asm"
	.include "unit.asm"
	.include "draw.asm"
	.include "sprite.asm"
	.include "input.asm"
	
UnitHasCombinedAttackMove:
	.db $00, $00, $01
	
; first one is move range, second is attack range
UnitRanges:
FarmerRange:
	.db $01, $01
ChickenRange:
	.db $01, $02
CowRange:
	.db $02, $02
	
UnitPrices:
	.db $00, $02, $02
	
giveStartingMoney:
	lda gameMode
	cmp #$80
	bne giveStartingMoneyDone
	
	lda #99
	sta p1Gold
	sta p2Gold
	
giveStartingMoneyDone:
	rts
	
giveHarvestMoney:
	; Every farm gives 1 gold on harvest!
	lda p1Gold
	clc
	adc p1FarmCount
	sta p1Gold
	
	lda p2Gold
	clc
	adc p2FarmCount
	sta p2Gold
	
	rts
	
;----- second 8k bank of PRG-ROM    
    .bank 1
    .org $E000
	
; set to 1 if you want the color bars or 0 if you dont
BENCHMARK_MODE:
	.db $01
	
; The first four correspond to the map tile IDs
MetaTiles:
	.db $43, $43, $43, $43 ;water
	.db $62, $63, $72, $73 ;trees
	.db $41, $40, $40, $40 ;grass
	.db $42, $42, $42, $42 ;farm
	
; the next correspond to unit IDs
Player1UnitMetaTiles:
	.db $82, $83, $92, $93 ;farmer
	.db $80, $81, $90, $91 ;chicken
	.db $86, $87, $96, $97 ;cow(bull)
	.db $00, $00, $00, $00 ;reserved
	
TextBoxMetaTiles:
	.db $29, $2a, $39, $24 ; top left corner
	.db $2a, $2a, $24, $24 ; top side
	.db $2a, $2b, $24, $39 ; top right corner
	.db $39, $24, $39, $24 ; left side
	.db $24, $24, $24, $24 ; middle
	.db $24, $39, $24, $39 ; right side
	.db $39, $24, $3a, $2a ; bottom left corner
	.db $24, $24, $2a, $2a ; bottom side
	.db $24, $39, $2a, $3b ; bottom right corner
	
Player2UnitMetaTiles:
	.db $82, $83, $92, $93 ;farmer
	.db $80, $81, $90, $91 ;chicken
	.db $86, $87, $96, $97 ;cow(bull)
	.db $00, $00, $00, $00 ;reserved
	
BorderTiles: ; $15-16
	.db $51, $44, $40, $44 ; p1 border
	.db $45, $40, $45, $40 ; p2 border
	
WaterTiles: ; $17...
	.db $43, $43, $43, $43
	.db $43, $6c, $43, $6c
	.db $5b, $5b, $43, $43
	.db $5b, $5c, $43, $6c
	
	.db $6a, $43, $6a, $43
	.db $6a, $6c, $6a, $6c
	.db $5a, $5b, $6a, $43
	.db $5a, $5c, $6a, $6c
	
	.db $43, $43, $7b, $7b
	.db $43, $6c, $7b, $7c
	.db $5b, $5b, $7b, $7b
	.db $5b, $5c, $7b, $7c
	
	.db $6a, $43, $7a, $7b
	.db $6a, $6c, $7a, $7c
	.db $5a, $5b, $7a, $7b
	.db $5a, $5c, $7a, $7c
	
MetaTileAttributes:
	.db $00, $55, $55, $55 ; map tiles
	.db $aa, $aa, $aa, $aa ; player 1 tiles
	.db $00, $00, $00, $00, $00, $00, $00, $00, $00 ; textbox tiles
	.db $ff, $ff, $ff, $ff ; player 2 tiles
	.db $aa, $ff ; border tiles
	.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; 16 water tile possibles
	
MetaSpriteX:
	.db $00, $08, $00, $08
MetaSpriteY:
	.db $00, $00, $08, $08
	
MetaSprites:
	.db $90, $91, $a0, $a1
UnitMetaSprites:
UnitDeathMetaSprites:
	;death sprites first
	.db $00, $10, $00, $10 ;farmer NOT USED
	.db $60, $61, $70, $71 ;chicken
	.db $62, $63, $72, $73 ;cow
	
UnitMoveMetaSprites:
; farmer front move
	.db $40, $41, $50, $51
	.db $42, $43, $52, $53
; farmer side move
	.db $44, $45, $54, $55
	.db $46, $47, $56, $57
; farmer back move
	.db $48, $49, $58, $59
	.db $4a, $4b, $5a, $5b
; farmer reserved
	.db $00, $00, $00, $00
	.db $00, $00, $00, $00
	
; chicken front move
	.db $20, $21, $30, $31
	.db $22, $23, $32, $33
; chicken side move
	.db $20, $21, $30, $31
	.db $22, $23, $32, $33
; chicken back move
	.db $20, $21, $30, $31
	.db $22, $23, $32, $33
; chicken reserved
	.db $00, $00, $00, $00
	.db $00, $00, $00, $00

; cow front move
	.db $00, $01, $10, $11
	.db $02, $03, $12, $13
; cow side move
	.db $00, $01, $10, $11
	.db $02, $03, $12, $13
; cow back move
	.db $00, $01, $10, $11
	.db $02, $03, $12, $13
; cow reserved
	.db $00, $00, $00, $00
	.db $00, $00, $00, $00
		

IndicatorSpriteAnimation:
	.db $82, $83, $84, $83

dawnPalette:
	.db $29, $30, $11, $01, $29, $17, $08, $18, $29, $05, $27, $30, $29, $03, $24, $30
dayPalette:
	.db $2a, $30, $11, $01, $2a, $17, $0a, $1a, $2a, $05, $27, $30, $2a, $03, $24, $30
duskPalette:
	.db $28, $30, $0c, $0f, $28, $16, $07, $17, $28, $05, $27, $30, $28, $03, $24, $30
nightPalette:
	.db $12, $30, $0f, $0f, $12, $17, $0f, $02, $12, $05, $27, $30, $12, $03, $24, $30
	
duskPalette2:
	.db $26, $30, $0c, $0f, $26, $17, $0f, $16, $26, $05, $27, $30, $26, $03, $24, $30
duskPalette3:
	.db $14, $30, $0f, $0f, $14, $17, $0f, $04, $14, $05, $27, $30, $14, $03, $24, $30
	
winterPalette:
	.db $3c, $30, $11, $0f, $3c, $15, $0a, $2c, $3c, $05, $27, $30, $3c, $03, $24, $30
	
spritePalette:
	.db $2a, $05, $27, $30, $2a, $03, $24, $30, $2a, $0f, $30, $21, $2a, $14, $22, $34 ; sprites
	
text_TheLicc:
	.db $1d, $31, $2e, $24, $15, $32, $2c, $2c, $ff ; "THE LICC"
	
text_EngineTitle:	
	.db $1b, $1b, $28, $09, $27, $01, $08, $27, $02, $00, $02, $00, $ff ; rr.9/18/2020
	
text_Icle:
	.db $12, $0c, $15, $0e, $ff ; icle
	
text_BuildMenu:
	.db $0b, $1e, $12, $15, $0d, $fe, $1e, $17, $12, $1d, $fe, $0f, $0a, $1b, $16, $ff
	
text_UnitMenu:
	.db $1e, $17, $12, $1d, $fe, $0c, $11, $12, $0c, $14, $0e, $17, $24, $02, $10, $fe
	.db $0c, $18, $20, $24, $24, $24, $24, $24, $02, $10, $ff
	
text_Player1Turn:
	.db $2a, $fe, $19, $15, $0a, $22, $0e, $1b, $24, $01, $25, $1c, $24, $1d, $1e, $1b, $17, $26, $ff
	
text_Player2Turn:
	.db $2a, $fe, $19, $15, $0a, $22, $0e, $1b, $24, $02, $25, $1c, $24, $1d, $1e, $1b, $17, $26, $ff
	
text_FarmerMenu:
	.db $0f, $0a, $1b, $16, $0e, $1b, $fe, $16, $18, $1f, $0e, $ff
	
text_ChickenMenu:
	.db $0c, $11, $12, $0c, $14, $0e, $17, $fe, $16, $18, $1f, $0e, $fe, $0a, $1d, $1d, $0a, $0c, $14, $fe, $1b, $0e, $16, $18, $1f, $0e, $ff
	
text_CowMenu:
	.db $0c, $18, $20, $fe, $0c, $11, $0a, $1b, $10, $0e, $fe, $1b, $0e, $16, $18, $1f, $0e, $ff
	
text_Spring:
	.db $1c, $19, $1b, $12, $17, $10, $ff
	
text_Summer:
	.db $1c, $1e, $16, $16, $0e, $1b, $ff
	
text_Fall:
	.db $0f, $0a, $15, $15, $ff
	
text_Winter:
	.db $20, $12, $17, $1d, $0e, $1b, $ff
	
text_Harvest:
	.db $2a, $fe, $11, $0a, $1b, $1f, $0e, $1c, $1d, $26, $ff
text_Player1Win:
	.db $2a, $fe, $19, $15, $0a, $22, $0e, $1b, $24, $01, $24, $20, $12, $17, $1c, $26, $ff
text_Player2Win:
	.db $2a, $fe, $19, $15, $0a, $22, $0e, $1b, $24, $02, $24, $20, $12, $17, $1c, $26, $ff
	
text_DebugMenu:
	.db $2a, $fe, $0d, $0e, $0b, $1e, $10, $24, $01, $19, $fe, $01, $24, $19, $15, $0a, $22, $0e, $1b, $fe, $02, $24, $19, $15, $0a, $22, $0e, $1b, $ff
	
text_GameOverMenu:
	.db $2a, $fe, $19, $15, $0a, $22, $24, $0a, $10, $0a, $12, $17, $fe, $1a, $1e, $12, $1d, $ff
	
GuiX:
	;     0    1    2    3    4    5    6    7    8    9    a    b    c    d    e    f   10   11
	.db $01, $01, $03, $08, $05, $05, $05, $03, $03, $01, $01, $01, $05, $01, $01, $05, $06, $01
GuiY:
	.db $01, $01, $06, $06, $06, $06, $06, $06, $06, $01, $01, $01, $06, $01, $01, $08, $06, $01
GuiWidths:
	.db $01, $01, $05, $07, $05, $05, $05, $0a, $0a, $01, $01, $01, $06, $01, $01, $07, $07, $01
GuiHeights:
	.db $01, $01, $03, $03, $02, $04, $03, $02, $02, $01, $01, $01, $02, $01, $01, $03, $06, $01
GuiMenuSizes:
	.db $00, $00, $02, $02, $01, $03, $02, $00, $00, $00, $00, $00, $00, $01, $01, $02, $03, $00
	
GuiPointerLow:
	.db $00, LOW(text_EngineTitle), LOW(text_BuildMenu), LOW(text_UnitMenu), LOW(text_FarmerMenu), LOW(text_ChickenMenu), LOW(text_CowMenu), LOW(text_Player1Turn), LOW(text_Player2Turn), $00, $00, $00, LOW(text_Harvest), $00, $00, LOW(text_GameOverMenu), LOW(text_DebugMenu)

GuiPointerHigh:
	.db $00, HIGH(text_EngineTitle), HIGH(text_BuildMenu), HIGH(text_UnitMenu), HIGH(text_FarmerMenu), HIGH(text_ChickenMenu), HIGH(text_CowMenu), HIGH(text_Player1Turn), HIGH(text_Player2Turn), $00, $00, $00, HIGH(text_Harvest), $00, $00, HIGH(text_GameOverMenu), HIGH(text_DebugMenu)
	
Song:
	.db $7f, $20, $02, $25, $0c ; fantasia in funk
	.db $7f, $7f, $7f, $3f, $20, $02, $25, $0c 
	.db $3f, $09, $5f, $7f, $3f, $ff
	
SongNoise:
	.db $4f, $4f, $47, $4f, $ff ; kick kick snare kick
	
TheLicc:
	.db $02, $04, $05, $07 ; the licc (needs to be fixed, tempo values have yet changed)
	.db $24, $00, $02, $5f
	
	.include "song.asm"
	.include "sfx.asm"
	.include "famitone4.asm" ; Sound engine
	
	.include "bcd.asm" ; bcd converter
	
TileData:
	.db $1b, $0a, $0c, $12, $1c, $1d, $1c, $24, $11, $18, $16, $18, $19, $11, $18, $0b, $0e, $1c, $24, $1c, $0e, $21, $12, $1c, $1d, $1c, $24, $1d, $1b, $0a, $17, $1c, $19, $11, $18, $0b, $0e, $1c, $24, $10, $18, $24, $0a, $20, $0a, $22, $24, $0a, $17, $0d, $24, $0f, $12, $17, $0d, $24, $0a, $17, $18, $1d, $11, $0e, $1b, $24, $10, $0a, $16, $0e, $ff

	
;---- vectors
    .org $FFFA     ;first of the three vectors starts here
    .dw nmi        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
    .dw reset      ;when the processor first turns on or is reset, it will jump
                   ;to the label reset:
    .dw irq        ;external interrupt IRQ is not used in this tutorial
	
	.bank 2
    .org $0000
    .incbin "funtus.chr"