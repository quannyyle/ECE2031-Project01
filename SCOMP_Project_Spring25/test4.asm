; IODemo.asm
; Produces a "bouncing" animation on the LEDs.
; The LED pattern is initialized with the switch state.

ORG 0

	; Get and store the switch values
Begin:
	IN  Switches
	Out Hex0
    Out LEDs
    Jump Begin
; Constants 
Pattern: DW  0
One: DW 1 
Counter: DW 10 ; Shifting 10 times for all active switches 
Count: DW 0 ;Position counter
Value: DW 4 
; IO address constants
Switches:  EQU 000
LEDs:      EQU 020
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005

