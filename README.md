
    nasm hello64.asm -f elf64 -o hello64.o
    gcc hello64.o -o hello64 -nostdlib -static
    ./hello64
