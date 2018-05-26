BasicUpstart2(start)

.import source "input.asm"
.import source "screen_utils.asm"
.import source "screens.asm"
.import source "charset.asm"

* = $4000 "Main Program"
.const CHR_HEAD = $51
.const CHR_HEAD_UP = $D4
.const CHR_HEAD_DOWN = $F4
.const CHR_HEAD_LEFT = $C4
.const CHR_HEAD_RIGHT = $C6

.const CHR_BODY_UP_DOWN = $E4
.const CHR_BODY_LEFT_RIGHT = $C5
.const CHR_BODY_DOWN_RIGHT = $D5
.const CHR_BODY_DOWN_LEFT = $D6
.const CHR_BODY_UP_RIGHT = $E5
.const CHR_BODY_UP_LEFT = $E6

.const CHR_TAIL_LEFT = $f6
.const CHR_TAIL_RIGHT = $f5
.const CHR_TAIL_UP = $d7
.const CHR_TAIL_DOWN = $c7


.const DIR_UP = 0
.const DIR_DOWN = 1
.const DIR_LEFT = 2
.const DIR_RIGHT = 3

.const COLOR_BG = 11
.const COLOR_BORDER = 12
.const COLOR_SNAKE = 5

.const CLEAR_BYTE = $D1

body_x: .fill 256, 0
body_y: .fill 256, 0
body_dir: .fill 256, 0

head_position: .byte 0
tail_position: .byte 0 
head_tail_offset: .byte 0
last_tail_x: .byte 0
last_tail_y: .byte 0

last_dir: .byte DIR_UP
dir: .byte DIR_UP




start:
	jmp game_start

wait: 
	lda #$ff 
	cmp $d012 
	bne wait 
	rts

advance_body:
	//copy old position to new position
	ldx head_position
	ldy head_position
	inx
	stx head_position
	lda body_x,y
	sta body_x,x
	lda body_y,y
	sta body_y,x

	//store last tail position
	ldx tail_position
	lda body_x, x
	sta last_tail_x
	lda body_y, x
	sta last_tail_y

	//inc tail position if offset == 0 else decrease offset
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
	sta last_dir
	cmp #DIR_DOWN
	beq move_down
	cmp #DIR_RIGHT
	beq move_right
	cmp #DIR_LEFT
	beq move_left
move_up: //default
	jsr advance_body
	ldx head_position
	dec body_y, x
	jmp move_done
move_left:
	jsr advance_body
	ldx head_position
	dec body_x, x
	jmp move_done
move_right:
	jsr advance_body
	ldx head_position
	inc body_x, x
	jmp move_done
move_down:
	jsr advance_body
	ldx head_position
	inc body_y, x
	jmp move_done
move_done:
	ldx head_position
	lda dir
	sta body_dir, x
	rts


handle_input:
	jsr GetInput
	lda inputResult
	cmp #LEFT
	bne !next_key+
	lda last_dir
	cmp #DIR_RIGHT
	beq !next_key+
	lda #DIR_LEFT
	sta dir
!next_key:
	lda inputResult
	cmp #RIGHT
	bne !next_key+
	lda last_dir
	cmp #DIR_LEFT
	beq !next_key+
	lda #DIR_RIGHT
	sta dir
!next_key:
	lda inputResult
	cmp #UP
	bne !next_key+
	lda last_dir
	cmp #DIR_DOWN
	beq !next_key+
	lda #DIR_UP
	sta dir
!next_key:
	lda inputResult
	cmp #DOWN
	bne !next_key+
	lda last_dir
	cmp #DIR_UP
	beq !next_key+
	lda #DIR_DOWN
	sta dir
!next_key:
	rts

check_collisions:
	ldx head_position
	lda body_y, x
	tay
	lda body_x, x
	tax
	cpx #40
	bcs lost
	cpy #25
	bcs lost
	jsr read_x_y_to_a
	cmp #CLEAR_BYTE
	bne lost
	rts
lost:
	jmp game_start

draw_head:
	ldx head_position
	lda body_y, x
	tay
	lda body_x, x
	tax
	lda #COLOR_SNAKE
	jsr color_a_on_x_y
	
	//load head dir character into a
	lda dir
	cmp #DIR_LEFT
	bne !next_head_dir+
	lda #CHR_HEAD_LEFT
	jmp head_dir_done
!next_head_dir:
	cmp #DIR_RIGHT
	bne !next_head_dir+
	lda #CHR_HEAD_RIGHT
	jmp head_dir_done
