; This BCD conversion code is written by Celius:
; http://wiki.nesdev.com/w/index.php/HexToDecimal.8

HexToDecimal.8:
;Given: Hex value in Hex0
;Returns decimal value in DecOnes, DecTens, and DecHundreds.

	lda #$00
	sta DecOnes
	sta DecTens
	sta DecHundreds

	lda Hex0
	and #$0F
	tax
	lda HexDigit00Table,x
	sta DecOnes
	lda HexDigit01Table,x
	sta DecTens

	lda Hex0
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda HexDigit10Table,x
	clc
	adc DecOnes
	sta DecOnes
	lda HexDigit11Table,x
	adc DecTens
	sta DecTens
	lda HexDigit12Table,x
	sta DecHundreds

	clc
	ldx DecOnes
	lda DecimalSumsLow,x
	sta DecOnes
	

	lda DecimalSumsHigh,x
	adc DecTens
	tax
	lda DecimalSumsLow,x
	sta DecTens

	lda DecimalSumsHigh,x
	adc DecHundreds
	tax
	lda DecimalSumsLow,x
	sta DecHundreds			;118

	rts
	
HexDigit00Table:
HexDigit56Table:
DecimalSumsLow:
;55 bytes
	.db $0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$0,$1,$2,$3,$4,$5
	.db $6,$7,$8,$9,$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$0,$1
	.db $2,$3,$4,$5,$6,$7,$8,$9,$0,$1,$2,$3,$4,$5,$6,$7
	.db $8,$9,$0,$1,$2,$3,$4

HexDigit01Table:
HexDigit57Table:
DecimalSumsHigh:
;55 bytes
	.db $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$1,$1,$1,$1,$1,$1
	.db $1,$1,$1,$1,$2,$2,$2,$2,$2,$2,$2,$2,$2,$2,$3,$3
	.db $3,$3,$3,$3,$3,$3,$3,$3,$4,$4,$4,$4,$4,$4,$4,$4
	.db $4,$4,$5,$5,$5,$5,$5
	
HexDigit10Table:
	.db $0,$6,$2,$8,$4,$0,$6,$2,$8,$4,$0,$6,$2,$8,$4,$0

HexDigit11Table:
	.db $0,$1,$3,$4,$6,$8,$9,$1,$2,$4,$6,$7,$9,$0,$2,$4
	
HexDigit12Table:
	.db $0,$0,$0,$0,$0,$0,$0,$1,$1,$1,$1,$1,$1,$2,$2,$2