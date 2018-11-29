.include "m8515def.inc"

;***************************************************************************
;*
;* "space-evader"
;*
;* This is a simple game written for ATmega8515. You pilot a
;* space aircraft through a the yonder of space filled with meteorites.
;* 
;*
;* - Aditya Pratama - 1706039490
;* - Giovan Isa Musthofa - 1706040126
;* - Lulu Ilmaknun Qurotaini - 1706979341
;* 
;*
;***************************************************************************

.def temp = r16

RESET:                    ;init Stack Pointer
  ldi temp, low(RAMEND)
  out SPL, temp
  ldi temp, high(RAMEND)
  out SPH, temp

forever:
  rjmp forever
