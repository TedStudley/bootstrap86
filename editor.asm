; The program is now separated from the boot sector, we'll be able to write a
; much larger and more complicated editor. 
section .editor

; Start the routine by loading the OS from disk into the data location
_main:
  MOV  BX, 0x0200                      ; 0200  BB 00 02
  MOV  ES, BX                          ; 0203  8E C3
  CALL _load                           ; 0205  E8 A5 01

  XOR  SI, SI                          ; 0208  31 F6
  main_loop:
    ; Output the current data address
    MOV  BX, SI                        ; 020A  89 F3
    MOV  AL, BH                        ; 020C  88 FE
    CALL _puthb                        ; 020E  E8 3C 00
    MOV  AL, BL                        ; 0211  88 D8
    CALL _puthb                        ; 0213  E8 37 00
    MOV  AX, 0x0E20                    ; 0216  B8 20 0E
    INT  0x10                          ; 0219  CD 10

    ; Input and perform a command
    CALL _getche                       ; 021B  E8 18 00
    PUSH AX                            ; 021E  50
    MOV  AL, 0x20                      ; 021F  B0 20
    INT  0x10                          ; 0221  CD 10
    POP  AX                            ; 0223  58
    CALL _switch_input                 ; 0224  E8 6E 00

    CALL _endl                         ; 0227  E8 54 00
  JMP  main_loop                       ; 022A  EB DE

; /===========================================================================\
; == PADDING ==================================================================
  TIMES 10 DB 0x00                     ; 022C-0235  00..00
; \===========================================================================/

; Input a character and write it to the screen
_getche:
  getche_loop:
    MOV  AH, 0x00                      ; 0236  B4 00
    INT  0x16                          ; 0238  CD 16
    ; make sure we got anything
    CMP  AL, 0x00                      ; 023A  3C 00
    JE   getche_loop                   ; 023C  74 F8
  ; display the input character
  MOV  AH, 0x0E                        ; 023E  B4 0E
  INT  0x10                            ; 0240  CD 10
  RET                                  ; 0242  C3

; /===========================================================================\
; == PADDING ==================================================================
  TIMES 10 DB 0x00                     ; 0243-024C  00..00
; \===========================================================================/

; Output a hex byte to the screen
_puthb:
  ; Store all affected registers
  PUSH AX                              ; 024D  50
  PUSH BX                              ; 024E  53
  PUSH DX                              ; 024F  52

  ; Prepare to output each nibble
  XOR  BX, BX                          ; 0250  31 DB
  MOV  AH, 0x0E                        ; 0252  B4 0E
  MOV  BL, AL                          ; 0254  88 C3
  XOR  DL, DL                          ; 0256  30 D2
  puthb_loop:
    ; Shift a nibble onto the top byte
    SHL  BX, 0x04                      ; 0258  C1 E3 04
    MOV  AL, BH                        ; 025B  88 F8

    CMP  AL, 0x0A                      ; 025D  3C 0A
    JB   puthb_hex_digit               ; 025F  72 02
      ; Add 0x07 ('A' - '0' - 0x0A)
      ADD  AL, 0x07                    ; 0261  04 07
    puthb_hex_digit:
    ; Add 0x30 ('0')
    ADD  AL, 0x30                      ; 0263  04 30
    INT  0x10                          ; 0265  CD 10

    XOR  BH, BH                        ; 0267  30 FF
    INC  DL                            ; 0269  FE C2
    CMP  DL, 0x02                      ; 026B  80 FA 02
    JB   puthb_loop                    ; 026E  72 E8
  ; restore all affected registers
  POP  DX                              ; 0270  5A
  POP  BX                              ; 0271  5B
  POP  AX                              ; 0272  58
  RET                                  ; 0273  C3

; /===========================================================================\
; == PADDING ==================================================================
  TIMES 10 DB 0x00                     ; 0274-027D  00..00
; \===========================================================================/

