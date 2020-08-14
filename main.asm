    .inesprg 1 ;1x 16kb PRG code
    .ineschr 1 ;1x 8kb CHR data
    .inesmap 0 ; mapper 0 = NROM, no bank swapping
    .inesmir 1 ;background mirroring (vertical mirroring = horizontal scrolling)

	.rsset $0000
param1 .rs 1 ; local parameters for functions when you cant use a register
param2 .rs 1
param3 .rs 1
param4 .rs 1
param5 .rs 1
param6 .rs 1
param7 .rs 1
param8 .rs 1
param9 .rs 1
	
globalTick .rs 1 ; For everything

; read the docs on this one lol... It Means Many Things
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
tilePPUAddress .rs 2 ; ditto as above but for tile changes

teste .rs 2 ; my trusty logger. Now it's a big boy and it can log pointers too.
cursorX .rs 1
cursorY .rs 1

buttons1 .rs 1
buttons2 .rs 1

	.rsset $0100
tileBufferLength .rs 1
tileBufferIndex  .rs 1
tileBuffer .rs 64

	.rsset $0400
MapData .rs 192 ; the whole mapa xD

p1PiecesX    .rs 8
p2PiecesX    .rs 8
p1PiecesY    .rs 8
p2PiecesY    .rs 8
p1PiecesType .rs 8
p2PiecesType .rs 8

	.rsset $0500
p1UnitCount .rs 1
p2UnitCount .rs 1
p1Gold .rs 1
p2Gold .rs 1

	.rsset $0700
attributesBuffer .rs 64

JOYPAD1 = $4016
JOYPAD2 = $4017
MAP_DRAW_Y = $03

MAX_METATILE_CHANGES = $03 ; per frame, 12 tiles per frame

;----- first 8k bank of PRG-ROM    
    .bank 0
    .org $C000
    
irq:
nmi:
	
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
	
	jsr drawCursor

DrawDone:
	lda #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	sta $2000
	lda #%00011110   ; enable sprites, enable background, no clipping on left side
	sta $2001
	lda #$00  ; no scrolling
	sta $2005
	sta $2005
	
	lda #$00
	sta $2003  
	lda #$02
	sta $4014 ; oam dma

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
	
InputHandler:
	lda globalTick
	and #$03
	cmp #$00
	beq InputB
	jmp InputHandlerDone
	
InputB:
	lda buttons1
	and #$40
	cmp #$40
	bne InputBDone
	
	lda tileBufferLength
	cmp #$00
	bne InputBDone
	
	lda #$01
	sta guiMode
	jsr closeCurrentTextBox

InputBDone:
InputA:
	lda buttons1
	and #$80
	cmp #$80
	bne InputADone
	
	lda tileBufferLength
	cmp #$00
	bne InputADone
	
	lda guiMode
	cmp #$00
	beq InputAPauseScreen
	cmp #$01
	beq InputAMainScreen
	cmp #$02
	beq InputABuildScreen
	jmp InputADone
	
InputAMainScreen:
	lda #$02
	sta guiMode
	jsr textboxBuildOpen
	jmp InputADone
	
InputAPauseScreen:
	jmp InputADone
	
InputABuildScreen:
	jmp InputADone
	
	;                ; this code adds a farm tile directly to the gfx buffer (DOESNT EDIT THE MAP)
	; lda #$03
	; sta tileBuffer
	; lda #$01
	; sta tileBufferLength
	; lda cursorX
	; sta tileBuffer + 1
	; lda cursorY
	; clc
	; adc #$03
	; sta tileBuffer + 2
	
InputADone:
InputRight:
	lda buttons1
	and #$01
	cmp #$01
	bne InputRightDone
	inc cursorX
	lda cursorX
	and #$0f
	sta cursorX
InputRightDone:
InputLeft:
	lda buttons1
	and #$02
	cmp #$02
	bne InputLeftDone
	dec cursorX
	lda cursorX
	and #$0f
	sta cursorX
InputLeftDone:
InputUp:
	lda buttons1
	and #$08
	cmp #$08
	bne InputUpDone
	dec cursorY
	lda cursorY
	cmp #$0c
	bcc InputUpDone
	lda #$0b
	sta cursorY
InputUpDone:
InputDown:
	lda buttons1
	and #$04
	cmp #$04
	bne InputDownDone
	inc cursorY
	lda cursorY
	cmp #$0c
	bcc InputDownDone
	lda #$00
	sta cursorY
