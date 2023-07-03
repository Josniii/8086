package sim8086

Instruction :: struct {
    address: u32,
    size: u16,
    op: OperationType,
    flags: InstructionFlagSet,
    operands: [2]Operand,
}

// Encodes an operand for an instruction (an address, a register, or an immediate value)
Operand :: struct {
    type: OperandType,
    value: union {
        EffectiveAddressExpression,
        RegisterAccess,
        u16,
        i16,
    },
}

// Encodes an address calculation
EffectiveAddressExpression :: struct {
    segment: RegisterIndex,
    base: EffectiveAddressBase,
    displacement: i16,
}

// Encodes an access to a register.
RegisterAccess :: struct {
    index: RegisterIndex, // Which register to access
    offset: u8, // Whether to look at low/high byte of register (high is 1, low/whole is 0)
    count: u8, // Number of bytes to read (1 or 2, byte or word)
}

Immediate :: struct {
    value: i32,
    relative: bool,
}

// Types of special flags an instruction can have
InstructionFlag :: enum {
    Lock,
    Rep,
    Segment,
    Wide,
}
InstructionFlagSet :: bit_set[InstructionFlag]

// The 8086 registers.
RegisterIndex :: enum {
    None,
    A,  // ax/al/ah
    B,  // bx/bl/bh
    C,  // cx/cl/ch
    D,  // dx/dl/dh
    SP,
    BP,
    SI,
    DI,
    ES,
    CS,
    SS,
    DS,
    IP,
    Flags,
}

// See Table 4-10 - R/M (Register/Memory) Field Encoding
EffectiveAddressBase :: enum {
    Direct, // NOTE: This being at 0 offsets the table by one, so add 1 to RM when using table.
    BxSi,
    BxDi,
    BpSi,
    BpDi,
    Si,
    Di,
    Bp,
    Bx,
}

OperandType :: enum {
    None,
    Register,
    Memory,
    Immediate,
    RelativeImmediate,
}

OperationType :: enum {
    None,
    Mov,
    Push,
    Pop,
    Xchg,
    In,
    Out,
    Xlat,
    Lea,
    Lds,
    Les,
    Lahf,
    Sahf,
    Pushf,
    Popf,
    Add,
    Adc,
    Inc,
    Aaa,
    Daa,
    Sub,
    Sbb,
    Dec,
    Neg,
    Cmp,
    Aas,
    Das,
    Mul,
    Imul,
    Aam,
    Div,
    Idiv,
    Aad,
    Cbw,
    Cwd,
    Not,
    Shl,
    Shr,
    Sar,
    Rol,
    Ror,
    Rcl,
    Rcr,
    And,
    Test,
    Or,
    Xor,
    Rep,
    Movs,
    Cmps,
    Scas,
    Lods,
    Stds,
    Call,
    Jmp,
    Ret,
    Je,
    Jl,
    Jle,
    Jb,
    Jbe,
    Jp,
    Jo,
    Js,
    Jne,
    Jnl,
    Jnle,
    Jnb,
    Jnbe,
    Jnp,
    Jno,
    Jns,
    Loop,
    Loopz,
    Loopnz,
    Jcxz,
    Int,
    Int3,
    Into,
    Iret,
    Clc,
    Cmc,
    Stc,
    Cld,
    Std,
    Cli,
    Sti,
    Hlt,
    Wait,
    Esc,
    Lock,
    Segment,
}
