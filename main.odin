package main

import "core:os"
import "core:fmt"

reg_w_table: [8]string = {
    "ax",
    "cx",
    "dx",
    "bx",
    "sp",
    "bp",
    "si",
    "di",
}
reg_table: [8]string = {
    "al",
    "cl",
    "dl",
    "bl",
    "ah",
    "ch",
    "dh",
    "bh",
}

main :: proc() {
    if len(os.args) != 2 {
        fmt.println("Please provide path to file!")
        return
    }
    filepath := os.args[1]
    instruction_stream, ok := os.read_entire_file(filepath, context.allocator)
    if !ok {
        fmt.println("Could not read file.")
        return
    }
    assert(len(instruction_stream) % 2 == 0)
    fmt.println("bits 16\n")
    for i := 0; i < len(instruction_stream); i += 2 {
        opcode := instruction_stream[i] & 0b11111100
        d := instruction_stream[i] & 0b00000010 >> 1
        w := instruction_stream[i] & 0b00000001
        mod := instruction_stream[i+1] & 0b11000000 >> 6
        reg := instruction_stream[i+1] & 0b00111000 >> 3
        rm := instruction_stream[i+1] & 0b00000111
        switch opcode {
        case 0x88:
            if mod != 0b00000011 {
                fmt.printf("Not a register to register mov: %x \n", mod)
            }
            reg_decode: string
            rm_decode: string
            if w == 1 {
                reg_decode = reg_w_table[reg]
                rm_decode = reg_w_table[rm]
            } else {
                reg_decode = reg_table[reg]
                rm_decode = reg_table[rm]
            }
            if d == 1 {
                fmt.printf("mov %v, %v\n", reg_decode, rm_decode)
            } else {
                fmt.printf("mov %v, %v\n", rm_decode, reg_decode)
            }   
        case:
            fmt.printf("Unknown opcode: %x\n", opcode)
        }
    }
}