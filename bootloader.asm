%define __DiskType __DiskType_HDD
%define __DiskType_CD  0x00
%define __DiskType_HDD 0x80
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                       Boot Sector: 512 Bytes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;[ORG 0x7C00]
[BITS 16]

;section .data          ; for constant variables such as strings, placed at the end of file
;section .bss           ; for mutatable variables
section .text        ; the entry point
    global main

main:
    cli                                 ; clear interrupts while changing segment registers
    jmp 0x0000:ClearSegmentRegisters    ; ensure there is no offset buffer from 0x7c00
    ClearSegmentRegisters:
    xor ax, ax                          ; clearing segment register, moving the stack pointer to the entry point
    mov ss, ax
    mov dx, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov sp, main
    cld                                 ; clear direction flag, for reading strings from low to high memory address
    sti                                 ; enable iterrupts
    push ax                             ; reset the disk, so that ititial head/track/... are zero
    xor ax, ax
    mov dl, __DiskType_HDD              ; initialize the HDD (0x80) or CD (0x00)
    int 0x13
    pop ax
call A20LineTest
call EnableA20
call longModeSupportTest
mov al, 1               ; # of sectors to read
mov cl, 2               ; Starting sector
call readFromDisk
call secondSector
jmp $                   ; infinite loop to current location

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                       functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; printf
; Requires:
;    Memory address of the string in register `si`
printf:
    pusha
    printf_string_loop:
        mov al, [si]    ; Loads the character located at memory address `si`
        add si, 1       ; Increments memory address
        cmp al, 0       ; Ensure it's not the end of character
        jne printCharacter
    popa
    ret
    ;;; printCharacter
    ; Requires:
    ;    Memory address of the character in register `al`
    printCharacter:
        mov ah, 0x0e    ; Move cursor forward
        int 0x10        ; call print interupt
    jmp printf_string_loop

;;; readDisk
; Requires:
;    Number of sectors to read in register `al`
;    Starting sector-number in register `cl`
;    printf function
readFromDisk:
    pusha
    mov ah, 0x02    ; Read sectors from disk selected
    mov dl, __DiskType    ; 0x00 for image on floppy disk, iso on flash drive, iso on USB, iso on CD; 0x80 for Hard Disk; QEmu emulates HDD
    mov ch, 0       ; Starting cylinder 
    mov dh, 0       ; Starting head
    push bx         ; setting segment register to zero
    mov bx, 0
    mov es, bx
    pop bx
    mov bx, 0x7c00 + 512
    int 0x13        ; calling interrupt 0x13
    jc  readFromDisk_disk_err
    popa
    ret
    readFromDisk_disk_err:
        mov si, readFromDisk_disk_err_message
        call printf
        jmp $




; Tests if the A20-line is enabled
; Tests for memorry wrapping after memory address 0xFFFFF
;   Returns:
;        ax = 1: A20 is disabled
;        ax = 0: A20 is enabled
;
; Offset Range:     0x0000 - 0xFFFF
; Segment Range:    0x0000 - 0xF000
; _________________________________
; Final Address = Segment * 16 + Offset
; So: Addressable Range:    0x00000 - 0xFFFFF
; Notation: Segment:Offset
; Test A20 Line to find if A20 is disbled
A20LineTest:
    pusha
    ; 1st Comparison
    mov ax, [0x7DFE] ; Location of the magic number
    mov bx, 0xFFFF        ; Set segment register to 0xFFFF
    mov es, bx
    mov bx, 0x7E0E  ; Location of the magic number, stored in the offset
    mov dx, [es:bx]
    cmp ax, dx
    je A20LineTest_Continue
    A20LineTest_A20IsDisabled:
    popa
    mov ax, 1
    ret
    A20LineTest_Continue:
    ; 2nd Comparison; segment register is still 0XFFFF
    mov ax, [0x7DFF]    ; moving a byte over & checking again
    mov bx, 0x7E0F      ; Changing the offset
    mov dx, [es:bx]     
    cmp ax, dx
    jne A20LineTest_A20IsDisabled
    popa
    mov ax, 0
    ret


