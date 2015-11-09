; Now that we've separated the boot sector from the rest of the program, we'll
; be able to write a much larger and more complicated editor. Of course, since
; we have to re-enter our entire editor every time we iterate, the process will
; only become more painful as our editor becomes more complicated. Let's add
; some simple features to allow us to modify the pre-existing editor instead of
; starting from scratch each time.
;
; Let's take this time to split up some of the routines in our program as well,
; since in order to make modifications, we'll need to have some code caves
; present to add more code before/after certain routines.
;
; Aditionally, from now on we'll split up this file into several different
; parts which will all be included from this main file.

; /===========================================================================\
; == BOOT SECTOR ==============================================================
; \===========================================================================/
%include "boot.asm"


; /===========================================================================\
; == EDITOR SECTOR ============================================================
; \===========================================================================/
%include "editor.asm"
