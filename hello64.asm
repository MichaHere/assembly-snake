BITS 64                                         ; use 64 bits
CPU X64                                         ; target x86_64 CPU family


section .data

message:        db  "Hello, 64 bit world!", 10  ; "10" declares a new line
message_len:    equ $ - message                 ; equal to the current position minus the message position


section .text
global _start

_start:
    call        print

    mov         rax, 60                         ; call sys_exit
    mov         rdi, 0                          ; error code 0
    syscall                                     ; call kernel


print_hello:
    push        rbp                             ; save rbp on the stack
    mov         rbp, rsp                        ; move the base pointer (rbp) to the current stack pointer (rsp)

    sub         rsp, 16                         ; reserve 16 bytes on the stack
    mov         BYTE [rsp + 0], 'h'
    mov         BYTE [rsp + 1], 'e'
    mov         BYTE [rsp + 2], 'l'
    mov         BYTE [rsp + 3], 'l'
    mov         BYTE [rsp + 4], 'o'
    mov         BYTE [rsp + 5], 10

    mov         rax, 1                          ; set call to sys_write
    mov         rdi, 1                          ; set the file descriptor to std_out
    lea         rsi, [rsp]                      ; load address of the string to the rsi register
    mov         rdx, 6                          ; set the length of the string
    syscall

    add         rsp, 16                         ; restore the stack
    pop         rbp                             ; retore base pointer
    ret                                         ; return from function

print:
    push        rbp                             ; save rbp on the stack
    mov         rbp, rsp                        ; move the base pointer (rbp) to the current stack pointer (rsp)

    mov         rax, 1                          ; call sys_write
    mov         rdi, 1                          ; set the file descriptor to std_out
    mov         rsi, message                    ; set the message buffer
    mov         rdx, message_len                ; set the message size
    syscall                                     ; call the kernel

    mov         rax, 0                          ; set return code
    
    pop         rbp                             ; retore base pointer
    ret                                         ; return from the function