; Output a newline to the screen
_endl:
  ; Store all affected registers
  PUSH AX                              ; 027E  50
  ; Carriage return to a new line
  MOV  AH, 0x0E                        ; 027F  B4 0E
  MOV  AL, 0x0A                        ; 0281  B0 0A
  INT  0x10                            ; 0283  CD 10
  MOV  AL, 0x0D                        ; 0285  B0 0D
  INT  0x10                            ; 0287  CD 10
  ; Restore all affected registers
  POP AX                               ; 0289  58
  RET                                  ; 028A  C3

; /===========================================================================\
; == PADDING ==================================================================
  TIMES 10 DB 0x00                     ; 028B-0294  00..00
; \===========================================================================/

; Switch on the input command
_switch_input:
  ; Jump to the switch start
  JMP switch_start                     ; 0295  EB 37

  goto_branch:
    CALL _goto                         ; 0297  E8 6B 00
    JMP  switch_break                  ; 029A  EB 5E
  input_branch:
    CALL _input                        ; 029C  E8 B2 00
    JMP  switch_break                  ; 029F  EB 59
  load_branch:
    CALL _load                         ; 02A1  E8 09 01
    JMP  switch_break                  ; 02A4  EB 54
  output_branch:
    CALL _output                       ; 02A6  E8 28 01
    JMP  switch_break                  ; 02A9  EB 4F
  quit_branch:
    CALL _quit                         ; 02AB  E8 47 01
    JMP  switch_break                  ; 02AE  EB 4A
  save_branch:
    CALL _save                         ; 02B0  E8 4E 01
    JMP  switch_break                  ; 02B3  EB 45
  ; Leave room for more options...
  TIMES 25 DB 0x90                     ; 02B5-02CD  90..90

  switch_start:
    ; Check for a 'g' (goto)
    CMP  AL, 0x67                      ; 02CE  3C 67
    JE   goto_branch                   ; 02D0  74 C5
    ; Check for an 'i' (input)
    CMP  AL, 0x69                      ; 02D2  3C 69
    JE   input_branch                  ; 02D4  74 C6
    ; Check for an 'l' (load)
    CMP  AL, 0x6C                      ; 02D6  3C 6C
    JE   load_branch                   ; 02D8  74 C7
    ; Check for an 'o' (output)
    CMP  AL, 0x6F                      ; 02DA  3C 6F
    JE   output_branch                 ; 02DC  74 C8
    ; Check for a 'q' (quit)
    CMP  AL, 0x71                      ; 02DE  3C 71
    JE  quit_branch                    ; 02E0  74 C9
    ; Check for an 's' (save)
    CMP  AL, 0x73                      ; 02E2  3C 73
    JE  save_branch                    ; 02E4  74 CA
    ; Leave room for more options...
    TIMES 20 DB 0x90                   ; 02E6-02F9  90..90

  switch_break:
  RET                                  ; 02FA  C3

; /===========================================================================\
; == PADDING ==================================================================
  TIMES 10 DB 0x00                     ; 02FB-0304  00..00
; \===========================================================================/

