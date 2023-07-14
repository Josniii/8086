package sim8086

import "core:fmt"

is_printable :: proc(instruction: Instruction) -> bool {
    return instruction.op != .Lock &&
        instruction.op != .Rep &&
        instruction.op != .Segment
}

print_instruction :: proc(instruction: ^Instruction) {
    print_effective_address_expression :: proc(address: EffectiveAddressExpression) {
        separator := ""
        for term in address.terms {
            register := term.register
            if register.index != .None {
                fmt.printf("%s", separator)
                fmt.printf("%s", get_register_name(register))
                separator = "+"
            }
        }
        if address.displacement != 0 {
            fmt.printf("%+d", address.displacement)
        }
    }
    suffix := ""
    if .Lock in instruction.flags {
        fmt.printf("lock ")
        if instruction.op == .Xchg {
            // NASM has some weirdness where xchg instructions 
            // have to have be in a certain order, even though it shouldn't matter.
            tmp := instruction.operands[0]
            instruction.operands[0] = instruction.operands[1]
            instruction.operands[1] = tmp
        }
    }
    if .Rep in instruction.flags {
        fmt.printf("rep ")
        suffix = .Wide in instruction.flags ? "w" : "b"
    }
    fmt.printf("%s%s ", mnemonic_string_table[int(instruction.op)], suffix)

    seperator := ""
    for operand in instruction.operands {
        if operand.type != .None {
            fmt.printf("%s", seperator)
            seperator = ", "
            switch operand.type {
                case .None:
                case .Memory:
                    address := operand.value.(EffectiveAddressExpression)

                    if .Far in instruction.flags {
                        fmt.printf("far ")
                    }

                    if address.explicit_segment != 0 {
                        fmt.printf("%d:%d", address.explicit_segment, address.displacement)
                    } else {
                        if instruction.operands[0].type != .Register {
                            fmt.printf("%s", .Wide in instruction.flags ? "word " : "byte ")
                        }

                        if .Segment in instruction.flags {
                            fmt.printf("%s:", get_register_name({instruction.segment_override, 0, 2}))
                        }

                        fmt.printf("[")
                        print_effective_address_expression(address)
                        fmt.printf("]")
                    }
                case .Register:
                    access := operand.value.(RegisterAccess)
                    fmt.printf("%s", register_string_table[access.index][access.count == 2 ? 2 : (access.offset & 1)])
                    //fmt.println(";", access.index, access.count, access.offset)
                case .Immediate:
                    immediate := operand.value.(Immediate)
                    if immediate.relative {
                        fmt.printf("$%+d", immediate.value + i32(instruction.size))
                    } else {
                        fmt.printf("%d", immediate.value)
                    }
            }
        }
    }
    fmt.println();
}

// Maps OperationType values to strings
mnemonic_string_table : []string = {
    "", // .None
    "mov",
    "push",
    "pop",
    "xchg",
    "in",
    "out",
    "xlat",
    "lea",
    "lds",
    "les",
    "lahf",
    "sahf",
    "pushf",
    "popf",
    "add",
    "adc",
    "inc",
    "aaa",
    "daa",
    "sub",
    "sbb",
    "dec",
    "neg",
    "cmp",
    "aas",
    "das",
    "mul",
    "imul",
    "aam",
    "div",
    "idiv",
    "aad",
    "cbw",
    "cwd",
    "not",
    "shl",
    "shr",
    "sar",
    "rol",
    "ror",
    "rcl",
    "rcr",
    "and",
    "test",
    "or",
    "xor",
    "rep",
    "movs",
    "cmps",
    "scas",
    "lods",
    "stos",
    "call",
    "jmp",
    "ret",
    "retf",
    "je",
    "jl",
    "jle",
    "jb",
    "jbe",
    "jp",
    "jo",
    "js",
    "jne",
    "jnl",
    "jnle",
    "jnb",
    "jnbe",
    "jnp",
    "jno",
    "jns",
    "loop",
    "loopz",
    "loopnz",
    "jcxz",
    "int",
    "int3",
    "into",
    "iret",
    "clc",
    "cmc",
    "stc",
    "cld",
    "std",
    "cli",
    "sti",
    "hlt",
    "wait",
    "esc",
    "lock",
    "segment",
}

get_register_name :: proc(register: RegisterAccess) -> string {
    return register_string_table[register.index][register.count == 2 ? 2 : (register.offset & 1)]
}
// Maps RegisterIndex values to strings
register_string_table : [][3]string = {
    {"",   "",   ""},
    {"al", "ah", "ax"},
    {"bl", "bh", "bx"},
    {"cl", "ch", "cx"},
    {"dl", "dh", "dx"},
    {"sp", "sp", "sp"},
    {"bp", "bp", "bp"},
    {"si", "si", "si"},
    {"di", "di", "di"},
    {"es", "es", "es"},
    {"cs", "cs", "cs"},
    {"ss", "ss", "ss"},
    {"ds", "ds", "ds"},
    {"ip", "ip", "ip"},
    {"flags", "flags", "flags"},
}

effective_address_table : []string = {
    "", // .Direct
    "bx+si",
    "bx+di",
    "bp+si",
    "bp+di",
    "si",
    "di",
    "bp",
    "bx",
}
