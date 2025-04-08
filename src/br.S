#include "sys_headers.h"

.intel_syntax noprefix

.data
    newline: .asciz "\n"
    default_mem: .int 40960

.text
.global _start

    // rax, rdx, rdi, rsi used for syscalls
    //
    // We use:
    // * rbx as an instruction pointer
    // * rsi as a data pointer
    //   this way, it will read/write to/from the vm memory
    // * rax for storing instructions/values from the vm memory
    //
    // And for now, don't protect memory (up to the bf programmer to ensure safety)

_start:

    // If > 1 arg, treat as number of bytes for vm
    mov rax, [rsp] # number of commandline args
    cmp rax, 1     # 1 arg -> just name of program
    je default_vm_mem

    read_vm_mem:

    // Read and setup vm

    jmp alloc_vm

    default_vm_mem:
    mov rsi, [default_mem]

    // Assume n bytes is in rsi
    // Allocate memory, and put memory pointer in rsi
    alloc_vm:
    mov rax, 9                      # mmap syscall no
    xor rdi, rdi                    # addr = null
    mov rdx, 0b111                  # prot = rwx
    mov r10, MAP_PRIVATE | MAP_ANON # flags = map_private | map_anon
    mov r8,  -1                     # fd = -1
    mov r9,  0                      # off = 0
    syscall

    cmp rax, -1 # check failure
    je exit

    mov r8, rax # r8 contains memory pointer to first (lowest) cell

    // We will simply read the program onto the stack
    push 0             #; put a nul-byte at the start of the program
    lea rbx, [rsp] #; save address just above first instruction we will use

    read_byte:                  #; read one byte at a time onto the stack
    dec rsp                     #; next address on stack
    lea rsi, [rsp]              #; prepare address for syscall
    call getch                  #; writes byte from stdin to top of stack
    mov al, [rsp]               #; nul-byte check the char just written
    cmp al, 0
    jne read_byte               #; loop if non-null
    and rsp, 0xFFFFFFFFFFFFFFF0 #; word-align stack

    # xor rax, rax
    # call exit

    mov rsi, r8 #; restore data pointer

    main_loop:
    dec rbx        #; next instruction
    mov al, [rbx] #; grab the current byte at the instruction pointer

    case_inc_ptr:
    cmp al, '>'
    jne case_dec_ptr

    inc rsi #; increment pointer

    jmp main_loop

    case_dec_ptr:
    cmp al, '<'
    jne case_inc_b

    dec rsi #; decrement pointer

    jmp main_loop

    case_inc_b:
    cmp al, '+'
    jne case_dec_b

    mov al, [rsi]
    inc al
    mov [rsi], al

    jmp main_loop

    case_dec_b:
    cmp al, '-'
    jne case_prt

    mov al, [rsi]
    dec al
    mov [rsi], al

    jmp main_loop

    case_prt:
    cmp al, '.'
    jne case_ipt

    call putch

    jmp main_loop

    case_ipt:
    cmp al, ','
    jne case_fwd_z

    call getch

    jmp main_loop

    case_fwd_z:
    cmp al, '['
    jne case_bwd_nz
    mov al, [rsi]
    cmp al, 0
    jnz main_loop

    # find the matching ']'
    mov rdi, -1
    xor rcx, rcx
    call match_bracket

    jmp main_loop

    case_bwd_nz:
    cmp al, ']'
    jne case_nul
    mov al, [rsi]
    cmp al, 0
    jz main_loop

    # find the matching '['
    mov rdi, 1
    xor rcx, rcx
    call match_bracket

    jmp main_loop

    case_nul:
    cmp al, 0
    jne case_default

    xor rax, rax
    call exit

    case_default:
    # mov rax, -1
    # call exit
    jmp main_loop

// Print backwards from [rsi]
# print_null_rev:
#
#     call putch         #; now, outputs rsi
#     mov bl, [rsi]      #; check the value of the single byte in [rsi]
#     cmp bl, 0
#     sub rsi, 1         #; prepare the next value
#     jne print_null_rev #; loop if not null
#
#     ret

// Find the matching bracket
// Given the current instruction in [rbx],
//       the offset to move by in rdi
//       the current bracket level in rcx
// Bracket level increases with opening bracket
match_bracket:

    mov al, [rbx]

    check_open:
    cmp al, '['
    jne check_close
    inc rcx
    jmp check_ret

    check_close:
    cmp al, ']'
    jne check_ret
    dec rcx

    check_ret:
    cmp rcx, 0
    jne next_pos
    ret

    next_pos:
    add rbx, rdi
    jmp match_bracket


// Exit with code rax
exit:
    mov rdi, rax
    mov rax, 60
    syscall
    ret

// Print a char at [rsi]
putch:
    enter 0, 0
    pop rdx
    mov rdx, 1
    call print_n
    push rdx
    leave
    ret

// Print a number at [rsi]
# putn:
#     enter 0, 0
#     push rsi
#     mov rax, [rsi]
#     add rax, '0'
#     push rax
#     lea rsi, [rbp]
#     call putch
#     add rsp, 8
#     pop rsi
#     leave
#     ret

// Print up to rdx bytes of a string from [rsi]
print_n:
    enter 0, 0
    push rax
    push rdi
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdi
    pop rax
    leave
    ret

// Get a char front stdin to [rsi]
getch:
    enter 0, 0
    push rax
    push rdi
    push rdx
    push rcx
    xor rax, rax #; sys_read
    xor rdi, rdi #; stdin
    mov rdx, 1   #; n
    syscall
    pop rcx
    pop rdx
    pop rdi
    pop rax
    leave
    ret

// Get the length of the string at [rsi] to rdx
strlen:
    enter 0, 0
    mov rdx, 0
    push rax
    push rsi

    strln_nz:
    # call putch
    mov al, [rsi]
    cmp al, 0

    je strln_z

    inc rsi
    inc rdx
    jmp strln_nz

    strln_z:
    pop rsi
    pop rax
    leave
    ret

// Print from [rsi]
print_null:
    enter 0, 0
    call strlen
    call print_n
    leave
    ret
