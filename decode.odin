package sim8086

import "core:fmt"

DisassemblyContext :: struct {
    default_segment: RegisterIndex,
    flags: InstructionFlagSet,
}

accept_instruction :: proc(disassembly_context: ^DisassemblyContext, instruction: Instruction) {
    #partial switch instruction.op {
        case .Lock:
            disassembly_context.flags |= {.Lock}
        case .Rep:
            disassembly_context.flags |= {.Rep}
        case .Segment:
            disassembly_context.flags |= {.Segment}
            disassembly_context.default_segment = instruction.operands[1].value.(RegisterAccess).index
        case:
            // "Consume" flags
            disassembly_context.flags = {}
    }
}

decode_instruction :: proc(disassembly_context: ^DisassemblyContext, memory: ^Memory, at_seg: ^SegmentAccess) -> (instruction: Instruction) {
    for instruction_format in instruction_formats {
        instruction = attempt_instruction_decode(disassembly_context, instruction_format, memory, at_seg^)
        if instruction.op != .None {
            at_seg.offset += instruction.size
            break
        }
    }
    return instruction
}

attempt_instruction_decode :: proc(disassembly_context: ^DisassemblyContext, instruction_format: InstructionFormat, memory: ^Memory, at_seg: SegmentAccess) -> (instruction: Instruction) {
    at_seg := at_seg
    parts: [len(InstructionFormatPartUsage)]int
    parts_set : bit_set[InstructionFormatPartUsage]

    // loop maintenance data
    valid_instruction := true
    starting_address := get_real_address(at_seg)
    bits_to_read: u8 = 0
    bits_read: u8 = 0
    for part in instruction_format.parts {
        value := part.value
        if part.bit_count != 0 {
            // Check if we have to read a byte to parse or there's leftover from previous parsing
            if bits_to_read == 0 {
                bits_to_read = 8
                bits_read = read_memory(memory, get_real_address(at_seg))
                at_seg.offset += 1
            }

            assert(part.bit_count <= bits_to_read) // No instruction should have require going across bytes for a part of them.

            bits_to_read -= part.bit_count
            value = bits_read
            value >>= bits_to_read
            value &= ~(0xff << part.bit_count)
        }

        if part.usage == .Literal {
            // Check literal bits against the ones provided in the table.
            valid_instruction &= (value == part.value)
            if !valid_instruction {
                break
            }
        } else {
            // Add the parsed part.
            parts[part.usage] |= (int(value) << part.shift)
            incl(&parts_set, part.usage) 
        }
    }
    if valid_instruction {
        fmt.printf("; %d\n", at_seg.offset - 1) // Fairly helpful for finding instruction locations
        // Parse remaining parts that can be derived from above (displacement and data)
        parse_immediate :: proc(memory: ^Memory, at_seg: ^SegmentAccess, wide, sign_extend: bool) -> (immediate: int) {
            if wide {
                byte0 := read_memory(memory, get_real_address(at_seg^))
                byte1 := read_memory(memory, get_real_address(at_seg^, 1))
                immediate = int(byte1) << 8 | int(byte0)
                at_seg.offset += 2
            } else {
                immediate = int(read_memory(memory, get_real_address(at_seg^)))
                if sign_extend {
                    immediate = int(i8(immediate))
                }
                at_seg.offset += 1
            }
            return
        }
        load_reg_operand :: proc(reg_index: int, wide: bool) -> (result: Operand) {
            // Table 4-9 - REG (Register) Field Encoding
            register_table: [][2]RegisterAccess = {
                //  W = 0       W = 1
                {{.A, 0, 1}, {.A,  0, 2}},
                {{.C, 0, 1}, {.C,  0, 2}},
                {{.D, 0, 1}, {.D,  0, 2}},
                {{.B, 0, 1}, {.B,  0, 2}},
                {{.A, 1, 1}, {.SP, 0, 2}},
                {{.C, 1, 1}, {.BP, 0, 2}},
                {{.D, 1, 1}, {.SI, 0, 2}},
                {{.B, 1, 1}, {.DI, 0, 2}},
            }
            result.type = .Register
            result.value = register_table[reg_index & 0b111][int(wide)]
            return
        }
        // Grab all the parts we parsed above
        mod, reg, rm := 
            parts[InstructionFormatPartUsage.MOD], 
            parts[InstructionFormatPartUsage.REG], 
            parts[InstructionFormatPartUsage.RM]
        w, s, d := 
            parts[InstructionFormatPartUsage.W] != 0, 
            parts[InstructionFormatPartUsage.S] != 0, 
            parts[InstructionFormatPartUsage.D] != 0

        has_direct_addr := mod == 0b00 && rm == 0b110
        
        //displacement
        has_disp := .Disp in parts_set || mod == 0b10 || mod == 0b01 || has_direct_addr
        disp_is_w := parts[InstructionFormatPartUsage.DispAlwaysW] != 0 || mod == 0b10 || has_direct_addr
        if has_disp {
            parts[InstructionFormatPartUsage.Disp] |= parse_immediate(memory, &at_seg, disp_is_w, !disp_is_w)
        }
        displacement := i32(parts[InstructionFormatPartUsage.Disp])

        has_data := .Data in parts_set
        data_is_w := parts[InstructionFormatPartUsage.WMakesDataW] != 0 && w && !s
        if has_data {
            parts[InstructionFormatPartUsage.Data] |= parse_immediate(memory, &at_seg, data_is_w, s)
        }
        data := parts[InstructionFormatPartUsage.Data]

        // Construct the fixed parts of the instruction
        {
            instruction.address = starting_address
            instruction.size = u16(get_real_address(at_seg) - starting_address)
            instruction.op = instruction_format.op
            instruction.flags = disassembly_context.flags
            if w {
                instruction.flags |= {.Wide}
            }
            if .Far in parts_set {
                instruction.flags |= {.Far}
            }
            instruction.segment_override = disassembly_context.default_segment
        }

        // Construct REG operand for instruction (if there is one)
        {    
            // Figure out which operand is the reg operand based on the 'd' bit.
            reg_operand := &instruction.operands[d ? 0 : 1]
            // Segment Register
            if .SR in parts_set {
                reg_operand.type = .Register
                reg_operand.value = RegisterAccess({
                    // ES is just the first of the segment registers.
                    index = RegisterIndex(int(RegisterIndex.ES) + parts[InstructionFormatPartUsage.SR] & 0b11),
                    count = 2, //Always wide.
                })
            }

            // Handle REG part
            if .REG in parts_set {
                assert(reg_operand.type == .None) // Ensure we're not overriding the operand.
                reg_operand^ = load_reg_operand(reg, w)
            }
        }

        // Construct mod operand for instruction (if there is one)
        // See Table 4-8 - MOD (Mode) Field Encoding
        if .MOD in parts_set {
            // Same idea as with reg_operand above.
            mod_operand := &instruction.operands[d ? 1 : 0]
            if mod == 0b11 {
                mod_operand^ = load_reg_operand(rm, w || (parts[InstructionFormatPartUsage.RMREGAlwaysW] != 0))
            } else {
                // See Table 4-10 - R/M (Register/Memory) Field Encoding
                e_addr_term_0 : [8]RegisterIndex = {.B, .B, .BP, .BP, .SI, .DI, .BP, .B}
                e_addr_term_1 : [8]RegisterIndex = {.SI, .DI, .SI, .DI, .None, .None, .None, .None}
                reg_0 := e_addr_term_0[rm & 0b111]
                reg_1 := e_addr_term_1[rm & 0b111]
                if mod == 0b00 && rm == 0b110 {
                    // direct
                    reg_0, reg_1 = .None, .None
                }
                mod_operand^ = effective_address_operand(
                    register_access(reg_0, 0, 2), 
                    register_access(reg_1, 0, 2), 
                    displacement
                )
            }
        }

        if .Data in parts_set && .Disp in parts_set && .MOD not_in parts_set {
            instruction.operands[0] = intersegment_address_operand(u32(data), displacement)
        } else {
            // Construct any other types of operands (if there is one)
            // Primarily immediates - but there are other strange types of values as well.
            other_operand : ^Operand = &instruction.operands[0]
            if other_operand.type != .None {
                other_operand = &instruction.operands[1]
            }

            if .RelativeJMPDisplacement in parts_set {
                assert(other_operand.type == .None)
                other_operand^ = immediate_operand(displacement, true)
            }

            if .Data in parts_set {
                assert(other_operand.type == .None)
                other_operand^ = immediate_operand(i32(data))
            }

            if .V in parts_set {
                assert(other_operand.type == .None)
                v := parts[InstructionFormatPartUsage.V] != 0
                if v {
                    other_operand^ = register_operand(.C, 1)
                } else {
                    other_operand^ = immediate_operand(1)
                }
            }
        }
    }
    return instruction
}