; goto a location in memory
_goto:
  ; Store all affected registers
  PUSH AX                              ; 0305  50
  PUSH BX                              ; 0306  53
  PUSH DX                              ; 0307  52

  XOR  BX, BX                          ; 0308  31 DB
  XOR  DX, DX                          ; 030A  31 D2
  goto_word_loop:
    ; Input the character
    CALL _getche                       ; 030C  E8 27 FF

    ; Check for backspace
    CMP  AL, 0x8                       ; 030F  3C 08
    JNE  goto_not_backspace            ; 0311  75 0E
      CMP  DL, 0x0                     ; 0313  80 FA 00
      JA   goto_not_first              ; 0316  77 02
        JMP  goto_word_loop            ; 0318  EB F2
      goto_not_first:
      DEC  DL                          ; 031A  FE CA
      SHR  BX, 0x4                     ; 031C  C1 EB 04
      JMP  goto_word_loop              ; 031F  EB EB
    goto_not_backspace:

    ; Subtract 0x30 ('0')
    SUB  AL, 0x30                      ; 0321  2C 30
    ; Check if we got 0-9
    CMP  AL, 0x9                       ; 0323  3C 09
    JNA  goto_is_digit                 ; 0325  76 0E
    ; Subtract 0x11 ('A' - '0')
    SUB  AL, 0x11                      ; 0327  2C 11
    ; Check if we got A-F
    CMP  AL, 0x6                       ; 0329  3C 06
    JNA  goto_is_hex_digit             ; 032B  76 06
    ; Subtract 0x20 ('a' - 'A')
    SUB  AL, 0x20                      ; 032D  2C 20
    ; Check if we got a-f
    CMP  AL, 0x6                       ; 032F  3C 06
    JNA  goto_is_hex_digit             ; 0331  76 00

    goto_is_hex_digit:
    ; Add 10 (0xA) to a hex digit A-F
    ADD  AL, 0xA                       ; 0333  04 0A
    goto_is_digit:

    ; Add to the current byte
    SHL  BX, 0x4                       ; 0335  C1 E3 04
    ADD  BL, AL                        ; 0338  00 C3

    ; Increment the byte counter
    INC  DL                            ; 033A  FE C2
    CMP  DL, 0x4                       ; 033C  80 FA 04
    JB   goto_word_loop                ; 033F  72 CB

  ; Move the completed word to SI
  MOV SI, BX                           ; 0341  89 DE

  ; Restore all affected registers
  POP  DX                              ; 0343  5A
  POP  BX                              ; 0344  5B
  POP  AX                              ; 0345  58
  RET                                  ; 0346  C3

; /===========================================================================\
; == PADDING ==================================================================
  TIMES 10 DB 0x00                     ; 0347-0350  00..00
; \===========================================================================/

; Input a hex string into memory
_input:
  ; Store all affected registers
  PUSH AX                              ; 0351  50
  PUSH BX                              ; 0352  53
  PUSH CX                              ; 0353  51

  input_loop:
    XOR  BX, BX                        ; 0354  31 DB
    XOR  DX, DX                        ; 0356  31 D2
    input_byte_loop:
      ; Input the character
      CALL _getche                     ; 0358  E8 D8 FE

      ; Check for backspace character
      CMP  AL, 0x08                    ; 035B  3C 08
      JNE  input_not_backspace         ; 035D  75 12
        ; pull up the previous nibble
        CMP  DL, 0x00                  ; 035F  80 FA 00
        JA   input_not_first           ; 0362  77 06
          ; jump back to last byte
          DEC  SI                      ; 0364  4E
          MOV  BL, [ES:SI]             ; 0365  25 8A 1C
          MOV  DL, 0x02                ; 0368  B2 02
        input_not_first:
        ; Decrement the loop counter
        DEC  DL                        ; 036A  FE CA
        SHR  BL, 0x04                  ; 036C  C0 EB 04
        JMP  input_byte_loop           ; 036F  EB E7
      input_not_backspace:

      ; Check for newline character
      CMP  AL, 0x0D                    ; 0371  3C 0D
      JNE  input_not_newline           ; 0373  75 02
        ; Finish input
        JMP  input_break               ; 0375  EB 28
      input_not_newline:

      ; Subtract 0x30 ('0')
      SUB  AL, 0x30                    ; 0377  2C 30
      ; See if we got 0-9
      CMP  AL, 0x09                    ; 0379  3C 09
      JNA  input_is_digit              ; 037B  76 10

      ; Subtract 0x11 ('A' - '0')
      SUB  AL, 0x11                    ; 037D  2C 11
      ; See if we got A-F
      CMP  AL, 0x06                    ; 037F  3C 06
      JNA  input_is_hex_digit          ; 0381  76 08

      ; Subtract 0x20 ('a' - 'A')
      SUB  AL, 0x20                    ; 0383  2C 20
      ; See if we got a-f
      CMP  AL, 0x06                    ; 0385  3C 06
      JNA  input_is_hex_digit          ; 0387  76 02

      ; Ignore non-hex characters
      JMP  input_byte_loop             ; 0389  EB CD

      input_is_hex_digit:
      ; Add 10 (0xA)
      ADD  AL, 0x0A                    ; 038B  03 0A
      input_is_digit:

      SHL  BL, 0x04                    ; 038D  C0 E3 04
      ADD  BL, AL                      ; 0390  00 C3

      ; Increment the byte counter
      INC  DL                          ; 0392  FE C2  
      CMP  DL, 0x02                    ; 0394  80 FA 02
      JB   input_byte_loop             ; 0397  72 BF

    ; Move the byte to memory
    MOV  [ES:SI], BL                   ; 0399  26 88 1C
    INC  SI                            ; 039C  46
    JMP  input_loop                    ; 039D  EB B5
  input_break:

  ; Restore all affected registers
  POP CX                               ; 039F  59
  POP BX                               ; 03A0  5B
  POP AX                               ; 03A1  58
  RET                                  ; 03A2  C3