; Enables the A20 line if possible
;   Returns:
;       1 in ax if it fails
;       0 in ax if it fails
EnableA20:
    pusha
    ; Uncomment to Manually disable A20
    ;mov ax, 0x2400
    ;int 0x15
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Check if it's already enabled
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    call A20LineTest
    cmp ax, 1
    je EnableA20_Successful
    ; Enable using BIOS Method
    mov ax, 0x2401
    int 0x15
    call A20LineTest
    cmp ax, 1
    je EnableA20_Successful
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Enable using keyboard Controller Method
    ; win.tue.nl/~aeb/linux/kbd/scancodes-11.html
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cli
    call EnableA20_WaitForKeyboardCommand
    mov al, 0xAD    ; Disable the keyboard
    out 0x64, al
    call EnableA20_WaitForKeyboardCommand
    mov al, 0xD0    ; Read output port (P2)
    out 0x64, al
    call EnableA20_WaitForKeyboardData
    in al, 0x60     ; Read Data
    push ax
    call EnableA20_WaitForKeyboardCommand
    mov al, 0xD1    ; Write output port
    out 0x64, al
    call EnableA20_WaitForKeyboardCommand
    pop ax
    or al, 2        ; Mask the Data: set 2nd bit to 1: A20 enabled
    out 0x60, al    ; Write the Data
    call EnableA20_WaitForKeyboardCommand
    mov al, 0xAE    ; Enable the keyboard
    out 0x64, al
    call EnableA20_WaitForKeyboardCommand
    sti
    call A20LineTest
    cmp ax, 1
    je EnableA20_Successful
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Enable using fast A20 method
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    in al, 0x92
    or al, 2
    out 0x92, al
    call A20LineTest
    cmp al, 1
    je EnableA20_Successful
    jmp EnableA20_Failed
    EnableA20_WaitForKeyboardCommand:
    in al, 0x64
    test al, 2
    jnz EnableA20_WaitForKeyboardCommand
    ret
    EnableA20_WaitForKeyboardData:
    in al, 0x64
    test al, 1
    jz EnableA20_WaitForKeyboardData
    ret
    EnableA20_Successful:
    mov si, EnableA20_SuccessMsg
    call printf
    popa
    mov ax, 0
    ret
    EnableA20_Failed:
    mov si, EnableA20_FailedMsg
    call printf
    popa
    mov ax, 1
    ret




; Expecting the assembler to inser 0x66 and 0x67 automatically before instructions,
; to allow for use of 32-bit instruction & addresses sizes, while operating in 16-bit mode.
; 
longModeSupportTest:
    pusha
    ; Check if CPUID is supported
    ; en.wikipedia.org/wiki/CPUID
    pushfd              ; push eflag to stack
    pop eax
    mov ecx, eax
    xor eax, 1 << 21
    push eax
    popfd
    pushfd
    pop eax
    cmp eax, ecx
    je longModeSupportTest_CpuidIsNotSupported
    ; request highest extended function
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb longModeSupportTest_longModeIsNotSupported
    ; check if long mode is supported
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz longModeSupportTest_longModeIsNotSupported
    popa
    ret
    longModeSupportTest_CpuidIsNotSupported:
    mov si, longModeSupportTest_CpuidIsNotSupportedMsg
    jmp longModeSupportTest_exit
    longModeSupportTest_longModeIsNotSupported:
    mov si, longModeSupportTest_longModeIsNotSupportedMsg
    jmp longModeSupportTest_exit
    longModeSupportTest_exit:    
    call printf
    popa
    jmp $




readFromDisk_disk_err_message:                          db "Error loading disk.", 0x0A, 0x0D, 0
longModeSupportTest_CpuidIsNotSupportedMsg:             db "CPUID is NOT supported", 0x0A, 0x0D, 0
longModeSupportTest_longModeIsNotSupportedMsg:          db "Long mode is NOT supported", 0x0A, 0x0D, 0
EnableA20_SuccessMsg:                                   db "Enabled A20 Line", 0x0A, 0x0D, 0
EnableA20_FailedMsg:                                    db "Could not enable A20 Line", 0x0A, 0x0D, 0


