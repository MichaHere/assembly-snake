BITS 64                                         ; use 64 bits
CPU X64                                         ; target x86_64 CPU family

section .text

%define AF_UNIX         1
%define SOCK_STREAM     1

%define SYSCALL_SOCKET  41
%define SYSCALL_EXIT    60

global _start

_start:
    ; open unix socket
    mov         rax, SYSCALL_SOCKET
    mov         rdi, AF_UNIX                    ; unix socket family
    mov         rsi, SOCK_STREAM                ; stream oriented type
    mov         rdx, 0                          ; automatic protocol
    syscall

    ; exit program
    mov         rax, SYSCALL_EXIT
    mov         rdi, 0                          ; error code
    syscall