; /===========================================================================\
; == PADDING ==================================================================
  TIMES 10 DB 0x00                     ; 03A3-03AC  00..00
; \===========================================================================/

; Load the OS from disk
_load:
  ; Store all affected registers
  PUSH AX                              ; 03AD  50
  PUSH BX                              ; 03AE  53
  PUSH CX                              ; 03AF  51
  PUSH DX                              ; 03B0  52
  PUSH ES                              ; 03B1  06

  ; Actually read the OS from disk
  MOV  BX, 0x0200                      ; 03B2  BB 00 02
  MOV  ES, BX                          ; 03B5  8E C3
  ; Read the OS from disk
  ;   AH = 0x02 - read disk sectors
  ;   AL = 0x02 - read 2 sectors
  ;   CH = 0x00 - read cylinder 0
  ;   CL = 0x02 - read sector 2
  ;   DH = 0x00 - read head 0
  ;   DL = 0x00 - read drive 0
  MOV  AX, 0x0202                      ; 03B7  B8 02 02
  XOR  BX, BX                          ; 03BA  31 DB
  MOV  CX, 0x0002                      ; 03BC  B9 02 00
  XOR  DX, DX                          ; 03BF  31 D2
  INT  0x13                            ; 03C1  CD 13

  ; Restore all affected registers
  POP  ES                              ; 03C3  07
  POP  DX                              ; 03C4  5A
  POP  CX                              ; 03C5  59
  POP  BX                              ; 03C6  5B
  POP  AX                              ; 03C7  58
  RET                                  ; 03C8  C3

; /===========================================================================\
; == PADDING ==================================================================
  TIMES 10 DB 0x00                     ; 03C9-03D2  00..00
; \===========================================================================/

_output:
  ; Store the affected registers
  PUSH SI                              ; 03D3  56
  PUSH BX                              ; 03D4  53

  XOR  BX, BX                          ; 03D5  31 DB
  output_loop:
    MOV  AL, [ES:SI+BX]                ; 03D7  26 8A 00
    CALL _puthb                        ; 03DA  E8 70 FE

    MOV  AL, 0x20                      ; 03DD  B0 20
    INT  0x10                          ; 03DF  CD 10

    INC  BL                            ; 03E1  FE C3
    CMP  BL, 0x08                      ; 03E3  80 FB 08
    JB   output_loop                   ; 03E6  72 EF

  ; Restore all affected registers
  POP  BX                              ; 03E8  5B
  POP  SI                              ; 03E9  5E
  RET                                  ; 03EA  C3

; /===========================================================================\
; == PADDING ==================================================================
  TIMES 10 DB 0x00                     ; 03EB-03F4  00..00
; \===========================================================================/

; Quit the OS
_quit:
  CLI                                  ; 03F5  FA
  HLT                                  ; 03F6  F4

; /===========================================================================\
; == PADDING ==================================================================
  TIMES 10 DB 0x00                     ; 03F7-0400  00..00
; \===========================================================================/

