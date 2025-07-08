BITS 64                                         ; use 64 bits
CPU X64                                         ; target x86_64 CPU family


section .data

message:        db  "Hello, 64 bit world!", 10  ; "10" declares a new line
message_len:    equ $ - message                 ; equal to the current position minus the message position


section .text
global _start

_start:
    call        _print                          ; call the _print function

    mov         rax, 60                         ; call sys_exit
    mov         rdi, 0                          ; error code 0
    syscall                                     ; call kernel


_print:
    mov         rax, 1                          ; call sys_write
    mov         rdi, 1                          ; set the file descriptor to std_out
    mov         rsi, message                    ; set the message buffer
    mov         rdx, message_len                ; set the message size
    syscall                                     ; call the kernel

    mov         rax, 0                          ; set return code
    ret                                         ; return from the function
