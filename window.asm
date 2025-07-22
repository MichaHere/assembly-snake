BITS 64                                         ; use 64 bits
CPU X64                                         ; target x86_64 CPU family

section .rodata

sun_path: db "/tmp/.X11-unix/X1", 0
static sun_path:data


section .text

%define AF_UNIX             1
%define SOCK_STREAM         1

%define SYSCALL_WRITE       1
%define SYSCALL_SOCKET      41
%define SYSCALL_CONNECT     42
%define SYSCALL_EXIT        60

; Create a UNIX socket and connect to the X11 server
; @returns Socket file descriptor
x11_connect_to_server:
static x11_connect_to_server:function
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

    sub         rsp, 112                        ; reserve space to store the sockaddr_un on the stack

    mov         WORD [rsp], AF_UNIX             ; set sockaddr_un.sun_family to AF_UNIX

    ; fill sockaddr_un.sun_path with "/tmp/.X11-unix/X0"
    lea         rsi, sun_path                   ; load the address of the string to rsi
    mov         r12, rdi                        ; save the socket file descriptor from rdi in r12
    lea         rdi, [rsp + 2]
    cld                                         ; more forward
    mov         ecx, 19                         ; length of string is 19 with null terminator
    rep         movsb                           ; copy

    ; connect to the server
    mov         rax, SYSCALL_CONNECT
    mov         rdi, r12                        ; restore the file descriptor to rdi
    lea         rsi, [rsp]

    %define SIZEOF_SOCKADDR_UN 2+108

    mov         rdx, SIZEOF_SOCKADDR_UN
    syscall

    cmp         rax, 0
    jne         exit_on_error

    mov         rax, rdi                        ; return the socket file descriptor

    ; function epilogue
    add         rsp, 112                        ; restore the stack
    pop         rbp                             ; restore base pointer
    ret

exit_on_error:
    ; exit program
    mov         rax, SYSCALL_EXIT
    mov         rdi, 1                          ; error code
    syscall

; Send the handshake to the X11 server and read the returned system information
; @param rdi The socket file descriptor
; @returns The window root id (uint32_t) in rax
x11_send_handshake:
static x11_send_handshake:function
    ; function prologue
    push        rbp                             ; push base pointer to the stack
    mov         rbp, rsp                        ; move the base pointer (rbp) to the current stack pointer (rsp)

    sub         rsp, 1<<15                      ; reserve space to store the system information on the stack



    ; function epilogue
    add         rsp, 1<<15                      ; restore the stack
    pop         rbp                             ; restore base pointer
    ret

_start:
global _start:function
    call x11_connect_to_server

    ; exit program
    mov         rax, SYSCALL_EXIT
    mov         rdi, 0                          ; error code
    syscall
