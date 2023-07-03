package sim8086



Opcode8086 :: enum u8 {
    // Data transfer
    MovRmToOrFromReg = 0b1000_1000,
    MovImmediateToRm = 0b1100_0110,
    MovImmediateToReg = 0b1011_0000,
    MovRmToOrFromSegReg = 0b1000_1100,
    
    MovMemToAcc = 0b1010_0000,
    MovAccToMem = 0b1010_0010,
    PushOrPopReg = 0b0101_0000,
    PushOrPopSegmentReg = 0b0000_0110,
    PopRegOrMem = 0b1000_1111,
    XchgRegOrMemWithReg = 0b1000_0110,
    XchgRegWithAcc = 0b1001_0000,
    InOut = 0b1110_0100,
    Xlat = 0b1101_0111,
    LoadEffectiveAddress = 0b1000_1101,
    LoadPointerToDs = 0b1100_0101,
    LoadPointerToEs = 0b1100_0100,
    LoadAHWithFlags = 0b1001_1111,
    StoreAHIntoFlags = 0b1001_1110,
    PushFlags = 0b1001_1100,
    PopFlags = 0b1001_1101,

    // Arithmetic (ADD/SUB/CMP)
    ArithRegOrMemWithRegToEither = 0b0000_0000,
    ArithImmediateToRegOrMem = 0b1000_0000,
    ArithImmediateToAcc = 0b0000_0100,
    IncOrDecRegister = 0b0100_0000,
    AsciiAdjustForAdd = 0b0011_0111,
    AsciiAdjustForSubtract = 0b0011_1111,
    AsciiAdjustForMultiply = 0b1101_0100,
    AsciiAdjustForDivide = 0b1101_0101,
    DecimalAdjustForAdd = 0b0010_0111,
    DecimalAdjustForSubtract = 0b0010_1111,
    ConvertByteToWord = 0b1001_1000,
    ConvertWordToDoubleWord = 0b1001_1001,
    ShiftOrRotate = 0b1101_0000,
    TestRmAndReg = 0b1000_0100,
    TestImmediateAndAcc = 0b1010_1000,

    // String manipulation
    RepeatStr = 0b1111_0010,
    MoveByteOrWord = 0b1010_0100,
    CompareByteOrWord = 0b1010_0110,
    ScanByteOrWord = 0b1010_1110,
    LoadByteOrWordToAcc = 0b1010_1100,
    StoreByteOrWordToAcc = 0b1010_1010,

    // Instructions with grouped opcodes -  see page 178
    Group1RegOrRem = 0b1111_0110,
    Group2RegOrRem = 0b1111_1110,

    //Control flow
    CallDirectInSeg = 0b1110_1000,
    CallDirectInterSeg = 0b1001_1010,
    CallOrJumpIndirect = 0b1111_1111,
    JmpDirectInSeg = 0b1110_1001,
    JmpDirectInSegShort = 0b1110_1011,
    JmpDirectInterSeg = 0b1110_1010,
    ReturnInSeg = 0b1100_0011,
    ReturnInSegAddImmediate = 0b1100_0010,
    ReturnInterSeg = 0b1100_1011,
    ReturnInterSegAddImmediate = 0b1100_1010,

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

    //Interrupts
    InterruptTypeSpecified = 0b1100_1101,
    InterruptType3 = 0b1100_1100,
    InterruptOnOverflow = 0b1100_1110,
    InterruptReturn = 0b1100_1111,

    //Processor Control
    ClearCarry = 0b1111_1000,
    ComplementCarry = 0b1111_0101,
    SetCarry = 0b1111_1001,
    ClearDirection = 0b1111_1100,
    SetDirection = 0b1111_1101,
    ClearInterrupt = 0b1111_1010,
    SetInterrupt = 0b1111_1011,
    Halt = 0b1111_0100,
    Wait = 0b1001_1011,
    EscapeToExternalDevice = 0b1101_1000,
    BusLockPrefix = 0b1111_0000,
    SegmentOverridePrefix = 0b0010_0110,
}

LoadInstruction :: enum {
    LEA,
    LDS,
    LES,
}

Registers :: enum {
    ax,
    cx,
    dx,
    bx,
    sp,
    bp,
    si,
    di,
}
SegmentRegisters :: enum {
    es,
    cs,
    ss,
    ds,
}

LookupTable :: [8]string

reg_tables: [2]LookupTable = {
    {
        "al",
        "cl",
        "dl",
        "bl",
        "ah",
        "ch",
        "dh",
        "bh",
    },
    {
        "ax",
        "cx",
        "dx",
        "bx",
        "sp",
        "bp",
        "si",
        "di",
    },
}
rm_table: LookupTable = {
    "bx + si",
    "bx + di",
    "bp + si",
    "bp + di",
    "si",
    "di",
    "bp",
    "bx",
}
seg_reg_table: [4]string = {
    "es",
    "cs",
    "ss",
    "ds",
}
arith_op_table: LookupTable = {
    "add",
    "or",
    "adc",
    "sbb",
    "and",
    "sub",
    "xor",
    "cmp",
}
shift_op_table: LookupTable = {
    "rol",
    "ror",
    "rcl",
    "rcr",
    "shl",
    "shr",
    "-st", // does not exist - see manual.
    "sar",
}
group_tables: [2]LookupTable = {
    {
        "test",
        "-g1", // does not exist - see manual.
        "not",
        "neg",
        "mul",
        "imul",
        "div",
        "idiv",
    },
    {
        "inc",
        "dec",
        "call",
        "call far",
        "jmp",
        "jmp far",
        "push",
        "-g2", // does not exist - see manual.
    },
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