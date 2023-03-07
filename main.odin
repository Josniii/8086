package main

import "core:os"
import "core:fmt"

reg_word_table: [8]string = {
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
rm_table: [8]string = {
    "bx + si",
    "bx + di",
    "bp + si",
    "bp + di",
    "si",
    "di",
    "bp",
    "bx",
}

Opcode :: enum u8 {
    RegOrMemToOrFromReg = 0x88,
    ImmediateToRegOrMem = 0xC6,
    ImmediateToReg = 0xB0,
    MemToAcc = 0xA0,
    AccToMem = 0xA2,
}

main :: proc() {
    if len(os.args) != 2 {
        fmt.println("Please provide path to file!")
        return
    }
    filepath := os.args[1]
    bytes, ok := os.read_entire_file(filepath, context.allocator)
    if !ok {
        fmt.println("Could not read file.")
        return
    }
    fmt.println("bits 16\n")
    for i := 0; i < len(bytes); i += 1 {
        instruction := bytes[i]
        using Opcode
        switch {
        case instruction & 0b1111_1100 == u8(RegOrMemToOrFromReg):
            fmt.println("; REGISTER/MEMORY TO/FROM REGISTER")
            destination := instruction & 0b10 >> 1
            word := instruction & 1
            i += 1
            mod := bytes[i] & 0b1100_0000 >> 6
            reg := bytes[i] & 0b11_1000 >> 3
            rm := bytes[i] & 0b111
            reg_decode: string
            rm_decode: string
            if word == 1 {
                reg_decode = reg_word_table[reg]
            } else {
                reg_decode = reg_table[reg]
            }
            rm_decode, i = decode_rm_field(rm, reg, mod, word, i, &bytes)
            if destination == 1 {
                fmt.printf("mov %v, %v\n", reg_decode, rm_decode)
            } else {
                fmt.printf("mov %v, %v\n", rm_decode, reg_decode)
            }
        case instruction & 0b1111_1110 == u8(ImmediateToRegOrMem):
            fmt.println("; IMMEDIATE TO REGISTER/MEMORY")
            word := instruction & 1
            i += 1
            mod := bytes[i] & 0b1100_0000 >> 6
            rm := bytes[i] & 0b111
            rm_decode: string
            rm_decode, i = decode_rm_field(rm, 0, mod, word, i, &bytes)
            immediate_decode: string
            if (word == 1) {
                immediate := u16(bytes[i+1]) | (u16(bytes[i+2]) << 8)
                immediate_decode = fmt.tprintf("word %v", immediate)
                i += 2
            } else {
                immediate := bytes[i+1]
                immediate_decode = fmt.tprintf("byte %v", immediate)
                i += 1
            }
            fmt.printf("mov %v, %v\n", rm_decode, immediate_decode)
        case instruction & 0b1111_0000 == u8(ImmediateToReg):
            fmt.println("; IMMEDIATE TO REGISTER")
            word := instruction & 0b1000 >> 3
            reg := instruction & 0b0111
            reg_decode: string
            immediate: u16
            if word == 1 {
                reg_decode = reg_word_table[reg]
                immediate = u16(bytes[i+1]) | (u16(bytes[i+2]) << 8)
                i += 2
            } else {
                reg_decode = reg_table[reg]
                immediate = u16(bytes[i+1])
                i += 1
            }
            fmt.printf("mov %v, %v\n", reg_decode, immediate)
        case instruction & 0b1111_1110 == u8(MemToAcc):
            fmt.println("; MEMORY TO ACCUMULATOR")
            word := instruction & 0b0000_0001
            addr: u16
            addr, i = decode_acc_addr(word, i, &bytes)
            fmt.printf("mov ax, [%v]\n", addr)
        case instruction & 0b1111_1110 == u8(AccToMem):
            fmt.println("; ACCUMULATOR TO MEMORY")
            word := instruction & 0b0000_0001
            addr: u16
            addr, i = decode_acc_addr(word, i, &bytes)
            fmt.printf("mov [%v], ax\n", addr)
        case:
            fmt.printf("; Unknown instruction byte: %x\n", instruction)
        }
    }
}

decode_rm_field :: proc(rm: u8, reg: u8, mod: u8, word: u8, i: int, p_bytes: ^[]u8) -> (rm_decode: string, new_index: int) {
    bytes := p_bytes^
    switch mod {
        case 0b11: // Register mode
            if word == 1 {
                rm_decode = reg_word_table[rm]
            } else {
                rm_decode = reg_table[rm]
            }
        case 0b10: // Memory mode, 16 bit displacement
            displacement := i16(bytes[i+1]) | (i16(bytes[i+2]) << 8)
            rm_decode = fmt.tprintf("[%v + %v]", rm_table[rm], displacement)
            new_index = i + 2
        case 0b01: // Memory mode, 8 bit displacement
            displacement := i8(bytes[i+1])
            rm_decode = fmt.tprintf("[%v + %v]", rm_table[rm], displacement)
            new_index = i + 1
        case 0b00: // Memory mode, no displacement (except R/M = 0b110)
            if rm == 0b110 {
                direct_address := i16(bytes[i+1]) | (i16(bytes[i+2]) << 8)
                rm_decode = fmt.tprintf("[%v]", direct_address)
                new_index = i + 2
            } else if reg < 0b100 {
                rm_decode = fmt.tprintf("[%v]", rm_table[rm])
            } else {
                rm_decode = rm_table[rm]
            }
    }
    return rm_decode, new_index
}

decode_acc_addr :: proc(word: u8, i: int, p_bytes: ^[]u8) -> (addr: u16, new_index: int) {
    bytes := p_bytes^
    if word == 1 {
        addr = u16(bytes[i+1]) | (u16(bytes[i+2]) << 8)
        new_index = i + 2
    } else {
        addr = u16(bytes[i+1])
        new_index = i + 1
    }
    return addr, new_index
}