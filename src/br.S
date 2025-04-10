#include "sys_headers.h"

#define DEFAULT_MEM 40960

.intel_syntax noprefix

.text
.global _start

_start:

    #; Parse args:
    #; assume (second) arg is filename
    mov rax, 2           #; sys_open
    mov rdi, [rsp + 16]  #; rdi contains argv[1]
    mov rsi, O_RDONLY    #; flags
    mov rdx, O_RDONLY    #; mode
    syscall              #; rax contains fd
    test rax, rax
    jl exit

    # #; get filesize of argument
    mov rdi, rax        #; rdi := input_fd
    mov rax, 5          #; sys_fstat
    sub rsp, STAT_SIZE  #; stack space for struct stat
    mov rsi, rsp        #; struct stat *statbuf
    syscall
    test rax, rax
    jne exit

    #; map source file into memory
    mov r8,  rdi                    #; fd := source
    mov esi, [rsp + STAT_FS_OFFSET] #; rsi := filesize (bytes)
    mov rax, 9                      #; sys_mmap
    xor rdi, rdi                    #; addr
    mov rdx, PROT_READ              #; prot
    mov r10, MAP_PRIVATE            #; flags
    xor r9, r9                      #; offset
    syscall                         #; now have buffer at [rax]
    test rax, rax
    jl exit

    add rsp, STAT_SIZE #; remove struct stat from stack
    mov rbx, rax       #; rbx setup for main loop

    read_vm_mem:

    #; Read and setup vm (default memory)
    mov rsi, DEFAULT_MEM

    #; Assume n bytes is in rsi
    #; allocate memory, and put memory pointer in rsi
    alloc_vm:
    mov rax, 9                      #; sys_mmap
    mov rdx, PROT_READ | PROT_WRITE #; prot
    mov r10, MAP_PRIVATE | MAP_ANON #; flags
    mov r8, -1                      #; fd
    syscall                         #; rsi, r9, rdi already set

    cmp rax, -1 #; check failure
    je exit

    mov rsi, rax #; rsi contains memory pointer to first (lowest) cell
    dec rbx      #; instruction pointer incremented at start of loop

    #; We use:
    #;
    #; * rbx as an instruction pointer
    #; * rsi as a data pointer this way, syscalls will read/write to/from the vm memory
    #;
    #; And for now, don't protect memory (up to the bf programmer to ensure safety)

    main_loop:
    inc rbx       #; next instruction
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

    mov rdx, 1 #; n
    mov rax, 1 #; sys_write
    mov rdi, 1 #; stdout
    syscall    #; rsi already set

    jmp main_loop

    case_ipt:
    cmp al, ','
    jne case_fwd_z

    mov rdx, 1   #; n
    xor rax, rax #; sys_write
    mov rdi, 1   #; stdout
    syscall      #; rsi already set

    jmp main_loop

    case_fwd_z:
    cmp al, '['
    jne case_bwd_nz
    mov al, [rsi]
    test al, al
    jnz main_loop

    #; find the matching ']'
    mov rdi, 1
    xor rcx, rcx
    call match_bracket

    jmp main_loop

    case_bwd_nz:
    cmp al, ']'
    jne case_nul
    mov al, [rsi]
    test al, al
    jz main_loop

    #; find the matching '['
    mov rdi, -1
    xor rcx, rcx
    call match_bracket

    jmp main_loop

    case_nul:
    test al, al
    jne case_default

    xor rax, rax
    call exit

    case_default:
    #; mov rax, -1
    #; call exit
    jmp main_loop

#; Find the matching bracket
#; Given the current instruction in [rbx],
#;       the offset to move by in rdi
#;       the current bracket level in rcx
#; Bracket level increases with opening bracket
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
    test rcx, rcx
    jne next_pos
    ret

    next_pos:
    add rbx, rdi
    jmp match_bracket

#; Exit with code rax
exit:
    mov rdi, rax
    mov rax, 60
    syscall
    ret
