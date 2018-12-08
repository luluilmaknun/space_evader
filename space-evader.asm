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
.equ space = 0x20
.equ meteor = 0x40

.org $00
  rjmp RESET
.org $07
  rjmp ISR_TOV0

PRINT_BANNER:              ; void PRINT_BANNER()
  cbi PORTA,1		   ; CLR RS
  rcall CLEAR_LCD
  ldi temp,0x80		   ; move cursor to line 1 col 0
  out PORTB,temp
  sbi PORTA,0		   ; SETB EN
  cbi PORTA,0		   ; CLR EN  
  ldi r25, high(2*banner_0)
  ldi r24, low(2*banner_0)
  rcall WRITE_TEXT

  cbi PORTA,1	           ; CLR RS
  ldi temp,0xc6	           ; move cursor to line 2 col 6
  out PORTB,temp
  sbi PORTA,0	           ; SETB EN
  cbi PORTA,0	           ; CLR EN  
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
  rcall INIT_OBSTACLES_MEM
  ;rcall INIT_LED
  ;rcall INIT_BUTTON
  rcall PRINT_BANNER
  rjmp MAIN

INIT_LCD:
  cbi PORTA,1	   ; CLR RS
  ldi temp,0x38    ; MOV DATA,0x38 --> 8bit, 2line, 5x7
  out PORTB,temp
  sbi PORTA,0	   ; SETB EN
  cbi PORTA,0	   ; CLR EN
  rcall WAIT_LCD
  ldi temp,0x0E    ; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
  out PORTB,temp
  sbi PORTA,0	   ; SETB EN
  cbi PORTA,0	   ; CLR EN
  rcall WAIT_LCD
  ldi temp,0x06    ; MOV DATA,0x06 --> increase cursor, display sroll OFF
  out PORTB,temp
  sbi PORTA,0	   ; SETB EN
  cbi PORTA,0	   ; CLR EN
  rcall WAIT_LCD
  ret

WAIT_LCD:
; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 1 024 cycles
; 128us at 8.0 MHz
  ldi  r24, 2
  ldi  r25, 83
wl_cont:
  dec  r25
  brne wl_cont
  dec  r24
  brne wl_cont
  ret


DELAY_00:
  ; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; Delay 4 000 cycles
	; 500us at 8.0 MHz
	    ldi  r24, 6
	    ldi  r25, 49
	L0: dec  r25
	    brne L0
	    dec  r24
	    brne L0
  ret


DELAY_01:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; DELAY_CONTROL 40 000 cycles
	; 5ms at 8.0 MHz

	    ldi  r24, 52
	    ldi  r25, 242
	L1: dec  r25
	    brne L1
	    dec  r24
	    brne L1
	    nop
	ret

DELAY_02:
; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 160 000 cycles
; 20ms at 8.0 MHz

	    ldi  r24, 208
	    ldi  r25, 202
	L2: dec  r25
	    brne L2
	    dec  r24
	    brne L2
	    nop
		ret

CLEAR_LCD:
  cbi PORTA,1	   ; CLR RS
  ldi temp, 0x01   ; MOV DATA,0x01
  out PORTB,temp
  sbi PORTA,0	   ; SETB EN
  cbi PORTA,0	   ; CLR EN
  rcall WAIT_LCD
  ret

WRITE_TEXT:        ; void WRITE_TEXT(char[] *r25:r24)
  mov	ZH, r25    ; Load high part of byte address into ZH
  mov	ZL, r24    ; Load low part of byte address into ZL
loadbyte:
  lpm              ; Load byte from program memory into r0
  
  tst r0           ; Check if we've reached the end of the message
  breq write_quit  ; If so, quit
  
  mov r24, r0      ; Put the character onto first argument
  rcall WRITE_CHAR
  adiw ZL,1        ; Increase Z registers
  rjmp loadbyte
write_quit:
  ret

WRITE_CHAR:        ; void WRITE_CHAR(char r24)
  sbi PORTA,1      ; SETB RS
  out PORTB, r24
  sbi PORTA,0	   ; SETB EN
  cbi PORTA,0	   ; CLR EN
  rcall WAIT_LCD
  ret

INIT_INTERRUPT:
  ldi temp,(1<<CS01)	; 
  out TCCR0,temp
  ldi temp,1<<TOV0
  out TIFR,temp      ; Interrupt if overflow occurs in T/C0
  ldi temp,1<<TOIE0
  out TIMSK,temp     ; Enable Timer/Counter0 Overflow int
  sei
  ret

INIT_PLAYER:
  cbi PORTA,1	   ; CLR RS
  ldi temp,0xc0	   ; move cursor to line 2 col 0
  out PORTB,temp
  sbi PORTA,0	   ; SETB EN
  cbi PORTA,0	   ; CLR EN  
  ldi r25, high(2*player)
  ldi r24, low(2*player)
  rcall WRITE_TEXT
  ret

