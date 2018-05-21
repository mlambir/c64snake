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

.const CLEAR_BYTE = ' '

body_x: .fill 256, 0
body_y: .fill 256, 0
head_position: .byte 0
tail_position: .byte 0 
head_tail_offset: .byte 0

dir: .byte DIR_UP


BasicUpstart2(start)

start:
	jmp game_start
wait: 
	lda #$ff 
	cmp $d012 
	bne wait 
	rts


pos: .word $0000
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

advance_body:
	ldx head_position
	ldy head_position
	inx
	stx head_position
	lda body_x,y
	sta body_x,x
	lda body_y,y
	sta body_y,x

	ldx head_tail_offset
	cpx #0
	bne dec_offset
	ldx tail_position
	inx
	stx tail_position
	jmp advance_done
dec_offset:
	dex
	stx head_tail_offset
advance_done:
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
	jmp move_done
move_left:
	ldx head_position
	lda body_x, x
	cmp #0
	beq move_done
	jsr advance_body
	ldx head_position
	dec body_x, x
	jmp move_done
move_right:
	ldx head_position
	lda body_x, x
	cmp #39
	beq move_done
	jsr advance_body
	ldx head_position
	inc body_x, x
	jmp move_done
move_up:
	ldx head_position
	lda body_y, x
	cmp #0
	beq move_done
	jsr advance_body
	ldx head_position
	dec body_y, x
	jmp move_done
move_down:
	ldx head_position
	lda body_y, x
	cmp #24
	beq move_done
	jsr advance_body
	ldx head_position
	inc body_y, x
	jmp move_done
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

game_start:
	ClearScreen(SCREEN_START, CLEAR_BYTE)
	lda #0
	sta head_position
	stx head_position
	lda #20
	sta body_x, x
	lda #12
	sta body_y, x
	lda #DIR_UP
	sta dir
	lda #10
	sta head_tail_offset
game_loop:
	jsr handle_input
	
	ldx tail_position
	lda body_y, x
	tay
	lda body_x, x
	tax
	lda #CLEAR_BYTE
	jsr draw_a_on_x_y

	jsr move
	
	ldx head_position
	lda body_y, x
	tay
	lda body_x, x
	tax
	lda #CHR_HEAD
	jsr draw_a_on_x_y
	
	ldx #$55
	jsr delay

	jmp game_loop


delay:
	ldy #0
yloop:
	dey
	bne yloop
	dex
	bne delay
	rts