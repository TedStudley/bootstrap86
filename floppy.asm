; Next, we need to be able to write our input programs to a disk, so that we
; can actually save our output. Additionally, we probably want to write our
; program data to a different sector in memroy, so we don't end up overwriting
; our monitor in the process. This is doubly important, since in order to
; write our monitor to disk the first time, we'll need to first enter it into
; the initial bootstrapping monitor by hand.

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

; Subtract 0x30 ('0')
SUB  AL, 0x30                          ; 0017  2C 30

; Break unless we got an octal digit
CMP  AL, 0x08                          ; 0019  3C 08
JNB  break_loop                        ; 001B  73 12

; Add the lower three bits to the byte 
SHL  BL, 0x03                          ; 001D  C0 E3 03
ADD  BL, AL                            ; 0020  00 C3

; Increment the byte counter by 1
INC  DL                                ; 0022  FE C2
CMP  DL, 0x03                          ; 0024  80 FA 03
JB   byte_loop                         ; 0027  72 E2

; Write the completed byte to memory
MOV  [ES:SI], BL                       ; 0029  26 88 1C
INC  SI                                ; 002C  46

; Loop until the program is loaded
JMP input_loop                         ; 002D  EB D8
break_loop:

; Execute the loaded program
; execute the loaded program
MOV  AX, 0xAA55                        ; 002F  B8 55 AA
MOV  [ES:0x01FE], AX                   ; 0032  26 A3 FE 01

; Copy the input program to disk
;   AH = 0x03 - write disk sectors
;   AL = 0x01 - write 1 sector
;   CH = 0x00 - write cylinder 0
;   CL = 0x01 - write sector 1
;   DH = 0x00 - write head 0
;   DL = 0x00 - write drive 0
MOV  AX, 0x0301                        ; 0036  B8 01 03
XOR  BX, BX                            ; 0039  31 DB
MOV  CX, 0x0001                        ; 003B  B9 01 00
XOR  DX, DX                            ; 003E  31 D2
INT  0x13                              ; 0040  CD 13

; Quit the monitor
CLI                                    ; 0042  FA
HLT                                    ; 0043  F4

; This new program takes 0x44 (68) bytes, and can be expressed in hex as:
;   BB 00 02 8E C3 31 F6 31 DB 31 D2 B4 00 CD 16 3C 00 74 F8 B4 0E CD 10 2C 30
;   3C 08 73 12 C0 E3 03 00 C3 FE C2 80 FA 03 72 E2 26 88 1C 46 EB D8 B8 55 AA
;   26 A3 FE 01 B8 01 03 31 DB B9 01 00 31 D2 CD 13 FA F4 
;
; Or in octal as:
;   273 000 002 216 303 061 366 061 333 061 322 264 000 315 026 074 000 164 370
;   264 016 315 020 054 060 074 010 163 022 300 343 003 000 303 376 302 200 372
;   003 162 342 046 210 034 106 353 330 270 125 252 046 243 376 001 270 001 003
;   061 333 271 001 000 061 322 315 023 372 364
