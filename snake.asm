
.import source "input.asm"

.macro @ClearScreen(target, clearByte) {  
	ldx #0
	lda #clearByte
loop:
	sta target,x
	sta target+$100,x
	sta target+$200,x
	sta target+40*25-$100,x
	inx
	bne loop
}

.const CHR_HEAD = $51
.const SCREEN_START = $0400

head_x: .byte 10
head_y: .byte 10
tail_x: .byte 10
tail_y: .byte 11


BasicUpstart2(start)

wait: 
	lda #$ff 
	cmp $d012 
	bne wait 
	rts

start:
	ClearScreen(SCREEN_START, ' ')
	jmp game_loop


pos: .byte 0,0
v_a: .byte 0
v_x: .byte 0
v_y: .byte 0
draw_a_on_x_y:
run:
	sta v_a
	stx v_x
	sty v_y

	lda #>SCREEN_START
	sta pos+1
	//add x to pos
	stx pos

//add y*40 to pos
loop:
	cpy #0
	beq loop_done
	dey
	clc
	lda pos
	adc #40
	sta pos
	lda pos+1
	adc #0
	sta pos+1
	jmp loop
loop_done:
// write to "pos"
	lda pos+1
	cmp #$05
	bcs case05
	ldx pos
	lda v_a
	sta SCREEN_START,x
	jmp case_end
case05:
	lda pos+1
	cmp #$06
	bcs case06
	ldx pos
	lda v_a
	sta SCREEN_START+$0100,x
	jmp case_end
case06:
	lda pos+1
	cmp #$07
	bcs case07
	ldx pos
	lda v_a
	sta SCREEN_START+$0200,x
	jmp case_end
case07:
	lda pos+1
	cmp #$08
	bcs case_end
	ldx pos
	lda v_a
	sta SCREEN_START+$0300,x
case_end:
	rts


game_loop:
	jsr GetInput
	lda inputResult
	cmp #LEFT
	bne !next+
	ldx head_x
	cpx #0
	beq !next+
	ldy head_y
	lda #' '
	jsr draw_a_on_x_y
	ldx head_x
	dex
	stx head_x
	jmp keys_done
!next:
	lda inputResult
	cmp #RIGHT
	bne !next+
	ldx head_x
	cpx #39
	beq !next+
	ldy head_y
	lda #' '
	jsr draw_a_on_x_y
	ldx head_x
	inx
	stx head_x
	jmp keys_done
!next:
	lda inputResult
	cmp #UP
	bne !next+
	ldy head_y
	cpy #0
	beq !next+
	ldx head_x
	lda #' '
	jsr draw_a_on_x_y
	ldy head_y
	dey
	sty head_y
	jmp keys_done
!next:
	lda inputResult
	cmp #DOWN
	bne !next+
	ldy head_y
	cpy #24
	beq !next+
	ldx head_x
	lda #' '
	jsr draw_a_on_x_y
	ldy head_y
	iny
	sty head_y
	jmp keys_done
!next:
keys_done:
	ldx head_x
	ldy head_y
	lda #CHR_HEAD
	jsr draw_a_on_x_y
	jsr wait
	jmp game_loop


