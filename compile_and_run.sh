#!/bin/bash

# Constants

program="window"
run_prefix="./build/"
requirements=("gcc" "nasm")

# Functions

function help {
    echo "compile_and_run.sh script"
    echo "Usage:    bash compile_and_run.sh [option] ... "
    echo "Options:"
    echo "  -h --help               Current command"
    echo "  --debug                 Runs the compiled file in debug mode"
    echo "  --file=[file_name]      Use a specific file instead of the default"
}

function check_requirements {
    for requirement in ${requirements[@]}; do
        if command -v $requirement &> /dev/null; then continue; fi

        echo "fatal: $requirement is not installed"
        exit 1
    done
}

function compile {
    if [ ! -d build/ ]; then
        mkdir build
    fi

    # Assemble program into machine code
    nasm $program.asm -f elf64 -o build/$program.o || exit 1

    # Link the program using gcc
    gcc build/$program.o -o build/$program -nostdlib -static || exit 1
}

function change_default_file {
    file=$1
    extension="${file##*.}"
    
    if [ ! -f $file ]; then
        echo "Error: file does not exist"
        exit 1
    fi

    if [ "$extension" != "asm" ]; then 
        echo "Error: file extension must be '.asm'"
        exit 1
    fi
    
    program=${file:0:-4}
}

# Run

for flag in $@; do
    case $flag in
        -h|--help)
            help
            exit 0
        ;;
        --debug)
            run_prefix="strace ./build/"
        ;;
        --file=*)
            change_default_file "${flag#*=}"
        ;;
        *)
            help
            exit 1
        ;;
    esac
done

# Default

check_requirements
compile
$run_prefix$program