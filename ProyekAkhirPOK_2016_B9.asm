.include "m8515def.inc"

.def temp =r16 ; temp
.def lcd0 = r18 ;  penanda letak pemain (untuk layar bawah)
.def lcd1  = r19 ; penanda letak pemain (untuk layar atas)
.def totext = r20 ; temp khusus untuk penulisan ke lcd
.def obstacle = r21 ; register untuk menggenerate obstacle
.def state_obstacle = r17; register untuk check prev state obstacle
.def counter_level = r23
.def status_level = r10
.def count = r22
.equ charx = 0x58
.equ space = 0x20

.org $00
    rjmp START
.org $01
    rjmp ext_int0 	; tombol up
.org $02
    rjmp ext_int1 	; tombol down
.org $06
    rjmp ISR_TOV1
.org $07
 	rjmp ISR_TOV0

START:
    ldi temp,low(RAMEND) ; Set stack pointer to -
    out SPL,temp ; -- last internal RAM location
    ldi temp,high(RAMEND)
    out SPH,temp

 ;set memory
 ldi XL,0x60
 ldi XH,0x00
 ldi YL,0x60
 ldi YH,0x00
    
 ;Set TIMER
 	ldi temp, (1<<CS11) ;| (1<<CS10) ;| (1<<CS11)
	out TCCR1B,temp
	ldi temp,1<<TOV1
    out TIFR,temp       ; Interrupt if overflow occurs in T/C0
    ldi temp,1<<TOIE1
    out TIMSK,temp      ; Enable Timer/Counter0 Overflow int
 
    ;karakter awal2 ada dibawah
 ldi lcd0, charx 
 ldi lcd1, space 
    ldi temp,$ff
    out DDRA,temp ; Set port A as output
    out DDRB,temp ; Set port B as output
    out DDRC,temp ; Set port B as output

 rcall INIT_LCD

ENABLEINTERUPT:
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

LOADBYTE_1:
 lpm ; Load byte from program memory into r0

 tst r0 ; Check if we've reached the end of the message
 breq QUIT ; If so, quit

 mov totext, r0 ; Put the character onto Port B
 rcall WRITE_TEXT
 adiw ZL,1 ; Increase Z registers
 rjmp LOADBYTE_1


INCREASE_LEVEL2:
 ldi r29, $00
 out TCCR0, r29
 out TIFR, r29
 out TIMSK, r29
 ldi ZH,high(2*message_level3) ; Load high part of byte address into ZH
 ldi ZL,low(2*message_level3) ; Load low part of byte address into ZL
 rcall CLEAR_LCD
 lsl status_level
 ;ldi temp, $01
 ;add status_level, temp
 out PORTC, status_level

LOADBYTE3:
 lpm ; Load byte from program memory into r0
 tst r0 ; Check if we've reached the end of the message
 breq QUIT_FINAL ; If so, quit
 mov totext, r0 ; Put the character onto Port B
 rcall WRITE_TEXT
 adiw ZL,1 ; Increase Z registers
 rjmp LOADBYTE3

QUIT:  ;menunggu timer dan merandom obstacle
 cpi r29, $ff
 breq forever
 cpi counter_level, level1
 breq increase_level
 cpi counter_level, level2
 breq increase_level2
 cpi counter_level, level3
 breq forever_quit
 ldi obstacle, 0xff
 ldi obstacle, 0x00
 ldi obstacle, 0x20
 ldi obstacle, 0x20
 ldi obstacle, 0xff
 ldi obstacle, 0x20
 ldi obstacle, 0x00
 ldi obstacle, 0x20
 ldi obstacle, 0x20
 ldi obstacle, 0xff
 rjmp QUIT


QUIT_FINAL:
 ldi temp, (1<<CS02);|(1<<CS00) ; Timer clock = system clock/1024
 out TCCR0,temp   
 ldi temp,1<<TOV0
 out TIFR,temp  ; Interrupt if overflow occurs in T/C0
 ldi temp,1<<TOIE0
 out TIMSK,temp  ; Enable Timer/Counter0 Overf
 inc counter_level
 ;ldi counter_level , $16
 rjmp QUIT


