; IODemo.asm
; Produces a "bouncing" animation on the LEDs.
; The LED pattern is initialized with the switch state.

ORG 0

	; Get and store the switch values
	IN     Switches
	OUT    LEDs
	JUMP   0



; IO address constants
Switches:  EQU 000
LEDs:      EQU 020
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005


