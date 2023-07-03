package oldmain

import "core:os"
import "core:fmt"

// CPU STATE
segment_override := -1
lock_flag := false
cpu_registers: [8]u16
segment_registers: [4]u16
memory: [65535]u8

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
    simulate := true
    fmt.println("bits 16\n")
    for i := 0; i < len(bytes); i += 1 {
        instr := bytes[i]
        using Opcode8086
        switch {
            //Full byte comparisons come first to avoid errs due to masks with multiple matches.
            case instr == u8(Xlat):
                fmt.println("xlat")
            case instr == u8(LoadEffectiveAddress):
                i = load_instr(i, &bytes, LoadInstruction.LEA)
            case instr == u8(LoadPointerToDs):
                i = load_instr(i, &bytes, LoadInstruction.LDS)
            case instr == u8(LoadPointerToEs):
                i = load_instr(i, &bytes, LoadInstruction.LES)
            case instr == u8(LoadAHWithFlags):
                fmt.println("lahf")
            case instr == u8(StoreAHIntoFlags):
                fmt.println("sahf")
            case instr == u8(PushFlags):
                fmt.println("pushf")
            case instr == u8(PopFlags):
                fmt.println("popf")
            case instr == u8(PopRegOrMem):
                i += 1
                mod, opcode, rm := extract_mod_rm(bytes[i])                
                rm_decode: string
                rm_decode, i = disassemble_rm(rm, mod, 1, i, &bytes)
                fmt.printf("pop word %v\n", rm_decode)
            case instr == u8(AsciiAdjustForAdd):
                fmt.println("aaa")
            case instr == u8(AsciiAdjustForSubtract):
                fmt.println("aas")
            case instr == u8(AsciiAdjustForMultiply):
                fmt.println("aam")
                i += 1
            case instr == u8(AsciiAdjustForDivide):
                fmt.println("aad")
                i += 1
            case instr == u8(DecimalAdjustForAdd):
                fmt.println("daa")
            case instr == u8(DecimalAdjustForSubtract):
                fmt.println("das")
            case instr == u8(ConvertByteToWord):
                fmt.println("cbw")
            case instr == u8(ConvertWordToDoubleWord):
                fmt.println("cwd")
            case instr == u8(CallDirectInSeg):
                ip_incr := (i16(bytes[i + 1]) | (i16(bytes[i + 2]) << 8))
                i += 2
                // i is the instruction pointer so the increment has to be added to i + 1
                ip := ip_incr + i16(i + 1)
                fmt.printf("call %v\n", ip)
            case instr == u8(JmpDirectInSeg):
                ip_incr := (i16(bytes[i + 1]) | (i16(bytes[i + 2]) << 8))
                i += 2
                // i is the instruction pointer so the increment has to be added to i + 1
                ip := ip_incr + i16(i + 1)
                fmt.printf("jmp %v\n", ip)
            case instr == u8(JmpDirectInSegShort):
                ip := i8(bytes[i + 1])
                i += 1
                fmt.printf("jmp %v\n", ip)
            case instr == u8(CallDirectInterSeg):
                ip := u16(bytes[i + 1]) | (u16(bytes[i + 2]) << 8)
                i += 2
                cs := u16(bytes[i + 1]) | (u16(bytes[i + 2]) << 8)
                i += 2
                fmt.printf("call %v:%v\n", cs, ip)
            case instr == u8(JmpDirectInterSeg):
                ip := u16(bytes[i + 1]) | (u16(bytes[i + 2]) << 8)
                i += 2
                cs := u16(bytes[i + 1]) | (u16(bytes[i + 2]) << 8)
                i += 2
                fmt.printf("jmp %v:%v\n", cs, ip)
            case instr == u8(ReturnInSeg):
                fmt.println("ret")
            case instr == u8(ReturnInSegAddImmediate):
                immediate := u16(bytes[i + 1]) | (u16(bytes[i + 2]) << 8)
                i += 2
                fmt.printf("ret %v\n", immediate);
            case instr == u8(ReturnInterSeg):
                fmt.println("retf")
            case instr == u8(ReturnInterSegAddImmediate):
                immediate := u16(bytes[i + 1]) | (u16(bytes[i + 2]) << 8)
                i += 2
                fmt.printf("retf %v\n", immediate);
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
            case instr == u8(InterruptTypeSpecified):
                interrupt_type := bytes[i + 1]
                i += 1
                fmt.printf("int %v\n", interrupt_type)
            case instr == u8(InterruptType3):
                fmt.println("int3")
            case instr == u8(InterruptOnOverflow):
                fmt.println("into")
            case instr == u8(InterruptReturn):
                fmt.println("iret")
            case instr == u8(ClearCarry):
                fmt.println("clc")
            case instr == u8(ComplementCarry):
                fmt.println("cmc")
            case instr == u8(SetCarry):
                fmt.println("stc")
            case instr == u8(ClearDirection):
                fmt.println("cld")
            case instr == u8(SetDirection):
                fmt.println("std")
            case instr == u8(ClearInterrupt):
                fmt.println("cli")
            case instr == u8(SetInterrupt):
                fmt.println("sti")
            case instr == u8(Halt):
                fmt.println("hlt")
            case instr == u8(BusLockPrefix):
                fmt.printf("lock ")
                lock_flag = true
            case instr == u8(Wait):
                fmt.println("wait")
            case instr & 0b1110_0111 == u8(SegmentOverridePrefix):
                segment_override = int(instr & 0b0001_1000 >> 3)
            case instr & 0b1111_1110 == u8(RepeatStr):
                fmt.printf("rep ")
            case instr & 0b1111_1110 == u8(MoveByteOrWord):
                if instr & 1 == 1 {
                    fmt.printf("movsw\n")
                } else {
                    fmt.printf("movsb\n")
                }
            case instr & 0b1111_1110 == u8(CompareByteOrWord):
                if instr & 1 == 1 {
                    fmt.printf("cmpsw\n")
                } else {
                    fmt.printf("cmpsb\n")
                }
            case instr & 0b1111_1110 == u8(ScanByteOrWord):
                if instr & 1 == 1 {
                    fmt.printf("scasw\n")
                } else {
                    fmt.printf("scasb\n")
                }
            case instr & 0b1111_1110 == u8(LoadByteOrWordToAcc):
                if instr & 1 == 1 {
                    fmt.printf("lodsw\n")
                } else {
                    fmt.printf("lodsb\n")
                }
            case instr & 0b1111_1110 == u8(StoreByteOrWordToAcc):
                if instr & 1 == 1 {
                    fmt.printf("stosw\n")
                } else {
                    fmt.printf("stosb\n")
                }
            case instr & 0b1111_1100 == u8(MovRmToOrFromReg):
                direction, word, mod, reg, rm: u8
                i, direction, word, mod, reg, rm = decode_reg_rm_instr(i, &bytes)
                reg_decode := reg_tables[word][reg]
                rm_decode: string
                rm_decode, i = disassemble_rm(rm, mod, word, i, &bytes)
                if direction == 1 {
                    fmt.printf("mov %v, %v", reg_decode, rm_decode)
                } else {
                    fmt.printf("mov %v, %v", rm_decode, reg_decode)
                }
                if simulate {
                    if direction == 1 {
                        old_value := cpu_registers[reg]
                        if mod == 0b11 {
                            cpu_registers[reg] = cpu_registers[rm]
                            fmt.printf(" ; %v:%x->%x", reg_decode, old_value, cpu_registers[reg])
                        }
                    } else if mod == 0b11 {
                        old_value := cpu_registers[rm]
                        cpu_registers[rm] = cpu_registers[reg]
                        fmt.printf(" ; %v:%x->%x", rm_decode, old_value, cpu_registers[rm])
                    }
                }
                fmt.println()
            case instr & 0b1111_1100 == u8(MovRmToOrFromSegReg):
                direction, _, mod, reg, rm: u8
                i, direction, _, mod, reg, rm = decode_reg_rm_instr(i, &bytes)
                reg_decode := seg_reg_table[reg]
                rm_decode: string
                rm_decode, i = disassemble_rm(rm, mod, 1, i, &bytes)
                if direction == 1 {
                    fmt.printf("mov %v, %v", reg_decode, rm_decode)
                } else {
                    fmt.printf("mov %v, %v", rm_decode, reg_decode)
                }
                if simulate {
                    if direction == 1 {
                        old_value := segment_registers[reg]
                        if mod == 0b11 {
                            segment_registers[reg] = cpu_registers[rm]
                            fmt.printf(" ; %v:%x->%x", reg_decode, old_value, segment_registers[reg])
                        }
                    } else if mod == 0b11 {
                        old_value := cpu_registers[rm]
                        cpu_registers[rm] = segment_registers[reg]
                        fmt.printf(" ; %v:%x->%x", rm_decode, old_value, cpu_registers[rm])
                    }
                }
                fmt.println()
            case instr & 0b1111_1110 == u8(MovImmediateToRm):
                rm_decode, immediate_decode: string
                opcode: u8;
                i, _, rm_decode, immediate_decode = immediate_mod_op_rm_instr(i, &bytes, 0)
                fmt.printf("mov %v, %v\n", rm_decode, immediate_decode)
            case instr & 0b1111_0000 == u8(MovImmediateToReg):
                word := instr & 0b1000 >> 3
                reg := instr & 0b0111
                reg_decode := reg_tables[word][reg]
                immediate: u16
                if word == 1 {
                    immediate = u16(bytes[i+1]) | (u16(bytes[i+2]) << 8)
                    i += 2
                } else {
                    immediate = u16(bytes[i+1])
                    i += 1
                }
                fmt.printf("mov %v, %v", reg_decode, immediate)
                if simulate {
                    if word == 1 {
                        old_value := cpu_registers[reg]
                        cpu_registers[reg] = immediate
                        fmt.printf(" ; %v:%x->%x", reg_tables[word][reg], old_value, cpu_registers[reg])
                    } else {
                        cpu_register := reg % 4 // al/ah, cl/ch, dl/dh, bl/dh are spaced 4 entries apart in the table.
                        old_value := cpu_registers[cpu_register]
                        if bool(reg & 0b100) {
                            cpu_registers[cpu_register] = (cpu_registers[cpu_register] & 0xFF) | (immediate << 8) 
                        } else {
                            cpu_registers[reg] = (cpu_registers[cpu_register] & 0xFF00) | immediate
                        }
                        fmt.printf(" ; %v:%x->%x", reg_tables[1][cpu_register], old_value, cpu_registers[cpu_register])
                    }
                    
                }
                fmt.println()
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
            case instr & 0b1111_0000 == u8(PushOrPopReg):
                pop := instr & 0b1000 >> 3
                reg := instr & 0b111
                if pop == 1 {
                    fmt.printf("pop %v\n", reg_tables[1][reg])
                } else {
                    fmt.printf("push %v\n", reg_tables[1][reg])
                }
            case instr & 0b1110_0110 == u8(PushOrPopSegmentReg):
                pop := instr & 0b1
                seg_reg := instr & 0b1_1000 >> 3
                if pop == 1 {
                    fmt.printf("pop %v\n", seg_reg_table[seg_reg])
                } else {
                    fmt.printf("push %v\n", seg_reg_table[seg_reg])
                }
            case instr & 0b1111_1110 == u8(XchgRegOrMemWithReg):
                word := instr & 1
                i += 1
                mod, reg, rm := extract_mod_rm(bytes[i])
                rm_decode: string
                rm_decode, i = disassemble_rm(rm, mod, word, i, &bytes)
                reg_decode := reg_tables[word][reg]
                if lock_flag {
                    fmt.printf("xchg %v, %v\n", rm_decode, reg_decode)
                } else {
                    fmt.printf("xchg %v, %v\n", reg_decode, rm_decode)
                }
            case instr & 0b1111_1000 == u8(XchgRegWithAcc):
                reg := instr & 0b111
                reg_decode := reg_tables[1][reg]
                fmt.printf("xchg ax, %v\n", reg_decode)
            case instr & 0b1111_0100 == u8(InOut):
                variable_port := instr & 0b1000 >> 3
                out := instr & 0b10 >> 1
                word := instr & 1
                reg := "al"
                if word == 1 {
                    reg = "ax"
                }
                if variable_port == 1 {
                    if out == 1 {
                        fmt.printf("out dx, %v\n", reg)
                    } else {
                        fmt.printf("in %v, dx\n", reg)
                    }
                } else {
                    i += 1
                    port := bytes[i]
                    if out == 1 {
                        fmt.printf("out %v, %v\n", port, reg)
                    } else {
                        fmt.printf("in %v, %v\n", reg, port)
                    }
                }
            case instr & 0b1100_0100 == u8(ArithRegOrMemWithRegToEither):
                direction, word, mod, reg, rm: u8
                i, direction, word, mod, reg, rm = decode_reg_rm_instr(i, &bytes)
                reg_decode := reg_tables[word][reg]
                rm_decode: string
                rm_decode, i = disassemble_rm(rm, mod, word, i, &bytes)
                op := arith_op_table[instr & 0b0011_1000 >> 3]
                if direction == 1 {
                    fmt.printf("%v %v, %v\n", op, reg_decode, rm_decode)
                } else {
                    fmt.printf("%v %v, %v\n", op, rm_decode, reg_decode)
                }
            case instr & 0b1111_1100 == u8(ArithImmediateToRegOrMem):
                signed := (instr & 0b10) >> 1
                rm_decode, immediate_decode: string
                opcode: u8;
                i, opcode, rm_decode, immediate_decode = immediate_mod_op_rm_instr(i, &bytes, signed)
                op := arith_op_table[opcode]
                fmt.printf("%v %v, %v\n", op, rm_decode, immediate_decode)
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
            case instr & 0b1111_1100 == u8(ShiftOrRotate):
                word := instr & 1
                variable_shift := instr & 0b10 >> 1
                i += 1
                mod, opcode, rm := extract_mod_rm(bytes[i])
                op := shift_op_table[opcode]
                rm_decode: string
                rm_decode, i = disassemble_rm(rm, mod, word, i, &bytes)
                shift_count := "1"
                if variable_shift == 1 {
                    shift_count = "cl"
                }
                if word == 1 {
                    fmt.printf("%v word %v, %v\n", op, rm_decode, shift_count)
                } else {
                    fmt.printf("%v byte %v, %v\n", op, rm_decode, shift_count)
                }
            case instr & 0b1111_1100 == u8(TestRmAndReg):
                direction, word, mod, reg, rm: u8
                i, direction, word, mod, reg, rm = decode_reg_rm_instr(i, &bytes)
                reg_decode := reg_tables[word][reg]
                rm_decode: string
                rm_decode, i = disassemble_rm(rm, mod, word, i, &bytes)
                if direction == 1 {
                    fmt.printf("test %v, %v\n", reg_decode, rm_decode)
                } else {
                    fmt.printf("test %v, %v\n", rm_decode, reg_decode)
                }
            case instr & 0b1111_1110 == u8(TestImmediateAndAcc):
                word := instr & 1
                if word == 1 {
                    immediate := u16(bytes[i+1]) | (u16(bytes[i+2]) << 8)
                    i += 2
                    fmt.printf("test ax, %v\n", immediate)
                } else {
                    immediate := bytes[i+1]
                    i += 1
                    fmt.printf("test al, %v\n", immediate)
                }
            case instr & 0b1111_0000 == u8(IncOrDecRegister):
                reg := instr & 0b111
                reg_decode := reg_tables[1][reg]
                dec := instr & 0b1000 >> 3
                if dec == 1 {
                    fmt.println("dec", reg_decode)
                } else {
                    fmt.println("inc", reg_decode)
                }
            case instr & 0b1111_1110 == u8(Group1RegOrRem):
                //Test op is an immediate op, different from all the others, so do a lookahead.
                if (bytes[i+1] & 0b0011_1000) == 0 {
                    opcode: u8
                    rm_decode, immediate_decode: string
                    i, opcode, rm_decode, immediate_decode = immediate_mod_op_rm_instr(i, &bytes, 0)
                    fmt.printf("test %v, %v\n", rm_decode, immediate_decode)
                    continue;
                }
                i = group_op_rm_instr(i, &bytes, 0)
            case instr & 0b1111_1110 == u8(Group2RegOrRem):
                i = group_op_rm_instr(i, &bytes, 1)
            case:
                fmt.printf("; Unknown instruction byte: %x\n", instr)
        }
        if lock_flag && instr != u8(BusLockPrefix) {
            lock_flag = false
        }
    }
    fmt.println("Final registers:")
    fmt.printf("    ax: %x (%v) \n", cpu_registers[Registers.ax], cpu_registers[Registers.ax])
    fmt.printf("    bx: %x (%v) \n", cpu_registers[Registers.bx], cpu_registers[Registers.bx])
    fmt.printf("    cx: %x (%v) \n", cpu_registers[Registers.cx], cpu_registers[Registers.cx])
    fmt.printf("    dx: %x (%v) \n", cpu_registers[Registers.dx], cpu_registers[Registers.dx])
    fmt.printf("    sp: %x (%v) \n", cpu_registers[Registers.sp], cpu_registers[Registers.sp])
    fmt.printf("    dp: %x (%v) \n", cpu_registers[Registers.bp], cpu_registers[Registers.bp])
    fmt.printf("    si: %x (%v) \n", cpu_registers[Registers.si], cpu_registers[Registers.si])
    fmt.printf("    di: %x (%v) \n", cpu_registers[Registers.di], cpu_registers[Registers.di])
    fmt.printf("    es: %x (%v) \n", segment_registers[SegmentRegisters.es], segment_registers[SegmentRegisters.es])
    fmt.printf("    cs: %x (%v) \n", segment_registers[SegmentRegisters.cs], segment_registers[SegmentRegisters.cs])
    fmt.printf("    ss: %x (%v) \n", segment_registers[SegmentRegisters.ss], segment_registers[SegmentRegisters.ss])
    fmt.printf("    ds: %x (%v) \n", segment_registers[SegmentRegisters.ds], segment_registers[SegmentRegisters.ds])
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

