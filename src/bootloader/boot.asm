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
bdb_dir_entries_count:      dw 0e0h                     ; Number of root directory entries
bdb_total_sectors:          dw 2880                     ; Total number of sectors
bdb_media_descriptor_type:  db 0f0h                     ; Media descriptor type
bdb_sectors_per_fat:        dw 9                        ; Number of sectors per FAT
bdb_sectors_per_track:      dw 18                       ; Number of sectors per track
bdb_heads_count:            dw 2                        ; Number of heads
bdb_hidden_sectors:         dd 0                        ; Number of hidden sectors
bdb_total_sectors_large:    dd 0                        ; Large sector count (if > 65535)

; Extended BIOS Parameter Block (EBPB) for FAT12
ebpb_drive_number:          db 0                        ; Drive number
ebpb_reserved1:             db 0                        ; Reserved
ebpb_boot_signature:        db 29h                      ; Extended boot signature
ebpb_volume_id:             dd 12345678h                ; Volume ID (4 byte serial number)
ebpb_volume_label:          db 'TEST OS    '             ; Volume label (11 bytes)
ebpb_filesystem_type:       db 'FAT12   '                ; File system type (8 bytes)

start:
    jmp main         ; Jump to the main program entry point

; Function: puts
; Purpose: Print a null-terminated string pointed to by SI
puts:
    push si          ; Save SI register (used for string pointer)
    push ax          ; Save AX register (used during string printing)

.loop:
    lodsb            ; Load byte at address [SI] into AL and increment SI
    or al, al        ; Check if AL is zero (null terminator)
    jz .done         ; If zero, jump to .done to finish printing
    mov ah, 0x0e     ; BIOS teletype interrupt function (print character in AL)
    mov bh, 0        ; Set page number to 0 (default page)
    int 0x10         ; Call BIOS interrupt to print the character
    jmp .loop        ; Continue to the next character in the string

.done:
    pop ax           ; Restore original value of AX
    pop si           ; Restore original value of SI
    ret              ; Return to the caller

; Main program entry point
main:
    xor ax, ax       ; Clear AX register (set AX to 0)
    mov ds, ax       ; Set Data Segment (DS) to 0
    mov es, ax       ; Set Extra Segment (ES) to 0
    mov ss, ax       ; Set Stack Segment (SS) to 0
    mov sp, 0x7000   ; Set the Stack Pointer (SP) to 0x7000 (safe stack area)
    mov si, msg_hw   ; Load address of the message into SI
    call puts        ; Call the puts function to print the message
    hlt              ; Halt the CPU (stop execution)

; disk routines

; Convert LBA to CHS address
l 


; Null-terminated message string
msg_hw: db 'Hello, World!', ENDL, 0  ; Message followed by a newline and null terminator

; Fill remaining space in the boot sector with zeros
times 510-($-$$) db 0  ; Fill until the 510th byte (sector size is 512 bytes)

; Boot signature
dw 0xAA55             ; Boot sector signature (mandatory for BIOS boot)