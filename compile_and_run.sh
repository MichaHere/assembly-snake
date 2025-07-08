#!/bin/bash

# Constants
program="window"
requirements=("gcc" "nasm")

# Check if all commands exist
for requirement in ${requirements[@]}; do
    if command -v $requirement &> /dev/null; then continue; fi

    echo "fatal: $requirement is not installed"
    exit 1
done

if [ ! -d build/ ]; then
    mkdir build
fi

# Assemble program into machine code
nasm $program.asm -f elf64 -o build/$program.o || exit 1

# Link the program using gcc
gcc build/$program.o -o build/$program -nostdlib -static || exit 1

# Run the program
./build/$program