load_instr :: proc(i: int, p_bytes: ^[]u8, load_type: LoadInstruction) -> (new_i: int) {
    bytes := p_bytes^
    new_i = i + 1
    mod, reg, rm := extract_mod_rm(bytes[new_i])
    rm_decode: string
    rm_decode, new_i = disassemble_rm(rm, mod, 1, new_i, &bytes)
    reg_decode := reg_tables[1][reg]
    switch load_type {
        case .LEA:
            fmt.printf("lea %v, %v\n", reg_decode, rm_decode)
        case .LDS:
            fmt.printf("lds %v, %v\n", reg_decode, rm_decode)
        case .LES:
            fmt.printf("les %v, %v\n", reg_decode, rm_decode)
    }
    return new_i
}

group_op_rm_instr :: proc(i: int, p_bytes: ^[]u8, group: int) -> (new_i: int) {
    bytes := p_bytes^
    word := bytes[i] & 1
    new_i = i + 1
    mod, opcode, rm := extract_mod_rm(bytes[new_i])

    op := group_tables[group][opcode]
    
    rm_decode: string
    rm_decode, new_i = disassemble_rm(rm, mod, word, new_i, &bytes)
    if mod == 0b11 {
        fmt.printf("%v %v\n", op, rm_decode)
    } else {
        if word == 1 {
            fmt.printf("%v word %v\n", op, rm_decode)
        } else {
            fmt.printf("%v byte %v\n", op, rm_decode)
        }
    }
    return new_i
}

