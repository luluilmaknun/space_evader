.include "m8515def.inc"

.def temp = r16
.def lcd1 = r17
.def lcd2 = r18

.org $00
    rjmp START

START:

INIT_STACK: ; create stack
	ldi temp,low(RAMEND)
    out SPL,temp 
    ldi temp,high(RAMEND)
    out SPH,temp

rcall INIT_LCD_MAIN

INIT_LCD_MAIN:
	rcall INIT_LCD

	ser temp
	ldi lcd1, player
	ldi lcd2, space 
    ldi temp,$ff
    out DDRA,temp ; Set port A as output
    out DDRB,temp ; Set port B as output
    out DDRC,temp ; Set port B as output

TIMER:
	ldi temp, (1<<CS11)
	out TCCR1B,temp
	ldi temp,1<<TOV1
    out TIFR,temp      
    ldi temp,1<<TOIE1
    out TIMSK,temp     

ENABLE_INTERUPT:
    ldi temp,0b00001010 ; Terpicu dimana (dari 1 ke 0 utk kedua interrupt
    out MCUCR,temp
    ldi temp,0b11000000 ; nyalain 2 interrupt (INT0 dan INT1)
    out GICR,temp
    sei

START_GAME: ;Menggenerate obstacle awal game
 	ldi temp, 0x00
 	st X, temp
 	adiw X, 1
 	ldi temp, 0x00
 	st X, temp
 	adiw X, 1
 	inc count
 	cpi count,0x08

	 brne START_GAME
 	ldi ZH,high(2*message_level1) ; Load high part of byte address into ZH
 	ldi ZL,low(2*message_level1) ; Load low part of byte address into ZL
 	ldi temp, $01
 	mov status_level, temp
 	out PORTC, status_level

	rcall INPUT_RINTANGAN
	rcall LOADBYTE
	rcall MOVE_CURSOR

INIT_LCD:
 cbi PORTA,1 ; CLR RS
 ldi temp,0xc0 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
 out PORTB,temp
 sbi PORTA,0 ; SETB EN
 cbi PORTA,0 ; CLR EN

 cbi PORTA,1 ; CLR RS
 ldi temp,$0c ; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
 out PORTB,temp
 sbi PORTA,0 ; SETB EN
 cbi PORTA,0 ; CLR EN

 rcall CLEAR_LCD ; CLEAR LCD
 cbi PORTA,1 ; CLR RS
 ldi temp,$06 ; MOV DATA,0x06 --> increase cursor, display sroll OFF
 out PORTB,temp
 sbi PORTA,0 ; SETB EN
 cbi PORTA,0 ; CLR EN
 ret


CLEAR_LCD:
 cbi PORTA,1 ; CLR RS
 ldi temp,$01 ; MOV DATA,0x01
 out PORTB,temp
 sbi PORTA,0 ; SETB EN
 cbi PORTA,0 ; CLR EN
 ret

RESET_LCD:    ; Clear LCD
 cbi PORTA,1  ; CLR RS
 ldi temp,$02 ; MOV DATA,0x01
 out PORTB,temp
 sbi PORTA,0 ; SETB EN
 cbi PORTA,0 ; CLR EN
 ret

WRITE_TEXT:
 sbi PORTA,1 ; SETB RS
 out PORTB, totext
 sbi PORTA,0 ; SETB EN
 cbi PORTA,0 ; CLR EN
 ret
