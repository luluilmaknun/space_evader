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
.def position = r18

.org $00
  rjmp RESET
.org $01
  rjmp ext_int0
.org $02
  rjmp ext_int1
.org $07
	rjmp ISR_TOV0

PRINT_BANNER:             ; void PRINT_BANNER()
	cbi PORTA,1	   ; CLR RS
  rcall CLEAR_LCD
  ldi temp,0x80	 ; move cursor to line 1 col 0
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN  
  ldi r25, high(2*banner_0)
  ldi r24, low(2*banner_0)
  rcall WRITE_TEXT

  cbi PORTA,1	   ; CLR RS
  ldi temp,0xc6	 ; move cursor to line 2 col 6
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN  
  ldi r25, high(2*banner_1)
  ldi r24, low(2*banner_1)
  rcall WRITE_TEXT
  rcall DELAY_02
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
  rcall PRINT_BANNER
  rcall INIT_INTERRUPT
  rjmp MAIN

INIT_LCD:
  push temp
	cbi PORTA,1	   ; CLR RS
	ldi temp,0x38	 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN
	rcall WAIT_LCD
	ldi temp,0x0C	 ; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN
	rcall WAIT_LCD
	ldi temp,0x06  ; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN
	rcall WAIT_LCD
  pop temp
	ret

WAIT_LCD:
; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 1 024 cycles
; 128us at 8.0 MHz
  push r18
  push r19
  ldi  r18, 2
  ldi  r19, 83
wl_cont:
  dec  r19
  brne wl_cont
  dec  r18
  brne wl_cont

  pop r19
  pop r18
  ret


DELAY_00:
  ; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; Delay 4 000 cycles
	; 500us at 8.0 MHz
	    ldi  r18, 6
	    ldi  r19, 49
	L0: dec  r19
	    brne L0
	    dec  r18
	    brne L0
  ret


DELAY_01:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; DELAY_CONTROL 40 000 cycles
	; 5ms at 8.0 MHz

	    ldi  r18, 52
	    ldi  r19, 242
	L1: dec  r19
	    brne L1
	    dec  r18
	    brne L1
	    nop
	ret

DELAY_02:
; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 160 000 cycles
; 20ms at 8.0 MHz

	    ldi  r18, 208
	    ldi  r19, 202
	L2: dec  r19
	    brne L2
	    dec  r18
	    brne L2
	    nop
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

INIT_INTERRUPT:
  ldi temp,0b00001010
  out MCUCR,temp
  ldi temp,0b11000000
  out GICR,temp
  
  ldi temp, 1<<CS02	; 
  out TCCR0,temp
  ldi temp,1<<TOV0
  out TIFR,temp      ; Interrupt if overflow occurs in T/C0
  ldi temp,1<<TOIE0
  out TIMSK,temp     ; Enable Timer/Counter0 Overflow int
  sei
  ret

INIT_PLAYER:
  cbi PORTA,1	   ; CLR RS
  ldi temp,0xc0	 ; move cursor to line 2 col 0
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN  
  ldi r25, high(2*player)
  ldi r24, low(2*player)
   rcall WRITE_TEXT
  ret

PRINT:
  cbi PORTA,1	   ; CLR RS
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN  
  ldi r25, high(2*player)
  ldi r24, low(2*player)
   rcall WRITE_TEXT
  ret

ISR_TOV0:
  rcall CLEAR_LCD
  rcall DELAY_00
  rcall PRINT
  reti

MAIN:
  rcall CLEAR_LCD
  cbi PORTA,1	   ; CLR RS
	ldi temp,0xc8	 ; MOV DATA,0xc8 --> disp ON, cursor OFF, blink OFF
	out PORTB,temp
	sbi PORTA,0	   ; SETB EN
	cbi PORTA,0	   ; CLR EN
	rcall WAIT_LCD
  rcall INIT_PLAYER
  rjmp forever

ext_int0:
  ldi temp,0x80	 ; move cursor to line 1 col 0
  reti

ext_int1:
  ldi temp,0xC0	 ; move cursor to line 2 col 0
  reti

forever:
  rjmp forever

banner_0:
.db ">>>SPACE", 0
banner_1:
.db "INVADER<<<", 0
player:
.db ">", 0
