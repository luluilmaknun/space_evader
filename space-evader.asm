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

.def temp = r25

.org $00
  rjmp RESET

MAIN:
  rcall PRINT_BANNER
  rjmp forever

PRINT_BANNER:             ; void PRINT_BANNER()
  ldi r25, high(2*banner)
  ldi r24, low(2*banner)
  rcall WRITE_TEXT
  ret

RESET:                    ;init Stack Pointer
  ldi temp, low(RAMEND)
  out SPL, temp
  ldi temp, high(RAMEND)
  out SPH, temp
  rjmp INIT_IO

INIT_IO:
  rcall INIT_LCD
  ;rcall INIT_LED
  ;rcall INIT_BUTTON
  ;rcall INIT_INTERRUPT
  rjmp MAIN

INIT_LCD:
  push temp
	cbi PORTA,1	   ; CLR RS
	ldi temp,0x38	 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN
	rcall WAIT_LCD
	cbi PORTA,1	   ; CLR RS
	ldi temp,0x0E	 ; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN
	rcall WAIT_LCD
	cbi PORTA,1	   ; CLR RS
	ldi temp,0x06  ; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN
	rcall WAIT_LCD
  rcall CLEAR_LCD
  pop temp
	ret

WAIT_LCD:   ; delay ... adjustable by modifying hierarchical counters
  push r25
  push r24
  push r23

	ldi  r25, 255
	ldi  r24, 255
	ldi  r23, 255
cont:
  dec  r25
  brne cont
  ldi  r25, 2
  dec  r24
	brne cont
  ldi  r24, 2
  dec  r23
  brne cont
  ldi  r23, 2

  pop r23
  pop r24
  pop r25
  ret

CLEAR_LCD:
  push temp
	cbi PORTA,1	   ; CLR RS
	ldi temp, 0x01 ; MOV DATA,0x01
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN
	rcall WAIT_LCD
  pop temp
	ret

WRITE_TEXT:         ; void WRITE_TEXT(char[] *r25:24)
  push r25
  push r24
	mov	ZH, r25      ; Load high part of byte address into ZH
	mov	ZL, r24      ; Load low part of byte address into ZL
loadbyte:
	lpm			         ; Load byte from program memory into r0

	tst	r0		       ; Check if we've reached the end of the message
	breq write_quit  ; If so, quit

	mov r25, r0      ; Put the character onto first argument
	rcall WRITE_CHAR
	adiw ZL,1		     ; Increase Z registers
	rjmp loadbyte
write_quit:
  pop r24
  pop r25
  ret

WRITE_CHAR:      ; void WRITE_CHAR(char r25)
	sbi PORTA,1    ; SETB RS
	out PORTB, r25
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN
	rcall WAIT_LCD
	ret

forever:
  rjmp forever

banner:
.db "SPACE INVADER", 0
