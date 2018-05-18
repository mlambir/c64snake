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
.const DIR_UP = 0
.const DIR_DOWN = 1
.const DIR_LEFT = 2
.const DIR_RIGHT = 3

head_x: .byte 10
head_y: .byte 10
tail_x: .byte 10
tail_y: .byte 11
dir: .byte DIR_UP


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

move:
	lda dir
	cmp #DIR_UP
	beq move_up
	cmp #DIR_DOWN
	beq move_down
	cmp #DIR_LEFT
	beq move_left
	cmp #DIR_RIGHT
	beq move_right
	rts
move_left:
	ldx head_x
	cpx #0
	beq move_done
	dex
	stx head_x
	rts
move_right:
	ldx head_x
	cpx #39
	beq move_done
	inx
	stx head_x
	rts
move_up:
	ldy head_y
	cpy #0
	beq move_done
	dey
	sty head_y
	rts
move_down:
	ldy head_y
	cpy #24
	beq move_done
	iny
	sty head_y
	rts
move_done:
	rts


handle_input:
	jsr GetInput
	lda inputResult
	cmp #LEFT
	bne !next_key+
	lda #DIR_LEFT
	sta dir
!next_key:
	lda inputResult
	cmp #RIGHT
	bne !next_key+
	lda #DIR_RIGHT
	sta dir
!next_key:
	lda inputResult
	cmp #UP
	bne !next_key+
	lda #DIR_UP
	sta dir
!next_key:
	lda inputResult
	cmp #DOWN
	bne !next_key+
	lda #DIR_DOWN
	sta dir
!next_key:
	rts

game_loop:
	ldx head_x
	ldy head_y
	lda #' '
	jsr draw_a_on_x_y
	jsr handle_input
	jsr move
	ldx head_x
	ldy head_y
	lda #CHR_HEAD
	jsr draw_a_on_x_y
	jsr wait
	jmp game_loop