INCREASE_LEVEL:
 ldi r29, $00
 out TCCR1B, r29
 out TIFR, r29
 out TIMSK, r29
 inc counter_level
 ;ldi counter_level ,$8
 ldi ZH,high(2*message_level2) ; Load high part of byte address into ZH
 ldi ZL,low(2*message_level2) ; Load low part of byte address into ZL
 rcall CLEAR_LCD
 lsl status_level
 ;ldi temp, $01
 ;add status_level, temp
 out PORTC, status_level

LOADBYTE2:
 lpm ; Load byte from program memory into r0
 tst r0 ; Check if we've reached the end of the message
 breq QUIT_ON ; If so, quit
 mov totext, r0 ; Put the character onto Port B
 rcall WRITE_TEXT
 adiw ZL,1 ; Increase Z registers
 rjmp LOADBYTE2

QUIT_ON:
 ldi temp, (1<<CS02)|(1<<CS00) ;imer clock = system clock/1024
 out TCCR0,temp   
 ldi temp,1<<TOV0
 out TIFR,temp  ; Interrupt if overflow occurs in T/C0
 ldi temp,1<<TOIE0
 out TIMSK,temp  ; Enable Timer/Counter0 Overf
 rjmp QUIT

FOREVER_QUIT:
 ldi r29, $00
 out TCCR0, r29
 out TIFR, r29
 out TIMSK, r29
 rcall clear_lcd
 ldi ZH,high(2*message_win) ; Load high part of byte address into ZH
 ldi ZL,low(2*message_win) ; Load low part of byte address into ZL
 rjmp loadbyte

FOREVER:
 ldi ZH,high(2*message) ; Load high part of byte address into ZH
 ldi ZL,low(2*message) ; Load low part of byte address into ZL

LOADBYTE:
 lpm ; Load byte from program memory into r0

 tst r0 ; Check if we've reached the end of the message
 breq QUIT_2 ; If so, quit and loop forever

 mov totext, r0 ; Put the character onto Port B
 rcall WRITE_TEXT
 adiw ZL,1 ; Increase Z registers
 rjmp LOADBYTE

QUIT_2:
 rjmp QUIT_2

ISR_TOV0:
 inc counter_level
    push temp
    in temp,SREG
    push temp

 rcall RESET_LCD
 ld r1, y ;simpan obstacle paling depan untuk di cek nanti
 ldi count, 0x00
 rjmp OBSTACLEUP

ISR_TOV1:
 inc counter_level
    push temp
    in temp,SREG
    push temp

 rcall RESET_LCD
 ld r1, y ;simpan obstacle paling depan untuk di cek nanti
 ldi count, 0x00


OBSTACLEUP: ;obstacle baris atas
 ld totext, Y 
 tst totext ;check apakah nilai di memori 0x00, jika 0x00, to text = 0x20 
 brne Write1 ; , jika tidak loncat ke Write1 (langsung tulis apapun yang ada di memori)
 ldi totext, 0x20
 
Write1:
 rcall WRITE_TEXT
 adiw Y,1
 inc count
 cpi count, 0x10
 brne OBSTACLEUP

SECONDROW:
 cbi PORTA,1 ; CLR RS
 ldi temp,$c0 ; MOV DATA,0x01
 out PORTB,temp
 sbi PORTA,0 ; SETB EN
 cbi PORTA,0 ; CLR EN

 SBIW Y, 16 ; membaca kembali memori
 ldi count, 0x00

OBSTACLEDOWN:
 ld temp, Y
 cpi temp, space ;check apakah isi dari memori = spasi (jika ya berarti  
 brne noObstacle ; ada obstacle di baris bawah), jika tidak (isi memori =
 ; 0xff / 0x00 berarti tidak ada obstacle)
 ldi totext, 0xff  
 rjmp WRITE0
  
