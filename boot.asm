; This file contains our bootloader. We shouldn't find it necessary to change
; this portion too frequently, since the majority of the program logic will end
; up being called *from* the bootloader.
section .boot

; Set the load pointer to 0x0100:0x0000
MOV  BX, 0x0100                        ; 0000  BB 00 01
MOV  ES, BX                            ; 0003  8E C3
XOR  BX, BX                            ; 0005  31 DB
; Read the OS from disk
;   AH = 0x02 - read disk sectors
;   AL = 0x02 - read 2 sectors
;   CH = 0x00 - read cylinder 1
;   CL = 0x02 - read sector 2
;   DH = 0x00 - read head 0
;   DL = 0x00 - read drive 0
MOV  AX, 0x0202                        ; 0007  B8 02 02
XOR  BX, BX                            ; 000A  31 DB
MOV  CX, 0x0002                        ; 000C  B9 02 00
XOR  DX, DX                            ; 000F  31 D2
INT  0x13                              ; 0011  CD 13

; Transfer control over to the OS.
JMP  0x0100:0x0000                     ; 0013  EA 00 00 00 00 01

; /===========================================================================\
; == PADDING ==================================================================
TIMES 0x01FE - ($ - $$) DB 0           ; 0018-01FD  00..00
; \===========================================================================/

; Add the magic word to the end
DW   0xAA55                            ; 01FE  AA 55