decode_reg_rm_instr :: proc(i: int, p_bytes: ^[]u8) -> (new_i: int, direction, word, mod, reg, rm: u8) {
    bytes := p_bytes^
    direction = (bytes[i] & 0b10) >> 1
    word = bytes[i] & 1
    new_i = i + 1
    mod, reg, rm = extract_mod_rm(bytes[new_i])
    return new_i, direction, word, mod, reg, rm
}

immediate_mod_op_rm_instr :: proc(i: int, p_bytes: ^[]u8, signed: u8) -> (new_i: int, opcode: u8, rm_decode, immediate_decode: string) {
    bytes := p_bytes^
    word := bytes[i] & 1
    new_i = i + 1
    mod, rm: u8
    mod, opcode, rm = extract_mod_rm(bytes[new_i])
    rm_decode, new_i = disassemble_rm(rm, mod, word, new_i, &bytes)
    if signed == 1 && word == 0 {
        immediate := i8(bytes[new_i + 1])
        immediate_decode = fmt.tprintf("byte %v", immediate)
        new_i += 1
    } else if signed == 1 {
        immediate := i16(bytes[new_i + 1])
        immediate_decode = fmt.tprintf("word %v", immediate)
        new_i += 1
    } else if word == 1 {
        immediate := u16(bytes[new_i + 1]) | (u16(bytes[new_i + 2]) << 8)
        immediate_decode = fmt.tprintf("word %v", immediate)
        new_i += 2
    } else {
        immediate := bytes[new_i + 1]
        immediate_decode = fmt.tprintf("byte %v", immediate)
        new_i += 1
    }
    return new_i, opcode, rm_decode, immediate_decode
}