noObstacle:
 ldi totext, space
  
WRITE0:
 rcall WRITE_TEXT
 adiw Y,1
 inc count
 cpi count, 0x10
 brne OBSTACLEDOWN

RET_EXT_INT:
 rcall RESET_LCD

 cpi lcd0,0x58 ;check apakah lcd0 == 0x58, jika ya berarti pemain ada di bawah
 breq bottom

 mov totext,lcd1 ;jika tidak berarti pemain ada di atas, dan langsung ke label END
 rcall WRITE_TEXT
 rjmp end

bottom:
 cbi PORTA,1 ; CLR RS
 ldi temp,$c0 ; MOV DATA,0x01
 out PORTB,temp
 sbi PORTA,0 ; SETB EN
 cbi PORTA,0 ; CLR EN

 mov totext,lcd0
 rcall WRITE_TEXT

END:
 ldi temp, 0xA7 ; char(X) + A57 = 0xff
 add temp, lcd1
 cp temp, r1 ; Cek apakah pemain ada di bar atas, dan apakah bar juga sedang ada obstacle
 breq ENDGAME ;loncat to endgame jika benar (game over)
  
 ldi temp, 0x78 ; char(X) + A57 = 0xff
 sub temp, lcd0
 cp temp, R1 ;ika tidak berarti di baris bawah ada obstacle, oleh karena itu cek
 breq ENDGAME ; apakah pemain ada di baris bawah, jika ya, game over)


 tst r1 ;Cek apakah r1 adalah 0x00 (tidak ada obstacle sama sekali)
 breq NEXTFRAME   ; jika benar, nextframe (lanjutkan game)


set_new_obstacle:
 ldi obstacle, $00
 st X, obstacle ;Simpan obstacle baru ke memori
 mov state_obstacle, obstacle
 adiw X,1 
 sbiw Y, 15 ;turunkan pointer Y
 pop temp
 out SREG,temp
 pop temp
 reti

check_gap_obstacle_1:
 cpi state_obstacle, $20
 breq set_new_obstacle
 st X, obstacle ;Simpan obstacle baru ke memori
 mov state_obstacle, obstacle
 adiw X,1 
 sbiw Y, 15 ;turunkan pointer Y
 pop temp
 out SREG,temp
 pop temp
 reti

check_gap_obstacle_2: 
 cpi state_obstacle, $ff
 breq set_new_obstacle
 st X, obstacle ;Simpan obstacle baru ke memori
 mov state_obstacle, obstacle
 adiw X,1 
 sbiw Y, 15 ;turunkan pointer Y
 pop temp
 out SREG,temp
 pop temp
 reti


NEXTFRAME:
 cpi obstacle, $ff
 breq check_gap_obstacle_1
 cpi obstacle, $20
 breq check_gap_obstacle_2
 
 st X, obstacle ;Simpan obstacle baru ke memori
 mov state_obstacle, obstacle
 adiw X,1 
 sbiw Y, 15 ;turunkan pointer Y

 pop temp
 out SREG,temp
 pop temp

 reti


ENDGAME:
 rcall CLEAR_LCD
 ldi temp, 0xff
 ldi r29, $00
 out TCCR1B, r29
 out TIFR, r29
 out TIMSK, r29
 ldi r29, $ff
 pop temp
 out SREG,temp
 pop temp
 reti

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

ext_int0:
 ldi lcd0, space
 ldi lcd1, charx
 ldi obstacle, 0xff
 reti

ext_int1:
 ldi lcd0, charx
 ldi lcd1, space
 ldi obstacle, 0xff
 reti

message_level1:
	.db "LEVEL 1", 0

message_level2:
	.db "LEVEL 2", 0

message_level3:
	.db "LEVEL 3", 0

message_win:
	.db "YOU WIN!!!", 0

message:
	.db "GAME OVER", 0
