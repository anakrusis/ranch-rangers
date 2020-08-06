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
	
globalTick .rs 1 ; For everything
guiMode .rs 1 
; guide:
; 00 = no windows open
; 01 = farm/unit screen
; 02 = unit selection screen (cow, chicken)

stringPtr  .rs 2 ; Where's the string we're rendering
strPPUAddress .rs 2 ; What address will the string go to in the ppu
currentMapByte .rs 1 ; what byte is being parsed of the map right now
teste .rs 2 ; my trusty logger. Now it's a big boy and it can log pointers too.
cursorX .rs 1
cursorY .rs 1

buttons1 .rs 1
buttons2 .rs 1

	.rsset $0100
tileBufferLength .rs 1
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

JOYPAD1 = $4016
JOYPAD2 = $4017
MAP_DRAW_Y = $03

MAX_METATILE_CHANGES = $08 ; per frame, 32 tiles per frame

;----- first 8k bank of PRG-ROM    
    .bank 0
    .org $C000
	
	.include "song.asm"
	.include "famitone4.asm" ; Sound engine
    
irq:
nmi:
TileBufferHandler:
	ldx #$00
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
	
	inx
	cpx #MAX_METATILE_CHANGES
	bne TileBufferLoop

DrawCursor:
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
	adc #MAP_DRAW_Y ; position is offset by 3 metatiles by default
	asl a           ; multiplied by 16 (coarse)
	asl a
	asl a
	asl a
	sta $0200
	sta $0204
	clc
	adc #$08
	sta $0208
	sta $020c

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
	bne InputHandlerDone

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
	
	jsr drawMap
	
TextBoxTest:
	lda #$00
	sta param4
	lda #$01
	sta param5
	lda #$10
	sta param6
	lda #$02
	sta param7
	
	jsr drawTextBox
	
StringTest:
	lda #$20
	sta strPPUAddress
	lda #$61
	sta strPPUAddress + 1
	
	lda #LOW(text_EngineTitle)
    sta stringPtr
    lda #HIGH(text_EngineTitle)
    sta stringPtr+1
	
	jsr drawString
	
EndInit:
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

; no arguments, fills the first nametable with 24 (blank blue character)	
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
	cpx #$ff
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
	cpx #$80
	bne attrLoop
	
	rts

; tile type in param1, X and Y position of tile in param2 and param3
; you should only call this during vblank or while bulk drawing with ppu off
drawTile:
	tya ; This is Y clobber prevention so that you can keep using Y to do other things if you like.
	pha

	lda param2
	asl a ; x multiplied by 0x02
	sta param2
	
	lda #$00
	sta strPPUAddress
	lda param3
	sta strPPUAddress + 1
	
	asl strPPUAddress + 1 ; y multiplied by 0x40 (16 bit left shift six times)
	rol strPPUAddress
	asl strPPUAddress + 1
	rol strPPUAddress 
	asl strPPUAddress + 1 
	rol strPPUAddress
	asl strPPUAddress + 1
	rol strPPUAddress 
	asl strPPUAddress + 1
	rol strPPUAddress 
	asl strPPUAddress + 1
	rol strPPUAddress
	
	clc ; x and y are added together
	lda param2
	adc strPPUAddress + 1
	sta strPPUAddress + 1
	bcc addDone
	inc strPPUAddress
addDone:
	
	clc	; the sum of x and y are added to the value $20c0 which is the top part of the map screen
	lda strPPUAddress + 1
	adc #$00
	sta strPPUAddress + 1	
	
	lda strPPUAddress
	adc #$20			
	sta strPPUAddress
	
drawTileTop:
	lda $2002
	lda strPPUAddress
	sta $2006
	lda strPPUAddress + 1
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
	lda strPPUAddress + 1
	adc #$20
	sta strPPUAddress + 1
	
	bcc drawTileBottom
	inc strPPUAddress
	
drawTileBottom:
	lda $2002
	lda strPPUAddress
	sta $2006
	lda strPPUAddress + 1
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
	
; no arguments, draws the entire map
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
	
drawUnits:
	
	ldx #$00
unitDrawLoop:
	
	
	rts
	
; this is like a bulk drawing version of something which will be done with a buffer soon
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
	
	sta param1
	stx param2
	sty param3
	jsr drawTile
	
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
	sta teste
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

drawString:
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
	rts
	
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
UnitMetaTiles:
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
	
testMap:
	;.db %01100110, %00100110, %01100110, %00100110
	.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $02, $02, $00, $00, $00, $02, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00, $00, $00, $00, $00
	.db $00, $00, $02, $02, $02, $02, $01, $02, $02, $02, $02, $02, $02, $00, $00, $00
	.db $00, $02, $02, $02, $02, $02, $02, $01, $02, $02, $02, $02, $02, $02, $00, $00
	.db $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00
	.db $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00
	.db $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00
	.db $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $01, $02, $02, $00, $00, $00
	.db $00, $00, $00, $02, $02, $02, $02, $02, $00, $00, $02, $02, $00, $00, $00, $00
	.db $00, $00, $00, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	
CursorSpriteData:
	.db $00, $80, %00000011, $00
	.db $00, $80, %01000011, $08  
	.db $08, $80, %10000011, $00 
	.db $08, $80, %11000011, $08 
	
BackgroundPalette:
	.db $2a, $30, $11, $1a, $2a, $06, $0a, $1a, $2a, $15, $27, $30, $2a, $13, $24, $30 ; bg
	.db $2a, $15, $27, $30, $2a, $14, $24, $34, $2a, $14, $24, $34, $2a, $14, $24, $34 ; sprites
	
text_TheLicc:
	.db $1d, $31, $2e, $24, $15, $32, $2c, $2c, $ff ; "THE LICC"
	
text_EngineTitle:	
	.db $0f, $0a, $1b, $16, $24, $08, $27, $06, $27, $02, $00, $02, $00, $ff ; farm 8/6/2020

Song:
	.db $7f, $20, $02, $25, $0c ; fantasia in funk
	.db $7f, $7f, $7f, $3f, $20, $02, $25, $0c 
	.db $3f, $09, $5f, $7f, $3f, $ff
	
SongNoise:
	.db $4f, $4f, $47, $4f, $ff ; kick kick snare kick
	
TheLicc:
	.db $02, $04, $05, $07 ; the licc (needs to be fixed, tempo values have yet changed)
	.db $24, $00, $02, $5f
	
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