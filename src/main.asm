                ; directive similar like preprocessor stuff
                ; instructions are instructions
org 0x7C00      ; directive that all addressess must be calculated with offset
bits 16         ; bits directive emits 16 bit code
                ; backwards compatibility directive for 8086 by starting in 16 bit mode


main:
    hlt

.halt:
    jmp .halt

                        ; db emits bytes directly (declare byte)
times 510-($-$$) db 0   ; $ is an current line offset, $$ is offset of curernt section
                        ; $-$$ is length of program thus far in bytes
dw 0AA55h               ; BIOS expects (512 byte in this case) first sector, with last two bytes 0AA55 for OS
                        ; dw = declare 2 byte word