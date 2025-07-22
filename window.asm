BITS 64                                         ; use 64 bits
CPU X64                                         ; target x86_64 CPU family

section .text

%define AF_UNIX         1
%define SOCK_STREAM     1

%define SYSCALL_SOCKET  41
%define SYSCALL_EXIT    60

; Create a UNIX socket and connect to the X11 server
; @returns Socket file descriptor
connect_to_x11_server:
static connect_to_x11_server:function
    ; function prologue
    push        rbp                             ; push base pointer to the stack
    mov         rbp, rsp                        ; move the base pointer (rbp) to the current stack pointer (rsp)

    ; open unix socket
    mov         rax, SYSCALL_SOCKET
    mov         rdi, AF_UNIX                    ; unix socket family
    mov         rsi, SOCK_STREAM                ; stream oriented type
    mov         rdx, 0                          ; automatic protocol
    syscall

    cmp         rax, 0
    jle         exit_on_error

    mov         rdi, rax                        ; store socket file descriptor in the rdi register

    ; function epilogue
    pop rbp                                     ; retore base pointer
    ret

exit_on_error:
    call connect_to_x11_server

    ; exit program
    mov         rax, SYSCALL_EXIT
    mov         rdi, 1                          ; error code
    syscall

_start:
global _start:function
    ; exit program
    mov         rax, SYSCALL_EXIT
    mov         rdi, 0                          ; error code
    syscall