InputDownDone:

InputHandlerDone:

	jsr FamiToneUpdate
	inc globalTick
	
    rti

reset:
    sei	
    cld
	
vblankwait1:
	bit $2002
	bpl vblankwait1
	
clearmem:
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
    bne clearmem
	
vblankwait2:
	bit $2002
	bpl vblankwait2
	
initPalette:
	lda $2002
	lda #$3F
	sta $2006   
	lda #$00
	sta $2006    
	ldx #$00
paletteLoop:
	lda BackgroundPalette, x
	sta $2007
	inx
	cpx #$20
	bne paletteLoop
	
	jsr clearScreen
	
	ldx #$00
initCursorSprite:
	lda CursorSpriteData, x
	sta $0200, x
	inx
	cpx #$10
	bne initCursorSprite
	
	ldx #$c0
CopyMapLoop:
	lda testMap, x
	sta MapData, x
	dex
	bne CopyMapLoop
	
TextBoxTest:
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
	
EndInit:
	jsr initGameState
	jsr drawMap

	lda #$90
    sta $2000   ;enable NMIs
	
	lda #%00011110 ; background and sprites enabled
	lda $2001
	
	lda #$01 ; ntsc
	ldx #LOW(song_music_data)
	ldy #HIGH(song_music_data)
	jsr FamiToneInit
	
	lda #$00
	jsr FamiToneMusicPlay
	
forever:
    jmp forever

; no arguments, fills both nametables with 24 (blank blue character). bulk drawing only! wayyy too much for vblank!	
clearScreen:
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
	
initGameState:
	lda #$01
	sta guiMode
	
	; these have to be set or else the GUI glitches when trying to close a nonexistent gui lol
	sta activeGuiWidth
	sta activeGuiHeight
	lda #$05
	sta activeGuiX
	sta activeGuiY
	rts
	
textboxBuildOpen:
	lda #$05
	sta param4
	sta param5
	sta param6
	lda #$03
	sta param7
	jsr drawTextBox
	
	lda #LOW(text_BuildMenu)
    sta stringPtr
    lda #HIGH(text_BuildMenu)
    sta stringPtr+1
	
	jsr initNewTextBox
	
	rts
	
initNewTextBox:
	lda param4
	sta activeGuiX
	lda param5
	sta activeGuiY
	lda param6
	sta activeGuiWidth
	lda param7
	sta activeGuiHeight
	
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
	
	.include "draw.asm"
	
;----- second 8k bank of PRG-ROM    
    .bank 1
    .org $E000
	
; The first four correspond to the map tile IDs
MetaTiles:
	.db $43, $43, $43, $43 ;water
	.db $60, $61, $70, $71 ;trees
	.db $40, $40, $40, $40 ;grass
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
	
MetaTileAttributes:
	.db $00, $55, $00, $55 ; map tiles
	.db $aa, $aa, $aa, $aa ; player 1 tiles
	.db $00, $00, $00, $00, $00, $00, $00, $00, $00 ; textbox tiles
	.db $ff, $ff, $ff, $ff ; player 2 tiles
	
testMap:
	;.db %01100110, %00100110, %01100110, %00100110
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
	
CursorSpriteData:
	.db $00, $80, %00000011, $00
	.db $00, $80, %01000011, $08  
	.db $08, $80, %10000011, $00 
	.db $08, $80, %11000011, $08 
	
BackgroundPalette:
	.db $2a, $30, $11, $38, $2a, $17, $0a, $1a, $2a, $05, $27, $30, $2a, $03, $24, $30 ; bg
	.db $2a, $15, $27, $30, $2a, $14, $24, $34, $2a, $14, $24, $34, $2a, $14, $24, $34 ; sprites
	
text_TheLicc:
	.db $1d, $31, $2e, $24, $15, $32, $2c, $2c, $ff ; "THE LICC"
	
text_EngineTitle:	
	.db $0f, $0a, $1b, $16, $24, $08, $27, $01, $03, $27, $02, $00, $02, $00, $ff ; farm 8/13/2020
	
text_Icle:
	.db $12, $0c, $15, $0e, $ff ; icle
	
text_BuildMenu:
	.db $0b, $1e, $12, $15, $0d, $fe, $1e, $17, $12, $1d, $fe, $0f, $0a, $1b, $16, $ff

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
	.include "famitone4.asm" ; Sound engine
	
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