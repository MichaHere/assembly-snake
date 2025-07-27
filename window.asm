BITS 64                                         ; use 64 bits
CPU X64                                         ; target x86_64 CPU family

section .data

id:             dd 0
static          id:data

id_base:        dd 0
static          id_base:data

id_mask:        dd 0
static          id_mask:data

root_visual_id: dd 0
static          root_visual_id:data


section .rodata

sun_path:   db "/tmp/.X11-unix/X1", 0
static      sun_path:data


section .text

%define AF_UNIX             1
%define SOCK_STREAM         1

%define SYSCALL_READ        0
%define SYSCALL_WRITE       1
%define SYSCALL_SOCKET      41
%define SYSCALL_CONNECT     42
%define SYSCALL_EXIT        60

; create a UNIX socket and connect to the X11 server
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

; send the handshake to the X11 server and read the returned system information
; @param rdi The socket file descriptor
; @returns The window root id (uint32_t) in rax
x11_send_handshake:
static x11_send_handshake:function
    ; function prologue
    push        rbp                             ; push base pointer to the stack
    mov         rbp, rsp                        ; move the base pointer (rbp) to the current stack pointer (rsp)

    sub         rsp, 1<<15                      ; reserve space to store the system information on the stack
    mov         BYTE [rsp + 0], 'l'             ; set order to little-endian
    mov         WORD [rsp + 2], 11              ; set major version to 11

    ; send the handshake to the x11 server
    mov         rax, SYSCALL_WRITE
    mov         rdi, rdi
    lea         rsi, [rsp]
    mov         rdx, 12
    syscall

    cmp         rax, 12                         ; check if bytes were written
    jnz         exit_on_error

    ; read the response of the server (8 bytes at first)
    ; use the stack for the read buffer
    mov         rax, SYSCALL_READ
    mov         rdi, rdi
    lea         rsi, [rsp]
    mov         rdx, 8
    syscall

    cmp         rax, 8                          ; check if server responded with 8 bytes
    jnz         exit_on_error

    cmp         BYTE [rsp], 1                   ; check if the server succeeded (the first byte should be 1)
    jnz         exit_on_error

    ; read the remaining response
    ; use the stack for the read buffer
    mov         rax, SYSCALL_READ
    mov         rdi, rdi
    lea         rsi, [rsp]
    mov         rdx, 1<<15
    syscall

    cmp         rax, 0                          ; check whether the server replied
    jle         exit_on_error

    ; set id_base globally
    mov         edx, DWORD [rsp + 4]
    mov         DWORD [id_base], edx

    ; set id_mask globally
    mov         edx, DWORD [rsp + 8]
    mov         DWORD [id_mask], edx

    ; read needed data and skip over the rest
    lea         rdi, [rsp]                      ; pointer that skips some data

    mov         cx, WORD [rsp + 16]             ; vendor length (v)
    movzx       rcx, cx

    mov         al, BYTE [rsp + 21]             ; number of formats (n)
    movzx       rax, al                         ; fill the rest of the register with zeroes to avoid garbage values
    imul        rax, 8                          ; multiply the number of formats by 8 (sizeof(format) == 8)

    add         rdi, 32                         ; skip over the connection setup
    add         rdi, rcx                        ; skip over the vendor invormation (v)

    ; skip over the padding
    add         rdi, 3
    add         rdi, -4

    add         rdi, rax                        ; skip over the format information (n*8)

    mov         eax, DWORD [rdi]                ; store and return the window root id

    ; set the root_visual_id globally
    mov         edx, DWORD [rdi + 32]
    mov         DWORD [root_visual_id], edx

    ; function epilogue
    add         rsp, 1<<15                      ; restore the stack
    pop         rbp                             ; restore base pointer
    ret

exit_on_error:
    ; exit program
    mov         rax, SYSCALL_EXIT
    mov         rdi, 1                          ; error code
    syscall

_start:
global _start:function
    call x11_connect_to_server
    call x11_send_handshake

    ; exit program
    mov         rax, SYSCALL_EXIT
    mov         rdi, 0                          ; error code
    syscall