; Padding to 510 bytes
times 510-($-$$) db 0
; Ending the boot sector with the magic number, 0x55AA
db 0x55, 0xAA


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                       2nd Sector
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
secondSector:
; PAE: Physical Address Extension
;       To Enable Long Mode & PAE: 
;               - Point 1st entry of each table: PML4 -> PDPT  -> PDT  -> PT  ->  Physical memorry
;               - Set PAE   (1<<5) in CR4 to enable Process Contex Identifiers
;               - Enable Long Mode vias EFER register that can be accessed via MSR number 0xC0000080
;               - Set PE & PG    (1<<0 | 1<<31) bit in CR0 to enable protected mode and paging
;               - If needed:
;                   - Set PCIDE (1<<17) in CR4 to enable Process Contex Identifiers
;               - Populate CR3 with PDBR (and PCIDE)
;               - CR3:
;                   - First 20 bits stores PDBR = physical location of the 1st entry in the table
;                   - Last 12 bits used as Process Context Identifier
; Extends VMemory supports to 256 TiB
;   4 Tables: 8 bytes/entry/table (Required space = 4096 * 4 = 16384 Bytes)
;       Page Map Level 4 Table: (Required space = 512*8 = 4096 Bytes)
;             . Contains 512 page-directory pointer tables
;             . Each entry is 8 bytes long
;       Page Directory Pointer Table:
;             . Contains 512 page-directory tables
;             . Each entry is 8 bytes long
;       Page Directory Table:
;             . Cointains 512 page tables
;             . Each entry is 8 bytes long
;       Page Tables:
;             . Contains 512 physical memory spots, 4KB each spot
;             . Each entry is 8 bytes long
PhysicalAddressExtension_Paging:
    cli
    ; Clears location where tables are stored, in this case at memory address 0x1000
    mov edi, 0x1000     ;
    mov cr3, edi        ; Store the location of the PAE
    xor eax, eax        ; start a loop
    mov ecx, 4096       ; repeat 4096
    rep stosd           ; Stores a DWord eax => Clears 4 bytes => needs to be excuted 4096 times to clear 16384 Bytes
    ; Point the tables to each other
    ; Page Map Level 4 Table            located @ 0x1000
    ; Page Directory Pointer Table      located @ 0x2000 
    ; Page Directory Table              located @ 0x3000 
    ; Page Tables                       located @ 0x4000 
    mov edi, 0x1000     ; Reset edi back to 0x1000
    mov DWord [edi], 0x2003     ; Point PML4 -> PDPT. Note that the first 2 bytes are already set
    add edi, 0x1000
    mov DWord [edi], 0x3003     ; Point PDPT -> PDT
    add edi, 0x1000
    mov DWord [edi], 0x4003     ; Point PDT -> PT
    add edi, 0x1000
    mov DWord ebx, 3            ; Initialize PT. Address 3 would be the begining of the memory 
    mov ecx, 512                ; repeat loop 512 times
    PhysicalAddressExtension_Paging_pageTableInitialization:
    mov DWord [edi], ebx        ; map begining of page table for current entry
    add ebx, 0x1000             ; add 4KB, for size of each entry
    add edi, 8                  ; advance to next entry in page table
    loop PhysicalAddressExtension_Paging_pageTableInitialization
    ; Enable PAE at CR4[5]
    mov eax, cr4
    or eax, 1<<5
    mov cr4, eax
    ; Activate Long Mode, via Extended Feature Enable Register (EFER[8]) that can be accessed
    ;  by using MSR number 0xC00000080
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1<<8   ; enable long mode
    wrmsr
    ;  Enable Paging and Protected Mode, to be in compatibility mode
    mov eax, cr0
    or eax, 1 << 31
    or eax, 1 << 0
    mov cr0, eax

    ; Load GDT
    lgdt [GDL_Pointer]
    ; Long Jump
    jmp GDT_Code:PhysicalAddressExtension_LongMode
    sti
    %include "./bootloader.gdt.asm"
    [bits 64]
    PhysicalAddressExtension_LongMode:
    VID_MEM equ 0xb8000
    ; VGA Mode:
    ; Clear Screen
    mov edi, VID_MEM
    mov rax, 0x1f201f201f201f20
    mov ecx, 500
    rep stosq
    ; Print "Done"
    mov rax, 0x1f651f6e1f6f1f44   
    mov [VID_MEM], rax
    hlt
; 64 bit codes frome here on
[bits 64]
jmp $



times 1024-($-$$)                       db 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                       3rd Sector
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

