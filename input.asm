.const keyPressed = $cb 	// scnkey puts code of held key here.

.const UP = $09 			// w
.const LEFT = $0A 			// a
.const DOWN = $0D	 		// s
.const RIGHT = $12	 		// d

.const FIRE = $3D			// space

.const NOKEY = 64
.const NOINPUT = 253		// no input detected

// ------------------------------------------------------

// this routine will scan keyboard first and then the joystick
// but only if there was no input from the keyboard
// it will leave the detected input in inputResult
GetInput:
	jsr GetKeyInput
	lda inputResult
	cmp #NOINPUT
	bne !skip+
	jsr GetJoyInput
!skip:
	rts

// ------------------------------------------------------

// this subroutine gets keyboard input
// only one key at a time is registered
// "inputResult" will hold the registered input
// and accumulator as well

GetKeyInput:
	lda keyPressed 			// get held key code

	cmp #NOKEY
	bne !skip+
	lda #NOINPUT 			// yes
!skip:
	sta inputResult
	rts

// -------------------------------------------------

// this subroutine checks for joystick input from port 2
// the input register is rotated and the carry bit is checked
// we have only one joystick button, so UP is used for rotate CCW
// "inputResult" will hold the registered input

.const CIAPRA = $dc00 				// joystick port 2 input register
.const NOJOY  = $ff 				// value for no joy input

GetJoyInput:
!skip:
	lda CIAPRA
	cmp #NOJOY 				// same as noinput?
	bne !nextjoy+ 			// no, so go check the possiblities

	lda #NOINPUT 			// there is no input, store it
	sta inputResult 		// in result
	rts
!nextjoy:
	clc 					// clear the carry bit
	lsr 					// check bit 0: joy up
	bcs !nextjoy+
	lda #UP 		// store the correct code ...
	sta inputResult 		// as result
	rts
!nextjoy:
	lsr 					// check bit 1: joy down
	bcs !nextjoy+ 			// bit set means not pressed
	lda #DOWN
	sta inputResult
	rts
!nextjoy:
	lsr 					// check bit 2: joy left
	bcs !nextjoy+
	lda #LEFT
	sta inputResult
	rts
!nextjoy:
	lsr 					// check bit 3: joy right
	bcs !nextjoy+
	lda #RIGHT
	sta inputResult
	rts
!nextjoy:
	lsr 					// check bit 4: joy fire button
	bcs !exit+
	lda #FIRE
	sta inputResult
!exit:
	rts 					// those were all the relevant bits.
							// if we get to this, NOINPUT is still
							// stored in inputResult.

// ------------------------------------------------

// this byte holds the result of the input query
inputResult:
	.byte 0
