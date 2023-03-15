package sim8086

import "core:os"
import "core:fmt"

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
        instr := bytes[i]
        using Opcode8086
        switch {
            case instr & 0b1111_1100 == u8(MovRegOrMemToOrFromReg):
                i = reg_rm_instr(i, &bytes, false);
            case instr & 0b1111_1110 == u8(MovImmediateToRegOrMem):
                word := instr & 1
                i += 1
                mod, _, rm := extract_mod_rm(bytes[i])
                rm_decode, new_i := decode_rm_field(rm, mod, word, i, &bytes)
                i = new_i
                immediate_decode: string
                if word == 1 {
                    immediate := u16(bytes[i+1]) | (u16(bytes[i+2]) << 8)
                    immediate_decode = fmt.tprintf("word %v", immediate)
                    i += 2
                } else {
                    immediate := bytes[i+1]
                    immediate_decode = fmt.tprintf("byte %v", immediate)
                    i += 1
                }
                fmt.printf("mov %v, %v\n", rm_decode, immediate_decode)
            case instr & 0b1111_0000 == u8(MovImmediateToReg):
                word := instr & 0b1000 >> 3
                reg := instr & 0b0111
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
            case instr & 0b1111_1110 == u8(MovMemToAcc):
                word := instr & 0b1
                addr := u16(bytes[i+1]) | (u16(bytes[i+2]) << 8)
                i += 2
                if word == 1 {
                    fmt.printf("mov ax, [%v]\n", addr)
                } else {
                    fmt.printf("mov al, [%v]\n", addr)
                }
            case instr & 0b1111_1110 == u8(MovAccToMem):
                word := instr & 0b1
                addr := u16(bytes[i+1]) | (u16(bytes[i+2]) << 8)
                i += 2
                if word == 1 {
                    fmt.printf("mov [%v], ax\n", addr)
                } else {
                    fmt.printf("mov [%v], al\n", addr)
                }
            case instr & 0b1100_0100 == u8(ArithRegOrMemWithRegToEither):
                i = reg_rm_instr(i, &bytes, true)
            case instr & 0b1111_1100 == u8(ArithImmediateToRegOrMem):
                signed := instr & 0b10 >> 1
                word := instr & 1
                i += 1
                mod, arithmetic_opcode, rm := extract_mod_rm(bytes[i])
                arith_op := arith_op_table[arithmetic_opcode]
                rm_decode, new_i := decode_rm_field(rm, mod, word, i, &bytes)
                i = new_i
                immediate_decode: string
                if signed == 1 && word == 0 {
                    immediate := i8(bytes[i+1])
                    immediate_decode = fmt.tprintf("byte %v", immediate)
                    i += 1
                } else if signed == 1 {
                    immediate := i16(bytes[i+1])
                    immediate_decode = fmt.tprintf("word %v", immediate)
                    i += 1
                } else if word == 1 {
                    immediate := u16(bytes[i+1]) | (u16(bytes[i+2]) << 8)
                    immediate_decode = fmt.tprintf("word %v", immediate)
                    i += 2
                } else {
                    immediate := bytes[i+1]
                    immediate_decode = fmt.tprintf("byte %v", immediate)
                    i += 1
                }
                fmt.printf("%v %v, %v\n", arith_op, rm_decode, immediate_decode)
            case instr & 0b1100_0100 == u8(ArithImmediateToAcc):
                word := instr & 1
                arith_op := arith_op_table[instr & 0b0011_1000 >> 3]
                immediate: u16
                accumulator: string
                if word == 1 {
                    immediate = u16(bytes[i+1]) | (u16(bytes[i+2]) << 8)
                    accumulator = "ax"
                    i += 2
                } else {
                    immediate = u16(bytes[i+1])
                    accumulator = "al"
                    i += 1
                }
                fmt.printf("%v %v, %v\n", arith_op, accumulator, immediate)
            case instr == u8(JumpOnEqual): fallthrough
            case instr == u8(JumpOnLess): fallthrough
            case instr == u8(JumpOnLessOrEqual): fallthrough
            case instr == u8(JumpOnBelow): fallthrough
            case instr == u8(JumpOnBelowOrEqual): fallthrough
            case instr == u8(JumpOnParity): fallthrough
            case instr == u8(JumpOnOverflow): fallthrough
            case instr == u8(JumpOnSign): fallthrough
            case instr == u8(JumpOnNotEqual): fallthrough
            case instr == u8(JumpOnGreaterOrEqual): fallthrough
            case instr == u8(JumpOnGreater): fallthrough
            case instr == u8(JumpOnAboveOrEqual): fallthrough
            case instr == u8(JumpOnAbove): fallthrough
            case instr == u8(JumpOnNotPar): fallthrough
            case instr == u8(JumpOnNotOverflow): fallthrough
            case instr == u8(JumpOnNotSign): fallthrough
            case instr == u8(Loop): fallthrough
            case instr == u8(LoopWhileZero):fallthrough
            case instr == u8(LoopWhileNotZero): fallthrough
            case instr == u8(JumpOnCXZero):
                i = cond_jump_instr(i, &bytes)
            case:
                fmt.printf("; Unknown instruction byte: %x\n", instr)
        }
    }
}

