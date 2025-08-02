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

    ; open unix socket: socket(2)
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

    ; connect to the server: connect(2)
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

    ; send the handshake to the x11 server: write(2)
    mov         rax, SYSCALL_WRITE
    mov         rdi, rdi
    lea         rsi, [rsp]
    mov         rdx, 12
    syscall

    cmp         rax, 12                         ; check if bytes were written
    jnz         exit_on_error

    ; read the response of the server (8 bytes at first): read(2)
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

    ; read the remaining response: read(2)
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

; Increment the global id
; @returns The new global id
x11_next_id:
static x11_next_id:function
    ; function prologue
    push        rbp                             ; push base pointer to the stack
    mov         rbp, rsp                        ; move the base pointer (rbp) to the current stack pointer (rsp)

    mov         eax, DWORD [id]                 ; get the current global id
    mov         edi, DWORD [id_base]            ; get the global id_base
    mov         edx, DWORD [id_mask]            ; get the global id_mask

    ; return id & id_mask | id_base
    and         eax, edx                        ; store id & id_mask in eax
    or          eax, edi                        ; store eax | id_base in eax

    add         DWORD [id], 1                   ; increment the global id

    ; function epilogue
    pop         rbp                             ; restore base pointer
    ret

; open the font on the x11 server
; @param rdi The socket file descriptor
; @param esi The font id
x11_open_font:
static x11_open_font:function
    ; function prologue
    push        rbp                             ; push base pointer to the stack
    mov         rbp, rsp                        ; move the base pointer (rbp) to the current stack pointer (rsp)

    %define OPEN_FONT_NAME_BYTE_COUNT       5
    %define OPEN_FONT_PADDING               ( ( 4 - ( OPEN_FONT_NAME_BYTE_COUNT % 4 ) ) % 4 )
    %define OPEN_FONT_PACKET_U32_COUNT      ( 3 + ( OPEN_FONT_NAME_BYTE_COUNT + OPEN_FONT_PADDING ) / 4 )
    %define X11_OP_REQ_OPEN_FONT            0x2d

    sub         rsp, 6*8                        ; reserve space for the message
    
    ; set font meta data
    mov         DWORD   [rsp + 0*4], X11_OP_REQ_OPEN_FONT | ( OPEN_FONT_NAME_BYTE_COUNT << 16 )
    mov         DWORD   [rsp + 1*4], esi
    mov         DWORD   [rsp + 2*4], OPEN_FONT_NAME_BYTE_COUNT

    ; set font name
    mov         BYTE    [rsp + 3*4 + 0], 'f'
    mov         BYTE    [rsp + 3*4 + 1], 'i'
    mov         BYTE    [rsp + 3*4 + 2], 'x'
    mov         BYTE    [rsp + 3*4 + 3], 'e'
    mov         BYTE    [rsp + 3*4 + 4], 'd'

    ; send font to the x11 server
    mov         rax, SYSCALL_WRITE
    mov         rdi, rdi
    lea         rsi, [rsp]
    mov         rdx, OPEN_FONT_PACKET_U32_COUNT * 4
    syscall

    cmp         rax, OPEN_FONT_PACKET_U32_COUNT * 4
    jnz         exit_on_error

    ; function epilogue
    add         rsp, 6*8                        ; restore the stack
    pop         rbp                             ; restore base pointer
    ret


; Create a graphical context for x11
; @param rdi The socket file descriptor
; @param esi The graphical context id
; @param edx The window root id
; @param ecx The font id
x11_create_graphical_context:
static x11_create_graphical_context:function
    ; function prologue
    push        rbp                             ; push base pointer to the stack
    mov         rbp, rsp                        ; move the base pointer (rbp) to the current stack pointer (rsp)

    sub         rsp, 8*8                        ; reserve space for the message

    %define X11_OP_REQ_CREATE_GC        0x37
    %define X11_FLAG_GC_BG              0x00000004
    %define X11_FLAG_GC_FG              0x00000008
    %define X11_FLAG_GC_FONT            0x00004000
    %define X11_FLAG_GC_EXPOSE          0x00010000

    %define CREATE_GC_FLAGS             X11_FLAG_GC_BG | X11_FLAG_GC_FG | X11_FLAG_GC_FONT
    %define CREATE_GC_PACKET_FLAG_COUNT 3
    %define CREATE_GC_PACKET_U32_COUNT  ( 4 + CREATE_GC_PACKET_FLAG_COUNT )
    %define MY_RGB_COLOR                0x0000ffff

    ; create graphical context message
    mov     DWORD [rsp + 0*4], X11_OP_REQ_CREATE_GC | ( CREATE_GC_PACKET_U32_COUNT << 16 )
    mov     DWORD [rsp + 1*4], esi
    mov     DWORD [rsp + 2*4], edx
    mov     DWORD [rsp + 3*4], CREATE_GC_FLAGS
    mov     DWORD [rsp + 4*4], MY_RGB_COLOR
    mov     DWORD [rsp + 5*4], 0
    mov     DWORD [rsp + 6*4], ecx

    ; send message to the x11 server
    mov     rax, SYSCALL_WRITE
    mov     rdi, rdi
    lea     rsi, [rsp]
    mov     rdx, CREATE_GC_PACKET_U32_COUNT * 4
    syscall
    
    cmp     rax, CREATE_GC_PACKET_U32_COUNT * 4
    jnz     exit_on_error

    ; function epilogue
    add         rsp, 8*8                        ; restore the stack
    pop         rbp                             ; restore base pointer
    ret

