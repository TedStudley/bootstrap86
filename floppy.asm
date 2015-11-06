; Unfortunately, there's no way to start from absolutely nothing. To begin, we
; need a bare-bones monitor program which can read in raw machine code to be
; executed by the processor.

; Explicitly use 16-bit mode
BITS 16
; Align the program to be loaded correctly

MOV  BX, 0x0100
MOV  DS, BX
XOR  SI, SI

; Loop until end of input
input_loop:
XOR  BX, BX
XOR  DX, DX

byte_loop:
; Input a character
MOV  AH, 0x00
INT  0x16
CMP  AL, 0x00
JZ byte_loop
; Display the character to the screen
MOV  AH, 0x0E
INT  0x10

; Subtract 0x30 ('0') from the input value
SUB  AL, 0x30

; Break from the loop unless the input value was an octal digit
CMP  AL, 0x08
JNB  break_loop

; Add the lower three bits to the current value and shift left by three bits
SHL  BL, 0x03
ADD  BL, AL

; Increment the byte counter by 1
INC  DL
CMP  DL, 0x03
JB   byte_loop

; Write the completed byte to memory and increment the current pointer
MOV  [DS:SI], BL
INC  SI

; Loop until the program is loaded
JMP input_loop
break_loop:

; Execute the loaded program
XOR  SI, SI
PUSH DS
PUSH SI
RETF

; Add the magic word (0xAA55)
TIMES 0x0200 - 2 - ($ - $$) DB 0
DW   0xAA55

; We can use this program to bootstrap the next version, which will allow us
; to write to write our completed programs to a floppy disk. Eventually (once
; our programs grow to more than 0xFF bytes in size) we'll run into the issue
; that they'll end up overwriting the monitor, but we should have plenty of
; time to deal with that before then.
