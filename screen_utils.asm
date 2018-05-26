.const FRAME_COLOR = $D020
.const BACKGROUND_COLOR = $D021
.const SCREEN_START = $0400
.const COLOR_START = $d800

.macro @ClearScreen(target, clearByte) {  
	ldx #0
	lda #clearByte
!loop:
	sta target,x
	sta target+$100,x
	sta target+$200,x
	sta target+40*25-$100,x
	inx
	bne !loop-
}

.macro @CopyScreen(source, target) {  
	ldx #0
!loop:
	lda source,x
	sta target,x
	lda source+$100,x
	sta target+$100,x
	lda source+$200,x
	sta target+$200,x
	lda source+40*25-$100,x
	sta target+40*25-$100,x
	inx
	bne !loop-
}

clear_screen:
	ClearScreen(SCREEN_START, ' ')
	rts

clear_color:
	ldx #0
!loop:
	sta COLOR_START,x
	sta COLOR_START+$100,x
	sta COLOR_START+$200,x
	sta COLOR_START+40*25-$100,x
	inx
	bne !loop-
	rts

pos: .word $0000
v_a: .byte 0
v_x: .byte 0
v_y: .byte 0

x_y_to_pos:
	sta v_a
	stx v_x
	sty v_y

	lda #>SCREEN_START
	sta pos+1
	//add x to pos
	stx pos

//add y*40 to pos
!loop:
	cpy #0
	beq !loop_done+
	dey
	clc
	lda pos
	adc #40
	sta pos
	lda pos+1
	adc #0
	sta pos+1
	jmp !loop-
!loop_done:
	rts


draw_a_on_x_y:
	jsr x_y_to_pos

	lda pos+1
	cmp #$05
	bcs !case05+
	ldx pos
	lda v_a
	sta SCREEN_START,x
	jmp !case_end+
!case05:
	lda pos+1
	cmp #$06
	bcs !case06+
	ldx pos
	lda v_a
	sta SCREEN_START+$0100,x
	jmp !case_end+
!case06:
	lda pos+1
	cmp #$07
	bcs !case07+
	ldx pos
	lda v_a
	sta SCREEN_START+$0200,x
	jmp !case_end+
!case07:
	lda pos+1
	cmp #$08
	bcs !case_end+
	ldx pos
	lda v_a
	sta SCREEN_START+$0300,x
!case_end:
	lda v_a
	ldx v_x
	ldy v_y
	rts

read_x_y_to_a:
	jsr x_y_to_pos

	lda pos+1
	cmp #$05
	bcs !case05+
	ldx pos
	lda SCREEN_START,x
	jmp !case_end+
!case05:
	cmp #$06
	bcs !case06+
	ldx pos
	lda SCREEN_START+$0100,x
	jmp !case_end+
!case06:
	cmp #$07
	bcs !case07+
	ldx pos
	lda SCREEN_START+$0200,x
	jmp !case_end+
!case07:
	ldx pos
	lda SCREEN_START+$0300,x
!case_end:
	ldx v_x
	ldy v_y
	rts

color_a_on_x_y:
	jsr x_y_to_pos

	lda pos+1
	cmp #$05
	bcs !case05+
	ldx pos
	lda v_a
	sta COLOR_START,x
	jmp !case_end+
!case05:
	lda pos+1
	cmp #$06
	bcs !case06+
	ldx pos
	lda v_a
	sta COLOR_START+$0100,x
	jmp !case_end+
!case06:
	lda pos+1
	cmp #$07
	bcs !case07+
	ldx pos
	lda v_a
	sta COLOR_START+$0200,x
	jmp !case_end+
!case07:
	lda pos+1
	cmp #$08
	bcs !case_end+
	ldx pos
	lda v_a
	sta COLOR_START+$0300,x
!case_end:
	lda v_a
	ldx v_x
	ldy v_y
	rts