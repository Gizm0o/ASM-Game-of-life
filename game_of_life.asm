%macro print 2
	mov eax, sys_write   ; Set syscall number for write
	mov edi, 1           ; Set stdout file descriptor
	mov rsi, %1          ; Set address of string/message to print (%1)
	mov edx, %2          ; Set length of string/message (%2)
	syscall               ; Invoke syscall to print
%endmacro

%macro clear_screen 0
	mov eax, sys_write   ; Set syscall number for write
	mov edi, 1           ; Set stdout file descriptor
	mov rsi, clear       ; Set address of "clear" escape sequence
	mov edx, clear_length; Set length of "clear" sequence
	syscall               ; Invoke syscall to clear screen
%endmacro

section .data
    row_cells       equ 16    ; Number of rows in grid
    column_cells    equ 64    ; Number of columns in grid
    array_length    equ row_cells * column_cells ; Total cells in grid

    ; Constants for cell states and control characters
    live            equ 'O'   ; 
    dead            equ ' '   ; 
    new_line        equ 10    ; ASCII code for newline character
    clear           db 27, "[2J", 27, "[H"  ; ANSI escape sequence to clear screen
    clear_length    equ $ - clear   ;

    ; Time specifications for nanosleep
    timespec:
        tv_sec  dq 0          ; Seconds part of time for nanosleep
        tv_nsec dq 200000000  ; Nanoseconds part of time for nanosleep

    sys_write       equ 1     ; Syscall number for write
    sys_nanosleep   equ 35    ; Syscall number for nanosleep
    sys_time        equ 201   ; Syscall number for time

section .bss
    cells1          resb array_length   ; Reserve space for cells array 1
    cells2          resb array_length   ; Reserve space for cells array 2

section .text
global _start

_start:
    ; Initialize the grid with random live and dead cells
    call generate_initial_cells

    ; Main loop to simulate generations of Game of Life
    .generate_cells:
        ; Clear the screen before printing each generation
        print clear, clear_length

        ; Print the current state of cells1
        mov rsi, cells1      ; Set source pointer to cells1
        mov edx, array_length; Set length to print
        print rsi, edx       ; Print cells1

        ; Pause briefly between generations
        mov eax, sys_nanosleep   ; Set syscall number for nanosleep
        mov edi, timespec        ; Set timespec struct address
        xor esi, esi             ; Set remaining time (not used)
        syscall                   ; Invoke syscall for nanosleep

        ; Clear the screen before updating for the next generation
        print clear, clear_length

        ; Calculate the next generation based on cells1
        mov rsi, cells1   ; Set source pointer to cells1
        mov rdi, cells2   ; Set destination pointer to cells2
        call update_cells ; Call subroutine to update cells

        ; Swap cell arrays for the next iteration
        xchg rsi, rdi     ; Exchange source and destination pointers

        ; Repeat indefinitely
        jmp .generate_cells

; Procedure to generate the initial state of cells1
generate_initial_cells:
    xor rdx, rdx   ; Clear rdx (counter for cells)
    .init_cell:
        ; For simplicity, using a pseudo-random method here to initialise cells1
        mov rax, sys_time   ; Get current time
        syscall              ; Invoke syscall for time

        ; Pseudo-randomly decide if cell is live or dead
        test rax, 1         ; Test lowest bit of returned time
        jz .cell_dead       ; If zero, cell is dead
        mov byte [cells1 + rdx], live   ; Set cell as live
        jmp .next_cell      ; Jump to next cell

    .cell_dead:
        mov byte [cells1 + rdx], dead   ; Set cell as dead

    .next_cell:
        inc rdx              ; Increment cell counter
        cmp rdx, array_length  ; Compare with total cells
        jl .init_cell        ; Loop until all cells initialized
    ret                     ; Return from subroutine

; Procedure to update cells for the next generation
update_cells:
    xor rdx, rdx   ; Clear rdx (counter for cells)
    .update_cell:
        ; Calculate neighbors and apply Game of Life rules
        movzx rcx, byte [rsi + rdx]   ; Current cell state

        ; Calculate live neighbors (including the current cell itself)
        movzx r8, byte [rsi + rdx - column_cells - 1] ; Top left
        add rcx, r8

        movzx r8, byte [rsi + rdx - column_cells]     ; Top middle
        add rcx, r8

        movzx r8, byte [rsi + rdx - column_cells + 1] ; Top right
        add rcx, r8

        movzx r8, byte [rsi + rdx - 1]                ; Left
        add rcx, r8

        movzx r8, byte [rsi + rdx + 1]                ; Right
        add rcx, r8

        movzx r8, byte [rsi + rdx + column_cells - 1] ; Bottom left
        add rcx, r8

        movzx r8, byte [rsi + rdx + column_cells]     ; Bottom middle
        add rcx, r8

        movzx r8, byte [rsi + rdx + column_cells + 1] ; Bottom right
        add rcx, r8

        ; Apply rules of Game of Life
        cmp byte [rsi + rdx], live   ; Check if current cell is live
        je .live_cell               ; Jump if live

        ; Current cell is dead
        cmp rcx, 3                  ; Check if exactly 3 live neighbors
        jne .cell_dead              ; Jump if not, cell remains dead
        mov byte [rdi + rdx], live  ; Set cell as live in next generation
        jmp .next_update            ; Jump to next cell update

    .live_cell:
        ; Current cell is live
        cmp rcx, 2                  ; Check if 2 or 3 live neighbors
        jne .cell_dead              ; Jump if not, cell dies
        mov byte [rdi + rdx], live  ; Set cell as live in next generation

    .cell_dead:
        mov byte [rdi + rdx], dead  ; Set cell as dead in next generation

    .next_update:
        inc rdx              ; Increment cell counter
        cmp rdx, array_length  ; Compare with total cells
        jl .update_cell      ; Loop until all cells updated
    ret                     ; Return from subroutine
