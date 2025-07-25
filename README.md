# Assembly Snake
This is a snake game written in assembly for the x86_64 CPU family using the Linux kernel. 


## Requirements

* nasm
* gcc
* X11


## Running the program

To run the program you can run the `compile_and_run.sh` script

    bash compile_and_run.sh

or you can compile it manually using the following commands

    mkdir build
    nasm window.asm -f elf64 -o build/hwindowello64.o
    gcc build/window.o -o build/window -nostdlib -static
    ./build/window


## Resources

In order to get an X11 window running, [this blog post](https://gaultier.github.io/blog/x11_x64.html#2750592591-connecting-to-the-server) from Philippe Gaultier was a huge help. 