; Save the OS to disk
_save:
  ; Store all affected registers
  PUSH AX                              ; 0401  50
  PUSH BX                              ; 0402  53
  PUSH CX                              ; 0403  51
  PUSH DX                              ; 0404  52
  PUSH ES                              ; 0405  06

  MOV  BX, 0x0200                      ; 0406  BB 00 02
  MOV  ES, BX                          ; 0409  8E C3
  ; Write the OS to disk
  ;   AH = 0x03 - write disk sectors
  ;   AL = 0x02 - write 2 sectors
  ;   CH = 0x00 - write cylinder 0
  ;   CL = 0x02 - write sector 2
  ;   DH = 0x00 - write head 0
  ;   DL = 0x00 - write drive 0
  MOV  AX, 0x0302                      ; 040B  B8 02 03
  XOR  BX, BX                          ; 040E  41 DB
  MOV  CX, 0x0002                      ; 0410  B9 02 00
  XOR  DX, DX                          ; 0413  31 D2
  INT  0x13                            ; 0415  CD 13

  ; Restore all affected registers
  POP  ES                              ; 0417  07
  POP  DX                              ; 0418  5A
  POP  CX                              ; 0419  59
  POP  BX                              ; 041A  5B
  POP  AX                              ; 041B  58
  RET                                  ; 041C  C3

; At 0x21C (540) bytes, this program is likely the largest we'll have to input
; completely by hand. The hexadecimal representation of the program is:
;   55 AA BB 00 02 8E C3 E8 A5 01 31 F6 89 F3 88 F8 E8 3C 00 88 D8 E8 37 00 B8
;   20 0E CD 10 E8 18 00 50 B0 20 CD 10 58 E8 6E 00 E8 54 00 EB DE 00 00 00 00
;   00 00 00 00 00 00 B4 00 CD 16 3C 00 74 F8 B4 0E CD 10 C3 00 00 00 00 00 00
;   00 00 00 00 50 53 52 31 DB B4 0E 88 C3 30 D2 C1 E3 04 88 F8 3C 0A 72 02 04
;   07 04 30 CD 10 30 FF FE C2 80 FA 02 72 E8 5A 5B 58 C3 00 00 00 00 00 00 00
;   00 00 00 50 B4 0E B0 0A CD 10 B0 0D CD 10 58 C3 00 00 00 00 00 00 00 00 00
;   00 EB 37 E8 6B 00 EB 5E E8 B2 00 EB 59 E8 09 01 EB 54 E8 2A 01 EB 4F E8 47
;   01 EB 4A E8 4E 01 EB 45 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90
;   90 90 90 90 90 90 90 90 3C 67 74 C5 3C 69 74 C6 3C 6C 74 C7 3C 6F 74 C8 3C
;   71 74 C9 3C 73 74 CA 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90
;   90 90 C3 00 00 00 00 00 00 00 00 00 00 50 53 52 31 DB 31 D2 E8 27 FF 3C 08
;   75 0E 80 FA 00 77 02 EB F2 FE CA C1 EB 04 EB EB 2C 30 3C 09 76 0E 2C 11 3C
;   06 76 06 2C 20 3C 06 76 00 04 0A C1 E3 04 00 C3 FE C2 80 FA 04 72 CB 89 DE 
;   5A 5B 58 C3 00 00 00 00 00 00 00 00 00 00 50 53 51 31 DB 31 D2 E8 DB FE 3C
;   08 75 12 80 FA 00 77 06 4E 26 8A 1C B2 02 FE CA C0 EB 04 EB E7 3C 0D 75 02
;   EB 28 2C 30 3C 09 76 10 2C 11 3C 06 76 08 2C 20 3C 06 76 02 EB CD 04 0A C0
;   E3 04 00 C3 FE C2 80 FA 02 72 BF 26 88 1C 46 EB B5 59 5B 58 C3 00 00 00 00
;   00 00 00 00 00 00 50 53 51 52 06 BB 00 02 8E C3 B8 02 02 31 DB B9 02 00 31
;   D2 CD 13 07 5A 59 5B 58 C3 00 00 00 00 00 00 00 00 00 00 56 53 31 DB 26 8A
;   00 E8 70 FE B0 20 CD 10 FE C3 80 FB 08 72 EF 5B 5E C3 00 00 00 00 00 00 00
;   00 00 00 FA F4 00 00 00 00 00 00 00 00 00 00 50 53 51 52 06 BB 00 02 8E C3
;   B8 02 03 31 DB B9 02 00 31 D2 CD 13 07 5A 59 5B 58 C3
