    .inesprg 1 ;1x 16kb PRG code
    .ineschr 1 ;1x 8kb CHR data
    .inesmap 0 ; mapper 0 = NROM, no bank swapping
    .inesmir 1 ;background mirroring (vertical mirroring = horizontal scrolling)

	.rsset $0000
globalTick .rs 1 ; For everything
stringPtr  .rs 2 ; Where's the string we're rendering
strPPUAddress .rs 2 ; What address will the string go to in the ppu

;----- first 8k bank of PRG-ROM    
    .bank 0
    .org $C000
	
	.include "song.asm"
	.include "famitone4.asm" ; Sound engine
    
irq:
nmi:
	
BlinkAnim:	;; Silly blink animation test
	lda #$00
	sta $0201 ; 201 and 205 are the addresses of the two tile index bytes of the head sprites
	sta $0205
	
	lda globalTick
	and #%00111111 ; Blinks every 64 frames for 8 frames
	cmp #$08
	bcs BlinkAnimDone
	
	lda #$01
	sta $0201
	sta $0205
	
BlinkAnimDone:

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
	
loadBG:
	lda $2002
	lda #$20
	sta $2006
	lda #$00
	sta $2006
	ldx #$00
BGLoop:
	lda #$42 ; 42 is just a stripey tile pattern ,lel
	sta $2007
	sta $2007
	sta $2007
	sta $2007
	inx
	cpx #$f0
	bne BGLoop ; Fills the whole screen with stripes
	
loadAttr:
	lda $2002   
	lda #$23
	sta $2006   
	lda #$C0
	sta $2006   
	ldx #$00
attrLoop:
	lda #$00 ; They're all zero! all of them! yay!
	sta $2007 
	inx
	cpx #$80
	bne attrLoop
	
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
	lda #$c3
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
	
PlayerSpriteData:
	.db $80, $00, $00, $80
	.db $80, $00, $40, $88  
	.db $88, $11, $00, $80 
	.db $88, $11, $40, $88 
	
BackgroundPalette:
	.db $2a, $30, $11, $1a, $2a, $06, $0a, $1a, $2a, $15, $27, $30, $2a, $13, $24, $30 ; bg
	.db $2b, $15, $27, $30, $04, $14, $24, $34, $04, $14, $24, $34, $04, $14, $24, $34 ; sprites
	
text_TheLicc:
	.db $1d, $31, $2e, $24, $15, $32, $2c, $2c, $ff ; "THE LICC"
	
text_EngineTitle:
	.db $0f, $0a, $16, $12, $1d, $18, $17, $0e, $24, $1d, $0e, $1c, $1d, $fe ; famitone test 
	
	.db $44, $0a, $17, $0d, $24, $18, $1d, $11, $0e, $1b, $24 ; (and other 
	.db $1e, $1d, $12, $15, $1c, $24, $15, $18, $15, $45, $fe ; utils lol)
	
	.db $0a, $0d, $10, $10, $0f, $13, $10, $10, $0f, $0a, $0f, $0a, $0f, $0a, $0f  ; "adggfjggfafafafa 7/31/2020"
	.db $0a, $24, $07, $27, $03, $01, $27, $02, $00, $02, $00, $ff

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