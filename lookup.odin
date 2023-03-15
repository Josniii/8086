package sim8086

Opcode8086 :: enum u8 {
    // Data transfer
    MovRegOrMemToOrFromReg = 0b1000_1000,
    MovImmediateToRegOrMem = 0b1100_0110,
    MovImmediateToReg = 0b1011_0000,
    MovMemToAcc = 0b1010_0000,
    MovAccToMem = 0b1010_0010,

    // Arithmetic (ADD/SUB/CMP)
    ArithRegOrMemWithRegToEither = 0b0000_0000,
    ArithImmediateToRegOrMem = 0b1000_0000,
    ArithImmediateToAcc = 0b00000100,

    // Conditional jumps
    JumpOnEqual = 0b0111_0100,
    JumpOnLess = 0b0111_1100,
    JumpOnLessOrEqual = 0b0111_1110,
    JumpOnBelow = 0b0111_0010,
    JumpOnBelowOrEqual = 0b0111_0110,
    JumpOnParity = 0b0111_1010,
    JumpOnOverflow = 0b0111_0000,
    JumpOnSign = 0b0111_1000,
    JumpOnNotEqual = 0b0111_0101,
    JumpOnGreaterOrEqual = 0b0111_1101,
    JumpOnGreater = 0b0111_1111,
    JumpOnAboveOrEqual = 0b0111_0011,
    JumpOnAbove = 0b0111_0111,
    JumpOnNotPar = 0b0111_1011,
    JumpOnNotOverflow = 0b0111_0001,
    JumpOnNotSign = 0b0111_1001,
    Loop = 0b1110_0010,
    LoopWhileZero = 0b1110_0001,
    LoopWhileNotZero = 0b1110_0000,
    JumpOnCXZero = 0b1110_0011,
}

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
arith_op_table: [8]string = {
    "add",
    "or",
    "adc",
    "sbb",
    "and",
    "sub",
    "xor",
    "cmp",
}

lookup_jmp_mnemonic :: proc(instr: Opcode8086) -> string {
    #partial switch instr {
        case .JumpOnEqual:
            return "je"
        case .JumpOnLess:
            return "jl"
        case .JumpOnLessOrEqual:
            return "jle"
        case .JumpOnBelow:
            return "jb"
        case .JumpOnBelowOrEqual:
            return "jbe"
        case .JumpOnParity:
            return "jp"
        case .JumpOnOverflow:
            return "jo"
        case .JumpOnSign:
            return "js"
        case .JumpOnNotEqual:
            return "jnz"
        case .JumpOnGreaterOrEqual:
            return "jge"
        case .JumpOnGreater:
            return "jg"
        case .JumpOnAboveOrEqual:
            return "jae"
        case .JumpOnAbove:
            return "ja"
        case .JumpOnNotPar:
            return "jnp"
        case .JumpOnNotOverflow:
            return "jno"
        case .JumpOnNotSign:
            return "jns"
        case .Loop:
            return "loop"
        case .LoopWhileZero:
            return "loopz"
        case .LoopWhileNotZero:
            return "loopnz"
        case .JumpOnCXZero:
            return "jcxz"
        case:
            return "???"
    }
}