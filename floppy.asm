; By this point, we've pretty much written ourselves into a corner. We should
; reserve the memory in the boot sector of our disk for the bootloader only,
; since it would be far to easy to use up the 512B available by adding nice
; features to the code.
;
; At this point, we would like to separate the boot functionality from the
; edit/save functionality, leaving a simple bootloader in the boot sector, and
; the rest of the monitor program to be loaded from elsewhere on the disk. We
; should also modify our editor to write to this new location on the disk, to
; avoid mistakenly clobbering the boot sector.

; The 'payload' section of this program contains the bootloader and editor to
; be written to disk. We need to jump over them to get to the actual payload
; delivery

JMP after_payload                      ; 0000  EB 7F
; /===========================================================================\
; = BEGINNING OF BOOT PAYLOAD =================================================
; \===========================================================================/
; Set the load pointer to 0x0100:0x0000
MOV  BX, 0x0100                        ; 0002  BB 00 01
MOV  ES, BX                            ; 0005  8E C3
XOR  BX, BX                            ; 0007  31 DB
; Read the OS from disk
;   AH = 0x02 - read disk sectors
;   AL = 0x02 - read 2 sectors
;   CH = 0x00 - read cylinder 0
;   CL = 0x02 - read sector 2
;   DH = 0x00 - read head 0
;   DL = 0x00 - read drive 0
MOV  AX, 0x0202                        ; 0009  B8 02 02
XOR  BX, BX                            ; 000C  31 DB
MOV  CX, 0x0002                        ; 000E  B9 02 00
XOR  DX, DX                            ; 0011  31 D2
INT  0x13                              ; 0013  CD 13

; Transfer control over to the OS
JMP 0x0100:0x0000                      ; 0015  EA 00 00 00 01
CLI                                    ; 001A  4A
HLT                                    ; 001B  F4
; /===========================================================================\
; = END OF BOOT PAYLOAD =======================================================
; \===========================================================================/
; Pad a byte to get an even offset
DB   0x90                              ; 001C  90
; /===========================================================================\
; = BEGINNING OF EDITOR PAYLOAD ===============================================
; \===========================================================================/
; Update the program data location
MOV  BX, 0x0200                        ; 001D  BB 00 02
MOV  ES, BX                            ; 0020  8E C3
XOR  SI, SI                            ; 0022  31 F6

; Loop until end of input
input_loop:
XOR  BX, BX                            ; 0024  31 DB
XOR  DX, DX                            ; 0026  31 D2

byte_loop:
; Input a character
MOV  AH, 0x00                          ; 0028  B4 00
INT  0x16                              ; 002A  CD 16
CMP  AL, 0x00                          ; 002C  3C 00
JZ   byte_loop                         ; 002E  74 F8
; Display the character to the screen
MOV  AH, 0x0E                          ; 0030  B4 0E
INT  0x10                              ; 0032  CD 10

; Check for backspace
CMP  AL, 0x08                          ; 0034  3C 08
JNE  not_special                       ; 0036  75 12
; Move to the previous byte
CMP  DL, 0x00                          ; 0038  80 FA 00
JA   not_first                         ; 003B  77 06
; Decrement the data pointer
DEC  SI                                ; 003D  4E
MOV  BL, [ES:SI]                       ; 003E  26 8A 1C
MOV  DL, 0x02                          ; 0041  B2 02
not_first:
; Decrement the loop counter
DEC  DL                                ; 0043  FE CA
SHR  BL, 0x04                          ; 0045  C0 EB 04
JMP  byte_loop                         ; 0048  EB DE
not_special:

; Subtract 0x30 ('0')
SUB  AL, 0x30                          ; 004A  2C 30

; Check for a hex digit 0-9
CMP  AL, 0x09                          ; 004C  3C 09
JNA  is_digit                          ; 004E  76 10

; Subtract 0x11 ('A' - '0')
SUB  AL, 0x11                          ; 0050  2C 11
; Check for a hex digit A-F
CMP  AL, 0x06                          ; 0052  3C 06
JB   is_hex_digit                      ; 0054  72 08

; Subtract 0x30 ('a' - 'A')
SUB  AL, 0x20                          ; 0056  2C 20
; Check for a hex digit a-f
CMP  AL, 0x06                          ; 0058  3C 06
JB   is_hex_digit                      ; 005A  72 02

; We got something that wasn't hex
JMP  break_loop                        ; 005C  EB 14
is_hex_digit:
ADD  AL, 0x0A                          ; 005E  04 0A
is_digit:
; Shift the current nibble left
SHL  BL, 0x04                          ; 0060  C0 E3 04
ADD  BL, AL                            ; 0063  00 C3

; Increment the byte counter
INC  DL                                ; 0065  FE C2
CMP  DL, 0x02                          ; 0067  80 FA 02
JB   byte_loop                         ; 006A  82 BC

; Write the completed byte to memory
MOV  [ES:SI], BL                       ; 006C  26 88 1C
INC  SI                                ; 006F  46

; Loop until the program is finished
JMP  input_loop                        ; 0070  EB B2
break_loop:

; Copy the input program to disk
;   AH = 0x03 - write disk sectors
;   AL = 0x02 - write 2 sectors
;   CH = 0x00 - write cylinder 0
;   CL = 0x02 - write sector 2
;   DH = 0x00 - write head 0
;   DL = 0x00 - write drive 0
MOV  AX, 0x0301                        ; 0072  B8 01 03
XOR  BX, BX                            ; 0075  31 DB
MOV  CX, 0x0002                        ; 0077  B9 02 00
XOR  DX, DX                            ; 007A  31 D2
INT  0x13                              ; 007C  CD 13

; quit the monitor
CLI                                    ; 007E  FA
HLT                                    ; 007F  F4
; /===========================================================================\
; = END OF EDITOR PAYLOAD =====================================================
; \===========================================================================/
after_payload:

; Now that the payload is in place, we
; need to write it to the boot sector.
; First copy it to a clean area in
; memory
MOV  BX, 0x0200                        ; 0080  BB 00 02
MOV  ES, BX                            ; 0083  8E C3
XOR  SI, SI                            ; 0085  31 F6

XOR  DL, DL                            ; 0087  30 D2
copy_bootloader:
; Transfer the byte
MOV  AL, [CS:0x7C02+SI]                ; 0089  2E 8A 84 03 7C
MOV  [ES:SI], AL                       ; 008E  26 88 04
INC  SI                                ; 0091  46
INC  DL                                ; 0092  FE C2
CMP  DL, 0x1A                          ; 0094  80 FA 1C
JB   copy_bootloader                   ; 0097  72 F0
MOV  AX, 0xAA55                        ; 0099  B8 55 AA
MOV  [ES:0x01FE], AX                   ; 009C  26 A3 FE 01

; Copy the bootloader to disk
;   AH = 0x03 - write disk sectors
;   AL = 0x01 - write 1 sector
;   CH = 0x00 - write cylinder 0
;   CL = 0x01 - write sector 1
;   DH = 0x00 - write head 0
;   DL = 0x00 - write drive 0
MOV  AX, 0x0301                        ; 00A0  B8 01 03
XOR  BX, BX                            ; 00A3  31 DB
MOV  CX, 0x0001                        ; 00A5  B9 01 00
XOR  DX, DX                            ; 00A8  31 D2
INT  0x13                              ; 00AA  CD 13

; Now, we need to write the editor.
; Let's again copy it to a clean
; portion in memory before writing it
; to disk.
XOR  SI, SI                            ; 00AC  31 F6
XOR  DL, DL                            ; 00AE  30 D2
copy_editor:
; Transfer the byte
MOV  AL, [CS:0x7C1D+SI]                ; 00B0  2E 8A 84 1D 7C
MOV  [ES:SI], AL                       ; 00B5  26 88 04
INC  SI                                ; 00B8  46
INC  DL                                ; 00B9  FE C2
CMP  DL, 0x63                          ; 00BB  80 FA 63
JB  copy_editor                        ; 00BE  72 F0

; Copy the editor to disk
;    AH = 0x03 - write disk sectors
;    AL = 0x01 - write 1 sector
;    CH = 0x00 - write cylinder 0
;    CL = 0x02 - write sector 2
;    DH = 0x00 - write head 0
;    CL = 0x00 - write drive 0
MOV  AX, 0x0301                        ; 00C0  B8 01 03
XOR  BX, BX                            ; 00C3  31 DB
MOV  CX, 0x0002                        ; 00C5  B9 02 00
XOR  DX, DX                            ; 00C8  31 D2
INT  0x13                              ; 00CA  CD 13

; Quit the payload program
CLI                                    ; 00CC  FA
HLT                                    ; 00CD  F4

; This program is large enough that it's getting difficult to manage. Luckily,
; our ability to use both backspace and hex input should make life a lot easier
; while inputting it. The program compiles to 0xCD (205) bytes, and can be
; expressed in hexadecimal as:
;   EB 7E BB 00 01 8E C3 31 DB B8 02 02 31 DB B9 02 00 31 D2 CD 13 EA 00 00 00
;   01 FA F4 90 BB 00 02 8E C3 31 F6 31 DB 31 D2 B4 00 CD 16 3C 00 74 F8 B4 0E
;   CD 10 3C 08 75 12 80 FA 00 77 06 4E 26 8A 1C B2 02 FE CA C0 EB 04 EB DE 2C
;   30 3C 09 76 10 2C 11 3C 06 72 08 2C 20 3C 06 72 02 EB 14 04 0A C0 E3 04 00
;   C3 FE C2 80 FA 02 72 BC 26 88 1C 46 EB B2 B8 01 03 31 DB B9 02 00 31 D2 CD
;   13 FA F4 BB 00 02 8E C3 31 F6 30 D2 2E 8A 84 02 7C 26 88 04 46 FE C2 80 FA
;   1A 72 F0 B8 55 AA 26 A3 FE 01 B8 01 03 31 DB B9 01 00 31 D2 CD 13 31 F6 30
;   D2 2E 8A 84 1D 7C 26 88 04 46 FE C2 80 FA 63 72 F0 B8 01 03 31 DB B9 02 00
;   31 D2 CD 13 FA F4
