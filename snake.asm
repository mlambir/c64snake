BasicUpstart2(start)

.import source "input.asm"
.import source "screen_utils.asm"
.import source "screens.asm"
.import source "charset.asm"

* = $4000 "Main Program"
.const CHR_FRUIT = $E7
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

.const CHR_TAIL_LEFT = $F6
.const CHR_TAIL_RIGHT = $F5
.const CHR_TAIL_UP = $D7
.const CHR_TAIL_DOWN = $C7


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

score: .word $0000
record: .word $0000

timer: .word $0000

timer_irq:
	inc timer
	beq !done+
	inc timer+1
!done:
	asl $D019	//"Acknowledge" the interrupt by clearing the VIC's interrupt flag.
	jmp $EA31

start:
	//setup rng
	lda #$FF  //; maximum frequency value
	sta $D40E //; voice 3 frequency low byte
	sta $D40F //; voice 3 frequency high byte
	lda #$80  //; noise waveform, gate bit off
	sta $D412 //; voice 3 control register

	//setup irq
	lda #%01111111
	sta $DC0D	//"Switch off" interrupts signals from CIA-1
	and $D011
	sta $D011	//Clear most significant bit in VIC's raster register
	lda #0
	sta $D012	//Set the raster line number where interrupt should occur
	lda #<timer_irq
	sta $0314
	lda #>timer_irq
	sta $0315	//Set the interrupt vector to point to interrupt service routine below
	lda #%00000001
	sta $D01A	//Enable raster interrupt signals from VIC

	jmp game_start

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
	cmp #CHR_FRUIT
	bne no_fruit
	jsr eat_fruit
	rts
no_fruit:
	cmp #CLEAR_BYTE
	bne lost
	rts
lost:
	jmp game_start

eat_fruit:
	inc head_tail_offset
	inc score
	beq !carry+
	jmp !nocarry+
!carry:
	inc score+1
!nocarry:
	jsr update_record
	jsr display_record
	jsr display_score
	jsr add_random_fruit
	rts
	
update_record:
	lda score+1
	cmp record+1
	bcc !done+
	beq !equal+
	jmp !larger+
!equal:
	lda score
	cmp record
	bcc !done+
!larger:
	lda score
	sta record
	lda score+1
	sta record+1 
!done:
	rts

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

rand_1_39:
 	lda $D41B //get random value from 0-255
    cmp #(39 - 1 + 1)  //compare to U-L+1
    bcs rand_1_39   //branch if value > U-L+1
    adc #1  // add L
    rts

rand_3_24:
 	lda $D41B //get random value from 0-255
    cmp #(24 - 3 +1)  //compare to U-L+1
    bcs rand_3_24   //branch if value > U-L+1
    adc #3  // add L
    rts


rand_val_x: .byte 0
add_random_fruit:
	jsr rand_1_39
	tax
	jsr rand_3_24
	tay
	jsr read_x_y_to_a
	cmp #CLEAR_BYTE
	bne add_random_fruit
	lda #1
	jsr color_a_on_x_y
	lda #CHR_FRUIT
	jsr draw_a_on_x_y
	rts

div_lo: .byte 0
div_hi: .byte 0

div10: 
	ldx #$11 
	lda #$00 
	clc 
!loop:    
	rol 
    cmp #$0A 
    bcc !skip+
    sbc #$0A 
!skip:    
	rol div_hi 
	rol div_lo
    dex 
    bne !loop- 
    rts

display_score:
	ldx score+1 
	stx div_lo
	ldy score
	sty div_hi

	ldy #$04
!next:    
	jsr div10 
    ora #$30 
    sta $042f,y 
    dey 
    bpl !next- 
    rts

display_record:
	ldx record+1 
	stx div_lo
	ldy record
	sty div_hi
	ldy #$04
!next:    
	jsr div10 
    ora #$30 
    sta $044A,y 
    dey 
    bpl !next- 
    rts

display_timer:
	ldx timer+1 
	stx div_lo
	ldy timer
	sty div_hi
	ldy #$04
!next:    
	jsr div10 
    ora #$30 
    sta $0400,y 
    dey 
    bpl !next- 
    rts

game_start:
	jsr load_charset
	CopyScreen(game_screen, SCREEN_START)
	lda #15
	jsr clear_color
	lda #0
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

	lda #0
	sta score
	sta score+1
	
	jsr display_score
	jsr display_record

	jsr draw_head

	jsr add_random_fruit

game_loop:
	jsr display_timer

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
	ldx timer+1
	cpx #15
	bcc delay
	ldx #0
	stx timer
	stx timer+1
	rts
