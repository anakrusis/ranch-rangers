    .inesprg 1 ;1x 16kb PRG code
    .ineschr 1 ;1x 8kb CHR data
    .inesmap 0 ; mapper 0 = NROM, no bank swapping
    .inesmir 1 ;background mirroring (vertical mirroring = horizontal scrolling)

	.rsset $0000
param1 .rs 1 ; parameters for functions when you cant use a register
param2 .rs 1
param3 .rs 1
	
globalTick .rs 1 ; For everything
stringPtr  .rs 2 ; Where's the string we're rendering
strPPUAddress .rs 2 ; What address will the string go to in the ppu
currentMapByte .rs 1 ; what byte is being parsed of the map right now
teste .rs 2 ; my trusty logger

;----- first 8k bank of PRG-ROM    
    .bank 0
    .org $C000
	
	.include "song.asm"
	.include "famitone4.asm" ; Sound engine
    
irq:
nmi:

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
	;jsr drawMap
	
	jmp StringTest
	ldx #$00 ; Cute little test sprite!
SpriteTest:
	lda PlayerSpriteData, x
	sta $0200, x
	inx
	cpx #$10
	bne SpriteTest
	
StringTest:
	lda #$20
	sta strPPUAddress
	lda #$60
	sta strPPUAddress + 1
	
	lda #LOW(text_EngineTitle)
    sta stringPtr
    lda #HIGH(text_EngineTitle)
    sta stringPtr+1
	
	jsr drawString
	
	;lda #$00
	;sta param1
	;sta param2
	;sta param3
	;jsr drawTile
	
	;lda #$01
	;sta param1
	;sta param2
	;sta param3
	;jsr drawTile
	
	jsr drawMap
	
	
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
	
	;lda strPPUAddress + 1
	
	;lda strPPUAddress
	;sta teste
	;lda strPPUAddress + 1
	;sta teste + 1
	
	clc ; x and y are added together
	lda param2
	adc strPPUAddress + 1
	sta strPPUAddress + 1
	bcc addDone
	inc strPPUAddress
addDone:
	
	clc	; the sum of x and y are added to the value $20c0 which is the top part of the map screen
	lda strPPUAddress + 1
	adc #$c0
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
	sta param3
	
	jsr drawTile
	
	inx
	cpx #$c0
	bne mapByteLoop
	
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
	
MetaTiles:
	.db $43, $43, $43, $43
	.db $60, $61, $70, $71
	.db $40, $40, $40, $40
	.db $42, $42, $42, $42
	
MapData:
	;.db %01100110, %00100110, %01100110, %00100110
	.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $02, $02, $00, $00, $00, $02, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00, $00, $00, $00, $00
	.db $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00, $00, $00
	.db $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00, $00
	.db $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00
	.db $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00
	.db $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00
	.db $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00, $00, $00
	.db $00, $00, $00, $02, $02, $02, $02, $02, $00, $00, $02, $02, $00, $00, $00, $00
	.db $00, $00, $00, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	
PlayerSpriteData:
	.db $80, $00, $00, $80
	.db $80, $00, $40, $88  
	.db $88, $11, $00, $80 
	.db $88, $11, $40, $88 
	
BackgroundPalette:
	.db $2a, $30, $11, $1a, $2a, $06, $0a, $1a, $2a, $15, $27, $30, $2a, $13, $24, $30 ; bg
	.db $2a, $15, $27, $30, $2a, $14, $24, $34, $2a, $14, $24, $34, $2a, $14, $24, $34 ; sprites
	
text_TheLicc:
	.db $1d, $31, $2e, $24, $15, $32, $2c, $2c, $ff ; "THE LICC"
	
text_EngineTitle:	
	.db $0a, $0d, $10, $10, $0f, $13, $10, $10, $0f, $0a, $0f, $0a, $0f, $0a, $0f  ; "adggfjggfafafafa 7/31/2020"
	.db $0a, $24, $08, $27, $04, $27, $02, $00, $02, $00, $ff

Song:
	.db $7f, $20, $02, $25, $0c ; fantasia in funk
	.db $7f, $7f, $7f, $3f, $20, $02, $25, $0c 
	.db $3f, $09, $5f, $7f, $3f, $ff
	
SongNoise:
	.db $4f, $4f, $47, $4f, $ff ; kick kick snare kick
	
TheLicc:
	.db $02, $04, $05, $07 ; the licc (needs to be fixed, tempo values have yet changed)
	.db $24, $00, $02, $5f
	
FreqLookupTbl:
	.db $ab, $09, $93, $09 ; C-3, C#3  0, 1
	.db $7c, $09, $67, $09 ; D-3, D#3  2, 3
	.db $52, $09, $3f, $09 ; E-3, F-3  4, 5
	.db $2d, $09, $1c, $09 ; F#3, G-3  6, 7
	.db $0c, $09, $fd, $08 ; G#3, A-3  8, 9
	.db $ef, $08, $e1, $08 ; A#3, B-3  a, b
	.db $d5, $08, $c9, $08 ; C-4, C#4  c, d
	.db $bd, $08, $00, $00 ; D-4, D#4  e, f
	.db $a9, $08, $9f, $08 ; E-4, F-4  10,11
	
NoteLenLookupTbl:
	.db $06, $0a, $10, $20 ; 1 and 0 together make swung eight notes, 2 a quarter note, and 3 is a half note
	
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