cond_jump_instr :: proc(i: int, p_bytes: ^[]u8) -> (new_i: int) {
    bytes := p_bytes^
    new_i = i + 1
    jump_increment := i8(bytes[new_i]) + 2
    if jump_increment >= 0 {
        fmt.printf("%v $+%v\n", lookup_jmp_mnemonic(Opcode8086(bytes[i])), jump_increment)
    } else {
        fmt.printf("%v $%v\n", lookup_jmp_mnemonic(Opcode8086(bytes[i])), jump_increment)
    }
    return new_i
}

reg_rm_instr :: proc(i: int, p_bytes: ^[]u8, is_arith_op: bool) -> (new_i: int) {
    bytes := p_bytes^
    direction := (bytes[i] & 0b10) >> 1
    word := bytes[i] & 1
    new_i = i + 1
    mod, reg, rm := extract_mod_rm(bytes[new_i])
    reg_decode, rm_decode: string
    if word == 1 {
        reg_decode = reg_word_table[reg]
    } else {
        reg_decode = reg_table[reg]
    }
    rm_decode, new_i = decode_rm_field(rm, mod, word, new_i, p_bytes)

    // Decode the type of op (MOV or an arithmetic instruction):
    op := "mov"
    if is_arith_op {
        op = arith_op_table[bytes[i] & 0b0011_1000 >> 3]
    }

    if direction == 1 {
        fmt.printf("%v %v, %v\n", op, reg_decode, rm_decode)
    } else {
        fmt.printf("%v %v, %v\n", op, rm_decode, reg_decode)
    }
    return new_i
}

extract_mod_rm :: proc(instr_byte: u8) -> (mod: u8, reg_or_opcode: u8, rm: u8) {
    mod = instr_byte & 0b1100_0000 >> 6
    reg_or_opcode = instr_byte & 0b11_1000 >> 3
    rm = instr_byte & 0b111
    return mod, reg_or_opcode, rm
}

decode_rm_field :: proc(rm: u8, mod: u8, word: u8, i: int, p_bytes: ^[]u8) -> (rm_decode: string, new_i: int) {
    bytes := p_bytes^
    new_i = i
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
            new_i += 2
        case 0b01: // Memory mode, 8 bit displacement
            displacement := i8(bytes[i+1])
            rm_decode = fmt.tprintf("[%v + %v]", rm_table[rm], displacement)
            new_i += 1
        case 0b00: // Memory mode, no displacement (except R/M = 0b110, which is direct addressing)
            if rm == 0b110 {
                direct_address := i16(bytes[i+1]) | (i16(bytes[i+2]) << 8)
                rm_decode = fmt.tprintf("[%v]", direct_address)
                new_i += 2
            } else {
                rm_decode = fmt.tprintf("[%v]", rm_table[rm])
            }
    }
    return rm_decode, new_i
}