!next_head_dir:
	cmp #DIR_DOWN
	bne !next_head_dir+
	lda #CHR_HEAD_DOWN
	jmp head_dir_done
!next_head_dir: //up - default
	lda #CHR_HEAD_UP
head_dir_done:
	jsr draw_a_on_x_y
	rts

body_char: .byte 0
draw_body:
	ldx head_position
	dex

	//load body dir character into a
	lda dir
	cmp #DIR_LEFT
	bne !next_head_dir+

	lda body_dir, x
	cmp #DIR_UP
	bne !next_last_dir+
	lda #CHR_BODY_DOWN_LEFT
	jmp body_dir_done
!next_last_dir:
	cmp #DIR_DOWN
	bne !next_last_dir+
	lda #CHR_BODY_UP_LEFT
	jmp body_dir_done
!next_last_dir:
	lda #CHR_BODY_LEFT_RIGHT
	jmp body_dir_done

!next_head_dir:
	cmp #DIR_RIGHT
	bne !next_head_dir+
	lda body_dir, x
	cmp #DIR_UP
	bne !next_last_dir+
	lda #CHR_BODY_DOWN_RIGHT
	jmp body_dir_done
!next_last_dir:
	cmp #DIR_DOWN
	bne !next_last_dir+
	lda #CHR_BODY_UP_RIGHT
	jmp body_dir_done
!next_last_dir:
	lda #CHR_BODY_LEFT_RIGHT
	jmp body_dir_done

!next_head_dir:
	cmp #DIR_DOWN
	bne !next_head_dir+
	lda body_dir, x
	cmp #DIR_LEFT
	bne !next_last_dir+
	lda #CHR_BODY_DOWN_RIGHT
	jmp body_dir_done
!next_last_dir:
	cmp #DIR_RIGHT
	bne !next_last_dir+
	lda #CHR_BODY_DOWN_LEFT
	jmp body_dir_done
!next_last_dir:
	lda #CHR_BODY_UP_DOWN
	jmp body_dir_done

!next_head_dir: //up - default
	lda body_dir, x
	cmp #DIR_LEFT
	bne !next_last_dir+
	lda #CHR_BODY_UP_RIGHT
	jmp body_dir_done
!next_last_dir:
	cmp #DIR_RIGHT
	bne !next_last_dir+
	lda #CHR_BODY_UP_LEFT
	jmp body_dir_done
!next_last_dir:
	lda #CHR_BODY_UP_DOWN
	jmp body_dir_done

body_dir_done:
	sta body_char
	ldx head_position
	dex
	lda body_y, x
	tay
	lda body_x, x
	tax
	lda body_char
	jsr draw_a_on_x_y
	rts

clear_tail:
	//clear tail
	ldx tail_position
	lda body_y, x
	cmp last_tail_y
	bne do_clear_tail
	lda body_x, x
	cmp last_tail_x
	bne do_clear_tail
	jmp dont_clear_tail
do_clear_tail:
	ldx last_tail_x
	ldy last_tail_y
	lda #CLEAR_BYTE
	jsr draw_a_on_x_y
dont_clear_tail:
	rts

tail_char: .byte 0
draw_tail:
	ldx tail_position
	inx
	lda body_dir, x
	cmp #DIR_LEFT
	bne !next_tail_dir+
	lda #CHR_TAIL_LEFT
	jmp do_draw_tail
!next_tail_dir:
	cmp #DIR_RIGHT
	bne !next_tail_dir+
	lda #CHR_TAIL_RIGHT
	jmp do_draw_tail
!next_tail_dir:
	cmp #DIR_DOWN
	bne !next_tail_dir+
	lda #CHR_TAIL_DOWN
	jmp do_draw_tail
!next_tail_dir:
	lda #CHR_TAIL_UP

do_draw_tail:
	sta tail_char
	ldx tail_position
	lda body_y, x
	tay
	lda body_x, x
	tax
	lda tail_char
	jsr draw_a_on_x_y
	rts

game_start:
	jsr load_charset
	CopyScreen(game_screen, SCREEN_START)
	lda #12
	sta FRAME_COLOR
	lda #11
	sta BACKGROUND_COLOR
	lda #0
	sta head_position
	sta tail_position
	lda #20
	sta body_x, x
	sta last_tail_x
	lda #12
	sta body_y, x
	sta last_tail_y
	lda #DIR_UP
	sta dir
	lda #5
	sta head_tail_offset
	
	jsr draw_head

game_loop:
	jsr handle_input
	jsr move
	jsr clear_tail
	jsr check_collisions
	jsr draw_head
	jsr draw_body
	jsr draw_tail
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