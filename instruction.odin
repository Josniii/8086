package sim8086

/*
 * This file contains struct definitions for the internal representation of instructions,
 * as well as helper procedures to make them.
 */

register_access :: proc(index: RegisterIndex, offset: u32, count: u32) -> (result: RegisterAccess) {
    result.index = index
    result.offset = offset
    result.count = count
    return result
}

intersegment_address_operand :: proc(segment: u32, displacement: i32) -> (result: Operand) {
    result.type = .Memory
    result.value = EffectiveAddressExpression({
        explicit_segment = segment,
        displacement = displacement,
    })
    return result
}

effective_address_operand :: proc(reg_0: RegisterAccess, reg_1: RegisterAccess, displacement: i32) -> (result: Operand) {
    result.type = .Memory
    result.value = EffectiveAddressExpression({
        terms = {EffectiveAddressTerm({reg_0}), EffectiveAddressTerm({reg_1})},
        displacement = displacement,
    })
    return result
}

register_operand :: proc(index: RegisterIndex, count: u32) -> (result: Operand) {
    result.type = .Register
    result.value = RegisterAccess({
        index = index,
        count = count,
    })
    return result
}

immediate_operand :: proc(value: i32, relative: bool = false) -> (result: Operand) {
    result.type = .Immediate
    result.value = Immediate({
        value = value,
        relative = relative,
    })
    return result
}

Instruction :: struct {
    address: u32,
    size: u16,
    op: OperationType,
    flags: InstructionFlagSet,
    operands: [2]Operand,
    segment_override: RegisterIndex,
}

// Encodes an operand for an instruction (an address, a register, or an immediate value)
Operand :: struct {
    type: OperandType,
    value: OperandValue,
}

OperandValue :: union {
    EffectiveAddressExpression,
    RegisterAccess,
    Immediate,
}

EffectiveAddressTerm :: struct {
    register: RegisterAccess,
}

// Encodes an address calculation
EffectiveAddressExpression :: struct {
    explicit_segment: u32,
    terms: [2]EffectiveAddressTerm,
    displacement: i32,
}

// Encodes an access to a register.
RegisterAccess :: struct {
    index: RegisterIndex, // Which register to access
    offset: u32, // Whether to look at low/high byte of register (high is 1, low/whole is 0)
    count: u32, // Number of bytes to read (1 or 2, byte or word)
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
    Far,
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

OperandType :: enum {
    None,
    Register,
    Memory,
    Immediate,
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
    Stos,
    Call,
    Jmp,
    Ret,
    Retf,
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
