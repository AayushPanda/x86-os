org 0x7C00          ; Set the origin address to 0x7C00, where the BIOS loads the bootloader
bits 16             ; Use 16-bit instructions since we are in real mode

%define ENDL 0x0D, 0x0A  ; Define ENDL as a newline character pair (CRLF)

; FAT12 HEADER
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'               ; OEM Name
bdb_bytes_per_sector:       dw 512                      ; Bytes per sector
bdb_sectors_per_cluster:    db 1                        ; Sectors per cluster
bdb_reserved_sectors:       dw 1                        ; Number of reserved sectors
bdb_fat_count:              db 2                        ; Number of FATs
bdb_dir_entries_count:      dw 0x0e0                     ; Number of root directory entries
bdb_total_sectors:          dw 2880                     ; Total number of sectors
bdb_media_descriptor_type:  db 0x0f0                     ; Media descriptor type
bdb_sectors_per_fat:        dw 9                        ; Number of sectors per FAT
bdb_sectors_per_track:      dw 18                       ; Number of sectors per track
bdb_heads_count:            dw 2                        ; Number of heads
bdb_hidden_sectors:         dd 0                        ; Number of hidden sectors
bdb_total_sectors_large:    dd 0                        ; Large sector count (if > 65535)

; Extended BIOS Parameter Block (EBPB) for FAT12
ebpb_drive_number:          db 0                        ; Drive number
ebpb_reserved1:             db 0                        ; Reserved
ebpb_boot_signature:        db 0x29                      ; Extended boot signature
ebpb_volume_id:             dd 0x12345678                ; Volume ID (4 byte serial number)
ebpb_volume_label:          db 'TEST OS    '             ; Volume label (11 bytes)
ebpb_filesystem_type:       db 'FAT12   '                ; File system type (8 bytes)

start:
    jmp main         ; Jump to the main program entry point

; ------------------------- string printing ----------------------------

; Function: puts
; Purpose: Print a null-terminated string pointed to by SI
puts:
    push si          ; Save SI register (used for string pointer)
    push ax          ; Save AX register (used during string printing)

.loop:
    lodsb            ; Load byte at address [SI] into AL and increment SI
    or al, al        ; Check if AL is zero (null terminator)
    jz .done         ; If zero, jump to .done to finish printing
                    
                    ; BIOS teletype interrupt function (print character in AL)
    mov ah, 0x0e     
    mov bh, 0        ; Set page number to 0 (default page)
    int 0x10         ; Call BIOS interrupt to print the character
    jmp .loop        ; Continue to the next character in the string

.done:
    pop ax           ; Restore original value of AX
    pop si           ; Restore original value of SI
    ret              ; Return to the caller

; ------------------------- end string printing ----------------------------

; Main program entry point
main:
    xor ax, ax       ; Clear AX register (set AX to 0)
    mov ds, ax       ; Set Data Segment (DS) to 0
    mov es, ax       ; Set Extra Segment (ES) to 0
    
    ; Set Stack Segment (SS) to 0
    mov ss, ax       ; Set Stack Segment (SS) to 0
    mov sp, 0x7C00   ; Set the Stack Pointer (SP) to 0x7000 (safe stack area)

    ; reading from disk
    mov [ebpb_drive_number], dl
    mov ax, 1           ; read second sector
    mov cl, 1           ; read 1 sector
    mov bx, 0x7E00      ; store after bootloader
    call disk_read


    mov si, msg_hw   ; Load address of the message into SI
    call puts        ; Call the puts function to print the message
    
    cli
    hlt              ; Halt the CPU (stop execution)


; ------------------------------------- error handling --------------------------------------

floppy_read_error:
    mov si, msg_read_failed
    call puts
    jmp reboot_on_keypress

reboot_on_keypress:
    mov ah, 0       ; bios func to *wait* for keypress. keypress returns ascii code of pressed key to al
    int 0x16        ; call bios keyboard interrupt with above setting
    jmp 0xFFFF:0   ; go to end of memory / reset vector, initiating reset

; ------------------------------------- end error handling --------------------------------------

.halt:
    cli
    hlt

; ------------------------------------- disk routines --------------------------------------

; LBA -> CHS conversion
; Params:
;   - ax: LBA
; Output:
;   - cx (6 bits 0-5): sector = LBA%[sectors per track] + 1
;   - cx (10 bits 6-15): cylinder = (LBA/sectors per track) / heads
;   - dh: head  = (LBA/sectors per track) % heads
lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [bdb_sectors_per_track]    ; dx = (ax = dx:ax) % [sectors per track]
                                        ; ax = (ax = dx:ax) / [sectors per track]
    inc dx
    mov cx, dx                          ; cx = sector

    xor dx, dx
    div word [bdb_heads_count]          ; dx = head, ax = cylinder
    mov dh, dl                          ; dh = head (since head is less than half a word)
    mov ch, al                          ; ch = cylinder low byte
    shl ah, 6                           ; shift cylinder high byte to bits 6-7
    or  ch, ah                          ; ch = cylinder
    ; CX is of format 76543210 98543210 (cylinder wrapped around into bits 6-7)

    pop ax
    mov dl, al
    pop ax
    ret

; Disk reading with INT 13,2 - READ DISK SECTORS (https://stanislavs.org/helppc/int_13-2.html)
; Params:
;   - ax: LBA (for use with lba_to_chs)
;   - cl: number of sectors to read
;   - dl: drive number
;   - es:bx: target to store data (also out)
; Out:
;   AH = status  (see INT 13,STATUS)
;   AL = number of sectors read
;   CF = 0 if successful
;      = 1 if error

disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx                             ; since cx is used by lba_to_chs
    call lba_to_chs
    pop ax                              ; al = num sec to read
    mov ah, 0x02

    mov di, 3                           ; retry count

.retry:
    pusha                               ; save all reg
    stc                               ; carry flag for bios
    int 0x13
    jnc .done

    ; failed
    popa                        ; retore all
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppy_read_error

; restores and returns
.done:
    popa
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Disk reset with INT 13,0 - RESET DISK SYSTEM (https://stanislavs.org/helppc/int_13-0.html)
; params:   dl = drive number
;           ah = 0
disk_reset:
    pusha
    mov ah, 0
    int 0x13
    jc floppy_read_error
    popa
    ret

; ------------------------------------- end disk routines --------------------------------------

; Null-terminated message strings
msg_hw: db 'Boot successful', ENDL, 0  ; Message followed by a newline and null terminator
msg_read_failed: db 'Read operation from disk failed', ENDL, 0

; Fill remaining space in the boot sector with zeros
times 510-($-$$) db 0  ; Fill until the 510th byte (sector size is 512 bytes)

; Boot signature
dw 0xAA55             ; Boot sector signature (mandatory for BIOS boot)