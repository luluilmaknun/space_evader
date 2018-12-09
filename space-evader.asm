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
.equ player = 0x3e
.def position = r18
.def life = r21

.org $00
  rjmp RESET
.org $01
  rjmp ext_int0
.org $02
  rjmp ext_int1
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
; Delay 320 cycles
; 40us at 8.0 MHz
  ldi  r25, 106
wl_cont:
  dec  r25
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

INIT_LED:
  ldi life, 0b11111111
  out PORTC, life
  ret

INIT_PLAYER:
  ldi temp, 0x00
  sts player_pos, temp
  ldi temp, 0x40
  sts player_is_bottom, temp
  rcall UPDATE_PLAYER_POS
  ret

UPDATE_PLAYER_POS:
  lds r23, pre_player_cursor
  cbi PORTA,1	   ; CLR RS
  out PORTB,r23
  sbi PORTA,0	   ; SETB EN
  cbi PORTA,0	   ; CLR EN  
  ldi r24, space
  rcall WRITE_CHAR
  lds temp, player_is_bottom
  ldi r23, 0x80
  add r23, temp
  lds temp, player_pos

  cpi temp, 0x28   ; 40 is max screen size
  brne no_reset_cursor

  ldi temp, 0

no_reset_cursor:   
  add r23, temp
  sts pre_player_cursor, r23
  inc temp
  sts player_pos, temp
  cbi PORTA,1	   ; CLR RS
  out PORTB,r23
  sbi PORTA,0	   ; SETB EN
  cbi PORTA,0	   ; CLR EN  
  rcall WAIT_LCD
  ldi r24, player
  rcall WRITE_CHAR
  ret

SCROLL_LCD:
  ldi temp, 0x18   ; Scroll display one character left (all lines)
  cbi PORTA,1	   ; CLR RS
  out PORTB,temp
  sbi PORTA,0	   ; SETB EN
  cbi PORTA,0	   ; CLR EN  
  rcall WAIT_LCD
  ret

ISR_TOV0:
  rcall DELAY_00
  rcall CHECK_COLLISION
  rcall SCROLL_LCD
  rcall UPDATE_PLAYER_POS
  reti

MAIN:
  rcall CLEAR_LCD
  cbi PORTA,1	       ; CLR RS
  ldi temp,0x0c        ; MOV DATA,0x0c --> disp ON, cursor OFF, blink OFF
  out PORTB,temp
  sbi PORTA,0	       ; SETB EN
  cbi PORTA,0	       ; CLR EN
  rcall WAIT_LCD
  rcall INIT_LED
  rcall PRINT_OBSTACLES
  rcall INIT_PLAYER
  
  rcall INIT_INTERRUPT
  rjmp forever


OBSTACLE_BYTE_TO_CHAR_TOP:    ; char OBSTACLE_BYTE_TO_CHAR_TOP(int r24) 
  cpi r24, 1
  breq ret_meteor
  ldi r24, space
  ret

OBSTACLE_BYTE_TO_CHAR_BOTTOM:    ; char OBSTACLE_BYTE_TO_CHAR_BOTTOM(int r24) 
  cpi r24, 3
  breq ret_meteor
  ldi r24, space
  ret

ret_meteor:
  ldi r24, meteor
  ret


PRINT_OBSTACLES:
  cbi PORTA,1        ; CLR RS
  ldi temp,0x80	     ; move cursor to line 1 col 0
  out PORTB,temp
  sbi PORTA,0	     ; SETB EN
  cbi PORTA,0	     ; CLR EN

  ldi ZH, high(2*obstacles)
  ldi ZL, low(2*obstacles)
  lpm

next_obstacle_code_top:
  mov r24, r0
  rcall OBSTACLE_BYTE_TO_CHAR_TOP
  rcall WRITE_CHAR

  adiw ZL, 1
  lpm
  tst r0
  brne next_obstacle_code_top

  cbi PORTA,1        ; CLR RS
  ldi temp,0xc0	     ; move cursor to line 2 col 0
  out PORTB,temp
  sbi PORTA,0	     ; SETB EN
  cbi PORTA,0	     ; CLR EN

  ldi ZH, high(2*obstacles)
  ldi ZL, low(2*obstacles)
  lpm

next_obstacle_code_bottom:
  mov r24, r0
  rcall OBSTACLE_BYTE_TO_CHAR_BOTTOM
  rcall WRITE_CHAR

  adiw ZL, 1
  lpm
  tst r0
  brne next_obstacle_code_bottom

  ret

CHECK_COLLISION:
  lds temp, player_pos
  lds r24, player_is_bottom
  ldi ZH, high(2*obstacles)
  ldi ZL, low(2*obstacles)
  add ZL, temp
  lpm
  mov temp, r0
  cpi temp, 2
  breq coll_passes
  cpi temp, 1
  brne coll_three
  tst r24
  brne coll_passes
  rjmp collides

coll_three:
  cpi r24, 0x40
  brne coll_passes

collides:
  rcall lose_life
  ret

coll_passes:
  ret

PRINT_GAMEOVER:              ; void PRINT_BANNER()
  cbi PORTA,1		   ; CLR RS
  rcall CLEAR_LCD
  ldi temp,0x80		   ; move cursor to line 1 col 0
  out PORTB,temp
  sbi PORTA,0		   ; SETB EN
  cbi PORTA,0		   ; CLR EN  
  ldi r25, high(2*game_over)
  ldi r24, low(2*game_over)
  rcall WRITE_TEXT
  rjmp forever

lose_life:
  lsr life
  out PORTC, life

  tst life
  breq PRINT_GAMEOVER
  ret

ext_int0:
  ldi temp, 0             ; false
  sts player_is_bottom, temp
  reti

ext_int1:
  ldi temp, 0x40          ; true
  sts player_is_bottom, temp
  reti

forever:
  rjmp forever

banner_0:
.db ">>>SPACE", 0
banner_1:
.db "INVADER<<<", 0
game_over:
.db "GAMEOVER!!!", 0
obstacles:
.db 2,2,1,1,2,2,2,3,3,3,3,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,3,3,2,2,1,1,1,1,2,2,3,3,2,2,0

;******************************** START OF DATA SEGMENT ****************************

.dseg

player_is_bottom: ; 0x0 for false and 0x40 for true
.byte 1

player_pos:
.byte 1

pre_player_cursor:
.byte 1
