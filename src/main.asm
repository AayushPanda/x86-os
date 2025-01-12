org 0x7C00              ; directive that all addressess must be calculated with offset
bits 16                 ; bits directive emits 16 bit code
                        ; backwards compatibility directive for 8086 by starting in 16 bit mode

%define ENDL 0x0D, 0x0A  ; CRNL

start:
    jmp main

; Prints a string to screen
; Params: 
;   - ds:si -> string
puts:
    push si
    push ax


.loop:
    lodsb               ; load single byte from DS:SI into (AL)/AX/EAX, si+=bytes loaded
    or al,al            ; flag register becomes zero if al or al = 0
    jz .done

    mov ah, 0x0e
    mov bh, 0
    int 0x10

    jmp .loop



; restore ax, si
.done:
    pop ax
    pop si
    ret

main:

    ; data segments es,ds initialised to 0
    mov ax, 0
    mov ds, ax
    mov es, ax

    ; set up stack
    mov ss, ax          ; stack starts at ax=0 temporarily
    mov sp, 0x7C00      ; os loaded in memory at 0x7C00, stack grows downward

    mov si, msg_hw
    call puts

    hlt

.halt:
    jmp .halt

msg_hw: db 'Hello, world!', ENDL, 0

                        ; db emits bytes directly (declare byte)
times 510-($-$$) db 0   ; $ is an current line offset, $$ is offset of curernt section
                        ; $-$$ is length of program thus far in bytes
dw 0x0AA55               ; BIOS expects (512 byte in this case) first sector, with last two bytes 0AA55 for OS
                        ; dw = declare 2 byte word