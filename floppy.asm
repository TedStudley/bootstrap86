; In the third iteration of the bootloader, I'd like to add some useful
; features, including the ability to input bytecode in hex instead of octal
; and the ability to use backspace to delete a character.

; Update the program data location
MOV  BX, 0x0200                        ; 0000  BB 00 02
MOV  ES, BX                            ; 0003  8E C3
XOR  SI, SI                            ; 0005  31 F6

; Loop until end of input
input_loop:
XOR  BX, BX                            ; 0007  31 DB
XOR  DX, DX                            ; 0009  31 D2

byte_loop:
; Input a character
MOV  AH, 0x00                          ; 000B  B4 00
INT  0x16                              ; 000D  CD 16
CMP  AL, 0x00                          ; 000F  3C 00
JZ byte_loop                           ; 0011  74 F8
; Display the character to the screen
MOV  AH, 0x0E                          ; 0013  B4 0E
INT  0x10                              ; 0015  CD 10

; Check for backspace
CMP  AL, 0x08                          ; 0017  3C 08
JNE  not_special                       ; 0019  75 12
; If this was the first digit, pull up
; the previous byte
CMP  DL, 0x00                          ; 001B  80 FA 00
JA   not_first                         ; 001E  77 06
; Decrement the current data pointer
; and pull up the previous byte
DEC  SI                                ; 0020  4E
MOV  BL, [ES:SI]                       ; 0021  26 8A 1C
MOV  DL, 0x02                          ; 0024  B2 02
not_first:

; Decrement the loop counter and shift
; right by a nibble
DEC  DL                                ; 0026  FE CA
SHR  BL, 0x04                          ; 0028  C0 EB 04
JMP  byte_loop                         ; 002B  EB DE
not_special:

; Subtract 0x30 ('0')
SUB  AL, 0x30                          ; 002D  2C 30

; Check for a hex digit 0-9
CMP  AL, 0x09                          ; 002F  3C 09
JNA  is_digit                          ; 0031  76 10

; Subtract 0x11 ('A' - '0')
SUB  AL, 0x11                          ; 0033  2C 11
; Check for a hex digit A-F
CMP  AL, 0x06                          ; 0035  3C 06
JB   is_hex_digit                      ; 0037  72 08

; Subtract 0x30 ('a' - 'A')
SUB  AL, 0x20                          ; 0039  2C 20
; Check for a hex digit a-f
CMP  AL, 0x06                          ; 003B  3C 06
JB   is_hex_digit                      ; 003D  72 02

; We got a non-hex digit.
JMP  break_loop                        ; 003F  EB 14

is_hex_digit:
ADD  AL, 0x0A                          ; 0041  04 0A
is_digit:

; Shift the current nibble left
SHL  BL, 0x04                          ; 0043  C0 E3 04
ADD  BL, AL                            ; 0046  00 C3

; Increment the byte counter by 1
INC  DL                                ; 0048  FE C2
CMP  DL, 0x02                          ; 004A  80 FA 02
JB   byte_loop                         ; 004D  72 BC

; Write the completed byte to memory
MOV  [ES:SI], BL                       ; 004F  26 88 1C
INC  SI                                ; 0052  46

; Loop until the program is loaded
JMP input_loop                         ; 0053  EB B2
break_loop:

; Execute the loaded program
MOV  AX, 0xAA55                        ; 0055  B8 55 AA
MOV  [ES:0x01FE], AX                   ; 0058  26 A3 FE 01

; Copy the input program to disk
;   AH = 0x03 - write disk sectors
;   AL = 0x01 - write 1 sector
;   CH = 0x00 - write cylinder 0
;   CL = 0x01 - write sector 1
;   DH = 0x00 - write head 0
;   DL = 0x00 - write drive 0
MOV  AX, 0x0301A                       ; 005C  B8 01 03
XOR  BX, BX                            ; 005F  31 DB
MOV  CX, 0x0001                        ; 0061  B9 01 00
XOR  DX, DX                            ; 0064  31 D2
INT  0x13                              ; 0066  CD 13

; Quit the monitor
CLI                                    ; 0068  FA
HLT                                    ; 0069  F4

; This new program takes 0x6A (110) bytes, and can be represented in
; hexadecimal opcodes as:
;   BB 00 02 8E C3 31 F6 31 DB 31 D2 B4 00 CD 16 3C 00 74 F8 B4 0E CD 10 3C 08
;   75 12 80 FA 00 77 06 4E 26 8A 1C B2 02 FE CA C0 EB 04 EB DE 2C 30 3C 09 76
;   10 2C 11 3C 06 72 08 2C 20 3C 06 72 02 EB 14 04 0A C0 E3 04 00 C3 FE C2 80
;   FA 02 72 BC 26 88 1C 46 EB B2 B8 55 AA 26 A3 FE 01 B8 01 03 31 DB B9 01 00
;   31 D2 CD 13 FA F4
;
; It can also be represented in octal as:
;   273 000 002 216 303 061 366 061 333 061 322 264 000 315 026 074 000 164 370
;   264 016 315 020 074 010 165 022 200 372 000 167 006 116 046 212 034 262 002
;   376 312 300 353 004 353 336 054 060 074 011 166 020 054 021 074 006 162 010
;   054 040 074 006 162 002 353 024 004 012 300 343 004 000 303 376 302 200 372
;   002 162 274 046 210 034 106 353 262 270 125 252 046 243 376 001 270 001 003
;   061 333 271 001 000 061 322 315 023 372 364
;
; Once we have these improvements, we should be ready to implement a more
; robust system, separating the bootloader from the rest of the monitor as well
; as implementing a way to load and edit the pre-existing program on disk. From
; there, we'll be on our way towards the first steps of a working OS.
