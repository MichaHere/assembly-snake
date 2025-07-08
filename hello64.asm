BITS 64                                         ; use 64 bits
CPU X64                                         ; target x86_64 CPU family


section .data

message:        db  "Hello, 64 bit world!", 10  ; "10" declares a new line
message_len:    equ $ - message                 ; equal to the current position minus the message position


section .text
global _start

_start:
    call        print                           ; call the function

    mov         rax, 60                         ; call sys_exit
    mov         rdi, 0                          ; error code 0
    syscall                                     ; call kernel

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