; create an x11 window
; @param rdi The socket file descriptor
; @param esi The new window id
; @param edx The window root id
; @param ecx The root visual id
; @param r8d Packed window location (x and y)
; @param r9d Packed window dimensions (width and height)
x11_create_window:
static x11_create_window:function
    ; function prologue
    push        rbp                             ; push base pointer to the stack
    mov         rbp, rsp                        ; move the base pointer (rbp) to the current stack pointer (rsp)

    sub         rsp, 12*8                       ; reserve space for the message

    %define X11_OP_REQ_CREATE_WINDOW        0x01
    %define X11_FLAG_WIN_BG_COLOR           0x00000002
    %define X11_EVENT_FLAG_KEY_RELEASE      0x0002
    %define X11_EVENT_FLAG_EXPOSURE         0x8000
    %define X11_FLAG_WIN_EVENT              0x00000800

    %define CREATE_WINDOW_FLAG_COUNT        2
    %define CREATE_WINDOW_PACKET_U32_COUNT  ( 8 + CREATE_WINDOW_FLAG_COUNT )
    %define CREATE_WINDOW_BORDER            1
    %define CREATE_WINDOW_GROUP             1

    ; create window message
    mov         DWORD [rsp + 0*4], X11_OP_REQ_CREATE_WINDOW | ( CREATE_WINDOW_PACKET_U32_COUNT << 16 )
    mov         DWORD [rsp + 1*4], esi
    mov         DWORD [rsp + 2*4], edx
    mov         DWORD [rsp + 3*4], r8d
    mov         DWORD [rsp + 4*4], r9d
    mov         DWORD [rsp + 5*4], CREATE_WINDOW_GROUP | ( CREATE_WINDOW_BORDER << 16 )
    mov         DWORD [rsp + 6*4], ecx
    mov         DWORD [rsp + 7*4], X11_FLAG_WIN_BG_COLOR | X11_FLAG_WIN_EVENT
    mov         DWORD [rsp + 8*4], 0
    mov         DWORD [rsp + 9*4], X11_EVENT_FLAG_KEY_RELEASE | X11_EVENT_FLAG_EXPOSURE

    ; send message to the x11 server
    mov         rax, SYSCALL_WRITE
    mov         rdi, rdi
    lea         rsi, [rsp]
    mov         rdx, CREATE_WINDOW_PACKET_U32_COUNT * 4
    syscall

    cmp         rax, CREATE_WINDOW_PACKET_U32_COUNT * 4
    jnz         exit_on_error

    ; function epilogue
    add         rsp, 12*8                       ; restore the stack
    pop         rbp                             ; restore base pointer
    ret

; map an x11 window
; @param rdi The socket file descriptor
; @param esi The window id
x11_map_window:
static x11_map_window:function
    ; function prologue
    push        rbp                             ; push base pointer to the stack
    mov         rbp, rsp                        ; move the base pointer (rbp) to the current stack pointer (rsp)

    sub         rsp, 16                         ; reserve space for the message

    %define X11_OP_REQ_MAP_WINDOW   0x08
    
    ; create message 
    mov         DWORD [rsp + 0*4], X11_OP_REQ_MAP_WINDOW | ( 2 << 16 )
    mov         DWORD [rsp + 1*4], esi

    ; send message to the x11 server
    mov         rax, SYSCALL_WRITE
    mov         rdi, rdi
    lea         rsi, [rsp]
    mov         rdx, 2*4
    syscall

    cmp         rax, 2*4
    jnz         exit_on_error

    ; function epilogue
    add         rsp, 16                         ; restore the stack
    pop         rbp                             ; restore base pointer
    ret

exit_on_error:
    ; exit program: exit(1)
    mov         rax, SYSCALL_EXIT
    mov         rdi, 1                          ; error code
    syscall

_start:
global _start:function
    call x11_connect_to_server
    call x11_send_handshake

    ; exit program: exit(0)
    mov         rax, SYSCALL_EXIT
    mov         rdi, 0                          ; error code
    syscall