extract_mod_rm :: proc(instr_byte: u8) -> (mod: u8, reg_or_opcode: u8, rm: u8) {
    mod = instr_byte & 0b1100_0000 >> 6
    reg_or_opcode = instr_byte & 0b11_1000 >> 3
    rm = instr_byte & 0b111
    return mod, reg_or_opcode, rm
}

disassemble_rm :: proc(rm: u8, mod: u8, word: u8, i: int, p_bytes: ^[]u8) -> (rm_decode: string, new_i: int) {
    bytes := p_bytes^
    new_i = i
    switch mod {
        case 0b11: // Register mode
            rm_decode = reg_tables[word][rm]
        case 0b10: // Memory mode, 16 bit displacement
            displacement := i16(bytes[i+1]) | (i16(bytes[i+2]) << 8)
            if displacement < 0 {
                rm_decode = fmt.tprintf("[%v%v]", rm_table[rm], displacement)
            } else {
                rm_decode = fmt.tprintf("[%v+%v]", rm_table[rm], displacement)
            }
            new_i += 2
        case 0b01: // Memory mode, 8 bit displacement
            displacement := i8(bytes[i+1])
            if displacement < 0 {
                rm_decode = fmt.tprintf("[%v%v]", rm_table[rm], displacement)
            } else {
                rm_decode = fmt.tprintf("[%v+%v]", rm_table[rm], displacement)
            }
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
    if segment_override != -1 {
        segment_register := seg_reg_table[segment_override]
        rm_decode = fmt.tprintf("%v:%v", segment_register, rm_decode)
        segment_override = -1 // clear the segment prefix
    }
    return rm_decode, new_i
}