ISR_TOV0:
  rcall SCROLL_OBSTACLES
  rcall UPDATE_OBSTACLE
  rcall DELAY_02
  reti

MAIN:
  rcall CLEAR_LCD
  cbi PORTA,1	       ; CLR RS
  ldi temp,0xc8        ; MOV DATA,0xc8 --> disp ON, cursor OFF, blink OFF
  out PORTB,temp
  sbi PORTA,0	       ; SETB EN
  cbi PORTA,0	       ; CLR EN
  rcall WAIT_LCD
  rcall INIT_PLAYER
  rcall INIT_OBSTACLES
  
  rcall INIT_INTERRUPT
  rjmp forever

INIT_OBSTACLES:
  ldi ZH, high(2*obstacles)
  sts obstacle_pos_h, ZH
  ldi ZL, low(2*obstacles)
  sts obstacle_pos_l, ZL
  ret

INIT_OBSTACLES_MEM:
  ldi temp, 0x20
  ldi r24, space
  ldi XH, high(obstacles_top_row)
  ldi XL, low(obstacles_top_row)
obs_mem_loop:
  st X+, r24
  dec temp
  tst temp
  brne obs_mem_loop
  ret

UPDATE_OBSTACLE:
  lds ZH, obstacle_pos_h
  lds ZL, obstacle_pos_l
  ldi r24, space
  lpm temp, Z+
  cpi temp, 0x01
  brne skip_top
  ldi r24, meteor   ; only set temp to meteor if lesser

skip_top:
  push temp
  cbi PORTA,1        ; CLR RS
  ldi temp,0x8f	     ; move cursor to line 1 col 15
  out PORTB,temp
  sbi PORTA,0	     ; SETB EN
  cbi PORTA,0	     ; CLR EN
  push r24
  rcall WAIT_LCD
  pop r24
  sts obstacles_top_row_last, r24 ; get the last byte
  rcall WRITE_CHAR

  ldi r24, space
  pop temp
  cpi temp, 0x03
  brne skip_bottom   ; only set temp to meteor if greater
  ldi r24, meteor

skip_bottom:
  cbi PORTA,1        ; CLR RS
  ldi temp,0xcf	     ; move cursor to line 2 col 15
  out PORTB,temp
  sbi PORTA,0	     ; SETB EN
  cbi PORTA,0	     ; CLR EN
  push r24
  rcall WAIT_LCD
  pop r24
  sts obstacles_bottom_row_last, r24 ; get the last byte
  rcall WRITE_CHAR
  
  sts obstacle_pos_h, ZH
  sts obstacle_pos_l, ZL
  ret

SCROLL_OBSTACLES:
  ldi XH, high(obstacles_top_row)
  ldi XL, low(obstacles_top_row + 0x02)
  ldi YH, high(obstacles_bottom_row)
  ldi YL, low(obstacles_bottom_row + 0x02)
  ldi r24, 0x0e
  rcall REWRITE_OBSTACLES
  ret

REWRITE_OBSTACLES:
  cpi r24, 0x01
  brne rewrite_again
  ret

rewrite_again:
  push r24
  push r24
  movw Z, X
  adiw X, 1
  ld r23, X
  st Z, r23

  cbi PORTA,1
  ldi temp, 0x90
  sub temp, r24
  out PORTB, temp
  sbi PORTA,0
  cbi PORTA,0
  rcall WAIT_LCD
  mov r24, r23
  rcall WRITE_CHAR

  movw Z, Y
  adiw Y, 1
  ld r22, Y
  st Z, r22
  pop r24

  cbi PORTA,1
  ldi temp, 0xd0
  sub temp, r24
  out PORTB, temp
  sbi PORTA,0
  cbi PORTA,0
  rcall WAIT_LCD
  mov r24, r22
  rcall WRITE_CHAR

  pop r24
  dec r24
  rcall REWRITE_OBSTACLES
  ret

forever:
  rjmp forever

banner_0:
.db ">>>SPACE", 0
banner_1:
.db "INVADER<<<", 0

player:
.db "X", 0

obstacles:
.db 2,1,1,1,2,2,2,3,3,3,3,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,3,3,2,2,1,1,1,1,2,2,3,3,2,2,2,3,2,2,1,1,1,3,3,3,2,2,2,2,1,1,2,2,3,3,2,2,1,1,2,2,3,3,1,1,2,3,2,1,2,3,1,2,0

;******************************** START OF DATA SEGMENT ****************************

.dseg

obstacle_pos_h:
.byte 1

obstacle_pos_l:
.byte 1

obstacles_top_row:
.byte 0x0f

obstacles_top_row_last:
.byte 1

obstacles_bottom_row:
.byte 0x0f

obstacles_bottom_row_last:
.byte 1
