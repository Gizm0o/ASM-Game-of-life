section .bss
    grid resb 100         ; 10x10 grid
    new_grid resb 100     ; New grid for next generation

section .data
    rows equ 10
    cols equ 10
    generations equ 10    ; Number of generations to simulate

section .text
    global _start

_start:
    ; Initialize the grid with some pattern
    call initialize_grid

    ; Main loop for generations
    mov rcx, generations
main_loop:
    call compute_next_generation
    call copy_new_to_old
    dec rcx
    jnz main_loop

    ; Exit the program
    mov rax, 60          ; sys_exit
    xor rdi, rdi         ; exit code 0
    syscall

initialize_grid:
    ; Example: Initialize with a simple pattern
    mov byte [grid + 11], 1
    mov byte [grid + 12], 1
    mov byte [grid + 21], 1
    ret

compute_next_generation:
    xor rdi, rdi         ; i = 0
    xor rsi, rsi         ; j = 0
next_cell:
    mov rbx, rdi         ; Copy i
    imul rbx, rbx, cols  ; i * cols
    add rbx, rsi         ; i * cols + j
    mov al, [grid + rbx]
    call count_neighbors
    mov bl, al           ; Save the count of neighbors

    ; Apply rules of Game of Life
    cmp byte [grid + rbx], 1
    jne .dead_cell

    ; Alive cell
    cmp bl, 2
    je .stay_alive
    cmp bl, 3
    je .stay_alive
    jmp .die

.stay_alive:
    mov byte [new_grid + rbx], 1
    jmp .next_iteration

.die:
    mov byte [new_grid + rbx], 0
    jmp .next_iteration

.dead_cell:
    cmp bl, 3
    je .become_alive
    jmp .stay_dead

.become_alive:
    mov byte [new_grid + rbx], 1
    jmp .next_iteration

.stay_dead:
    mov byte [new_grid + rbx], 0

.next_iteration:
    inc rsi             ; j++
    cmp rsi, cols
    jl next_cell_row

    inc rdi             ; i++
    xor rsi, rsi        ; j = 0
    cmp rdi, rows
    jl next_cell
    ret

next_cell_row:
    jmp next_cell

count_neighbors:
    ; Count the number of live neighbors around (i, j)
    xor r8, r8          ; neighbor count = 0
    mov r9, rdi         ; Copy i to r9
    mov r10, rsi        ; Copy j to r10
    sub r9, 1           ; Start with (i-1)
    sub r10, 1          ; Start with (j-1)
    mov r11, 3          ; 3 rows to check

count_row:
    push r10            ; Save j position
    mov r12, 3          ; 3 columns to check
count_col:
    ; Check boundary conditions
    cmp r9, -1
    jl skip_cell
    cmp r9, rows
    jge skip_cell
    cmp r10, -1
    jl skip_cell
    cmp r10, cols
    jge skip_cell

    ; Check if it's the current cell
    cmp r9, rdi
    jne check_cell
    cmp r10, rsi
    je skip_cell

check_cell:
    ; Calculate the cell index and check if it's alive
    mov rbx, r9
    imul rbx, rbx, cols
    add rbx, r10
    cmp byte [grid + rbx], 1
    jne skip_cell
    inc r8             ; Increment neighbor count

skip_cell:
    inc r10            ; Move to next column
    dec r12            ; Decrement column counter
    jnz count_col      ; If more columns to check, repeat

    pop r10            ; Restore j position
    inc r9             ; Move to next row
    dec r11            ; Decrement row counter
    jnz count_row      ; If more rows to check, repeat

    mov al, r8b        ; Return neighbor count in al
    ret

copy_new_to_old:
    mov rdi, grid
    mov rsi, new_grid
    mov rcx, 100        ; 10x10 grid

copy_loop:
    mov al, [rsi]
    mov [rdi], al
    inc rdi
    inc rsi
    loop copy_loop
    ret
