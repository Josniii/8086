package sim8086

//The instruction table format.

InstructionFormat :: struct {
    op: OperationType,
    parts: []InstructionFormatPart, // TODO: Fix this?
}

InstructionFormatPart :: struct {
    usage: InstructionFormatPartUsage,
    bit_count: u8, // Number of bits to read
    shift: u8, 
    value: u8,
}

InstructionFormatPartUsage :: enum {
    Literal,
    MOD,
    REG,
    RM,
    SR,
    Disp,
    Data,
    DispAlwaysW,
    WMakesDataW,
    RMREGAlwaysW,
    RelativeJMPDisplacement,
    Far,
    D,
    S,
    W,
    V,
    Z,
}

// ==================================================================================================================
// Constants representing a part of an instruction which can be used in the table.
// ==================================================================================================================

@(private) D : InstructionFormatPart : {.D, 1, 0, 0}
@(private) S : InstructionFormatPart : {.S, 1, 0, 0}
@(private) W : InstructionFormatPart : {.W, 1, 0, 0}
@(private) V : InstructionFormatPart : {.V, 1, 0, 0}
@(private) Z : InstructionFormatPart : {.Z, 1, 0, 0}

@(private) XXX : InstructionFormatPart : {.Data, 3, 0, 0}
@(private) YYY : InstructionFormatPart : {.Data, 3, 3, 0}
@(private) RM : InstructionFormatPart : {.RM, 3, 0, 0}
@(private) MOD : InstructionFormatPart : {.MOD, 2, 0, 0}
@(private) REG : InstructionFormatPart : {.REG, 3, 0, 0}
@(private) SR : InstructionFormatPart : {.SR, 2, 0, 0}

@(private) DISP : InstructionFormatPart : {.Disp, 0, 0, 0}
@(private) ADDRLO : InstructionFormatPart : {.Disp, 0, 0, 0}
@(private) ADDRHI : InstructionFormatPart : {.DispAlwaysW, 0, 0, 1}
@(private) DATA : InstructionFormatPart : {.Data, 0, 0, 0}
@(private) DATAIFW : InstructionFormatPart : {.WMakesDataW, 0, 0, 1}

// These represent implicitly understood information about instruction, to explicitly encode into the table.
@(private) ImpD1 : InstructionFormatPart : {.D, 0, 0, 1}               // D = 1
@(private) ImpD0 : InstructionFormatPart : {.D, 0, 0, 0}               // D = 0
@(private) ImpS1 : InstructionFormatPart : {.S, 0, 0, 1}               // S = 1
@(private) ImpS0 : InstructionFormatPart : {.S, 0, 0, 0}               // S = 0
@(private) ImpW1 : InstructionFormatPart : {.W, 0, 0, 1}               // W = 1
@(private) ImpRM0 : InstructionFormatPart : {.RM, 0, 0, 0b0}           // RM = 000
@(private) ImpRM010 : InstructionFormatPart : {.RM, 0, 0, 0b010}       // RM = 010
@(private) ImpRM110 : InstructionFormatPart : {.RM, 0, 0, 0b110}       // RM = 110
@(private) ImpMOD0 : InstructionFormatPart : {.MOD, 0, 0, 0}           // MOD = 00
@(private) ImpMOD11 : InstructionFormatPart : {.MOD, 0, 0, 0b11}       // MOD = 11
@(private) ImpREG0 : InstructionFormatPart : {.REG, 0, 0, 0}           // REG = 000
// Flags
@(private) RMREGAlwaysW : InstructionFormatPart : {.RMREGAlwaysW, 0, 0, 1}
@(private) RelativeJMPDisplacement : InstructionFormatPart : {.RelativeJMPDisplacement, 0, 0, 1}
@(private) Far : InstructionFormatPart : {.Far, 0, 0, 1}

// ==================================================================================================================/
// The 8086 assembly instruction table.
// Every line represents one instruction in the Intel 8086 manual, from top to bottom, unless otherwise specified.
// ==================================================================================================================/
instruction_formats: []InstructionFormat : {
    // DATA TRANSFER
    // MOV = Move:
    {.Mov, {{.Literal, 6, 0, 0b1000_10}, D, W, MOD, REG, RM}},
    {.Mov, {{.Literal, 7, 0, 0b1100_011}, W, MOD, {.Literal, 3, 0, 0b000}, RM, DATA, DATAIFW, ImpD0}},
    {.Mov, {{.Literal, 4, 0, 0b1011}, W, REG, DATA, DATAIFW, ImpD1}},
    {.Mov, {{.Literal, 7, 0, 0b1010_000}, W, ADDRLO, ADDRHI, ImpREG0, ImpMOD0, ImpRM110, ImpD1}},
    {.Mov, {{.Literal, 7, 0, 0b1010_001}, W, ADDRLO, ADDRHI, ImpREG0, ImpMOD0, ImpRM110, ImpD0}},
    {.Mov, {{.Literal, 6, 0, 0b1000_11}, D, {.Literal, 1, 0, 0b0}, MOD, {.Literal, 1, 0, 0b0}, SR, RM, ImpW1}}, // This definition handles both RM to SR and SR to RM by having a D bit.
    // PUSH = Push:
    {.Push, {{.Literal, 8, 0, 0b1111_1111}, MOD, {.Literal, 3, 0, 0b110}, RM, ImpW1}},
    {.Push, {{.Literal, 5, 0, 0b0101_0}, REG, ImpW1}},
    {.Push, {{.Literal, 3, 0, 0b000}, SR, {.Literal, 3, 0, 0b110}, ImpW1}},
    // POP = Pop:
    {.Pop, {{.Literal, 8, 0, 0b1000_1111}, MOD, {.Literal, 3, 0, 0b000}, RM, ImpW1}},
    {.Pop, {{.Literal, 5, 0, 0b0101_1}, REG, ImpW1}},
    {.Pop, {{.Literal, 3, 0, 0b000}, SR, {.Literal, 3, 0, 0b111}, ImpW1}},
    // XCHG = Exchange:
    {.Xchg, {{.Literal, 7, 0, 0b1000_011}, W, MOD, REG, RM, ImpD1}},
    {.Xchg, {{.Literal, 5, 0, 0b1001_0}, REG, ImpMOD11, ImpW1, ImpRM0}},
    // IN = Input from:
    {.In, {{.Literal, 7, 0, 0b1110_010}, W, DATA, ImpREG0, ImpD1}},
    {.In, {{.Literal, 7, 0, 0b1110_110}, W, ImpREG0, ImpD1, ImpMOD11, ImpRM010, RMREGAlwaysW}},
    // OUT = Output to:
    {.Out, {{.Literal, 7, 0, 0b1110_011}, W, DATA, ImpREG0, ImpD0}},
    {.Out, {{.Literal, 7, 0, 0b1110_111}, W, ImpREG0, ImpD0, ImpMOD11, ImpRM010, RMREGAlwaysW}},
    {.Xlat, {{.Literal, 8, 0, 0b1101_0111}}},
    {.Lea, {{.Literal, 8, 0, 0b1000_1101}, MOD, REG, RM, ImpD1, ImpW1}},
    {.Lds, {{.Literal, 8, 0, 0b1100_0101}, MOD, REG, RM, ImpD1, ImpW1}},
    {.Les, {{.Literal, 8, 0, 0b1100_0100}, MOD, REG, RM, ImpD1, ImpW1}},
    {.Lahf, {{.Literal, 8, 0, 0b1001_1111}}},
    {.Sahf, {{.Literal, 8, 0, 0b1001_1110}}},
    {.Pushf, {{.Literal, 8, 0, 0b1001_1100}}},
    {.Popf, {{.Literal, 8, 0, 0b1001_1101}}},
    // ARITHMETIC
    // ADD = Add:
    {.Add, {{.Literal, 6, 0, 0b0000_00}, D, W, MOD, REG, RM}},
    {.Add, {{.Literal, 6, 0, 0b1000_00}, S, W, MOD, {.Literal, 3, 0, 0b000}, RM, DATA, DATAIFW}},
    {.Add, {{.Literal, 7, 0, 0b0000_010}, W, DATA, DATAIFW, ImpREG0, ImpD1}},
    // ADC = Add with carry:
    {.Adc, {{.Literal, 6, 0, 0b0001_00}, D, W, MOD, REG, RM}},
    {.Adc, {{.Literal, 6, 0, 0b1000_00}, S, W, MOD, {.Literal, 3, 0, 0b010}, RM, DATA, DATAIFW}},
    {.Adc, {{.Literal, 7, 0, 0b0001_010}, W, DATA, DATAIFW, ImpREG0, ImpD1}},
    // INC = Increment:
    {.Inc, {{.Literal, 7, 0, 0b1111_111}, W, MOD, {.Literal, 3, 0, 0b000}, RM}},
    {.Inc, {{.Literal, 5, 0, 0b0100_0}, REG, ImpW1}},
    {.Aaa, {{.Literal, 8, 0, 0b0011_0111}}},
    {.Daa, {{.Literal, 8, 0, 0b0010_0111}}},
    // SUB = Subtract:
    {.Sub, {{.Literal, 6, 0, 0b0010_10}, D, W, MOD, REG, RM}},
    {.Sub, {{.Literal, 6, 0, 0b1000_00}, S, W, MOD, {.Literal, 3, 0, 0b101}, RM, DATA, DATAIFW}},
    {.Sub, {{.Literal, 7, 0, 0b0010_110}, W, DATA, DATAIFW, ImpREG0, ImpD1}},
    // SBB = Subtract with borrow:
    {.Sbb, {{.Literal, 6, 0, 0b0001_10}, D, W, MOD, REG, RM}},
    {.Sbb, {{.Literal, 6, 0, 0b1000_00}, S, W, MOD, {.Literal, 3, 0, 0b011}, RM, DATA, DATAIFW}},
    {.Sbb, {{.Literal, 7, 0, 0b0001_110}, W, DATA, DATAIFW, ImpREG0, ImpD1}},
    // DEC = Decrement:
    {.Dec, {{.Literal, 7, 0, 0b1111_111}, W, MOD, {.Literal, 3, 0, 0b001}, RM}},
    {.Dec, {{.Literal, 5, 0, 0b0100_1}, REG, ImpW1}},
    {.Neg, {{.Literal, 7, 0, 0b1111_011}, W, MOD, {.Literal, 3, 0, 0b011}, RM}},
    // CMP = Compare:
    {.Cmp, {{.Literal, 6, 0, 0b0011_10}, D, W, MOD, REG, RM}},
    {.Cmp, {{.Literal, 6, 0, 0b1000_00}, S, W, MOD, {.Literal, 3, 0, 0b111}, RM, DATA, DATAIFW}},
    {.Cmp, {{.Literal, 7, 0, 0b0011_110}, W, DATA, DATAIFW, ImpREG0, ImpD1}}, // Probably an error in the table here, since it should have a W bit but no wide data is mentioned.
    {.Aas, {{.Literal, 8, 0, 0b0011_1111}}},
    {.Das, {{.Literal, 8, 0, 0b0010_1111}}},
    {.Mul, {{.Literal, 7, 0, 0b1111_011}, W, MOD, {.Literal, 3, 0, 0b100}, RM, ImpS0}},
    {.Imul, {{.Literal, 7, 0, 0b1111_011}, W, MOD, {.Literal, 3, 0, 0b101}, RM, ImpS1}},
    {.Aam, {{.Literal, 8, 0, 0b1101_0100}, {.Literal, 8, 0, 0b0000_1010}}}, // Table says this has a displacement, but it doesn't.
    {.Div, {{.Literal, 7, 0, 0b1111_011}, W, MOD, {.Literal, 3, 0, 0b110}, RM, ImpS0}},
    {.Idiv, {{.Literal, 7, 0, 0b1111_011}, W, MOD, {.Literal, 3, 0, 0b111}, RM, ImpS1}},
    {.Aad, {{.Literal, 8, 0, 0b1101_0101}, {.Literal, 8, 0, 0b0000_1010}}}, // Table says this has a displacement, but it doesn't.
    {.Cbw, {{.Literal, 8, 0, 0b1001_1000}}},
    {.Cwd, {{.Literal, 8, 0, 0b1001_1001}}},
    // LOGIC
    {.Not, {{.Literal, 7, 0, 0b1111_011}, W, MOD, {.Literal, 3, 0, 0b010}, RM}},
    {.Shl, {{.Literal, 6, 0, 0b1101_00}, V, W, MOD, {.Literal, 3, 0, 0b100}, RM}},
    {.Shr, {{.Literal, 6, 0, 0b1101_00}, V, W, MOD, {.Literal, 3, 0, 0b101}, RM}},
    {.Sar, {{.Literal, 6, 0, 0b1101_00}, V, W, MOD, {.Literal, 3, 0, 0b111}, RM}},
    {.Rol, {{.Literal, 6, 0, 0b1101_00}, V, W, MOD, {.Literal, 3, 0, 0b000}, RM}},
    {.Ror, {{.Literal, 6, 0, 0b1101_00}, V, W, MOD, {.Literal, 3, 0, 0b001}, RM}},
    {.Rcl, {{.Literal, 6, 0, 0b1101_00}, V, W, MOD, {.Literal, 3, 0, 0b010}, RM}},
    {.Rcr, {{.Literal, 6, 0, 0b1101_00}, V, W, MOD, {.Literal, 3, 0, 0b011}, RM}},
    // AND = And:
    {.And, {{.Literal, 6, 0, 0b0010_00}, D, W, MOD, REG, RM}},
    {.And, {{.Literal, 7, 0, 0b1000_000}, W, MOD, {.Literal, 3, 0, 0b100}, RM, DATA, DATAIFW}},
    {.And, {{.Literal, 7, 0, 0b0010_010}, W, DATA, DATAIFW, ImpREG0, ImpD1}},
    // TEST = And function to flags no result:
    {.Test, {{.Literal, 7, 0, 0b1000_010}, W, MOD, REG, RM}}, // Table has an error here - there is no D flag, and the bits are wrong I believe.
    {.Test, {{.Literal, 7, 0, 0b1111_011}, W, MOD, {.Literal, 3, 0, 0b000}, RM, DATA, DATAIFW}},
    {.Test, {{.Literal, 7, 0, 0b1010_100}, W, DATA, DATAIFW, ImpREG0, ImpD1}}, // Table has an error here and is missing 16-bit data.
    // OR = Or:
    {.Or, {{.Literal, 6, 0, 0b0000_10}, D, W, MOD, REG, RM}},
    {.Or, {{.Literal, 7, 0, 0b1000_000}, W, MOD, {.Literal, 3, 0, 0b001}, RM, DATA, DATAIFW}},
    {.Or, {{.Literal, 7, 0, 0b0000_110}, W, DATA, DATAIFW, ImpREG0, ImpD1}},
    // XOR = Exclusive or:
    {.Xor, {{.Literal, 6, 0, 0b0011_00}, D, W, MOD, REG, RM}},
    {.Xor, {{.Literal, 7, 0, 0b1000_000}, W, MOD, {.Literal, 3, 0, 0b110}, RM, DATA, DATAIFW}}, // Table has an error here - the bit pattern is totally different!
    {.Xor, {{.Literal, 7, 0, 0b0011_010}, W, DATA, DATAIFW, ImpREG0, ImpD1}},
    // STRING MANIPULATION
    {.Rep, {{.Literal, 7, 0, 0b1111_001}, Z}},
    {.Movs, {{.Literal, 7, 0, 0b1010_010}, W}},
    {.Cmps, {{.Literal, 7, 0, 0b1010_011}, W}},
    {.Scas, {{.Literal, 7, 0, 0b1010_111}, W}},
    {.Lods, {{.Literal, 7, 0, 0b1010_110}, W}},
    {.Stos, {{.Literal, 7, 0, 0b1010_101}, W}}, //Table notes this as Stds, but that instruction does not exist.
    // CONTROL TRANSFER
    // CALL = Call:
    {.Call, {{.Literal, 8, 0, 0b1110_1000}, ADDRLO, ADDRHI, RelativeJMPDisplacement}},
    {.Call, {{.Literal, 8, 0, 0b1111_1111}, MOD, {.Literal, 3, 0, 0b010}, RM, ImpW1}},
    {.Call, {{.Literal, 8, 0, 0b1001_1010}, ADDRLO, ADDRHI, DATA, DATAIFW, ImpW1}},
    {.Call, {{.Literal, 8, 0, 0b1111_1111}, MOD, {.Literal, 3, 0, 0b011}, RM, ImpW1, Far}},
    // JMP = Jump:
    {.Jmp, {{.Literal, 8, 0, 0b1110_1001}, ADDRLO, ADDRHI, RelativeJMPDisplacement}},
    {.Jmp, {{.Literal, 8, 0, 0b1110_1011}, ADDRLO, RelativeJMPDisplacement}},
    {.Jmp, {{.Literal, 8, 0, 0b1111_1111}, MOD, {.Literal, 3, 0, 0b100}, RM, ImpW1}},
    {.Jmp, {{.Literal, 8, 0, 0b1110_1010}, ADDRLO, ADDRHI, DATA, DATAIFW, ImpW1}},
    {.Jmp, {{.Literal, 8, 0, 0b1111_1111}, MOD, {.Literal, 3, 0, 0b101}, RM, ImpW1, Far}},
    // RET = Return from CALL:
    {.Ret, {{.Literal, 8, 0, 0b1100_0011}}},
    {.Ret, {{.Literal, 8, 0, 0b1100_0010}, DATA, DATAIFW, ImpW1}},
    {.Retf, {{.Literal, 8, 0, 0b1100_1011}}}, // retf is not in the manual, but seems to be a thing.
    {.Retf, {{.Literal, 8, 0, 0b1100_1010}, DATA, DATAIFW, ImpW1}},
    {.Je, {{.Literal, 8, 0, 0b0111_0100}, ADDRLO, RelativeJMPDisplacement}},
    {.Jl, {{.Literal, 8, 0, 0b0111_1100}, ADDRLO, RelativeJMPDisplacement}},
    {.Jle, {{.Literal, 8, 0, 0b0111_1110}, ADDRLO, RelativeJMPDisplacement}},
    {.Jb, {{.Literal, 8, 0, 0b0111_0010}, ADDRLO, RelativeJMPDisplacement}},
    {.Jbe, {{.Literal, 8, 0, 0b0111_0110}, ADDRLO, RelativeJMPDisplacement}},
    {.Jp, {{.Literal, 8, 0, 0b0111_1010}, ADDRLO, RelativeJMPDisplacement}},
    {.Jo, {{.Literal, 8, 0, 0b0111_0000}, ADDRLO, RelativeJMPDisplacement}},
    {.Js, {{.Literal, 8, 0, 0b0111_1000}, ADDRLO, RelativeJMPDisplacement}},
    {.Jne, {{.Literal, 8, 0, 0b0111_0101}, ADDRLO, RelativeJMPDisplacement}},
    {.Jnl, {{.Literal, 8, 0, 0b0111_1101}, ADDRLO, RelativeJMPDisplacement}},
    {.Jnle, {{.Literal, 8, 0, 0b0111_1111}, ADDRLO, RelativeJMPDisplacement}},
    {.Jnb, {{.Literal, 8, 0, 0b0111_0011}, ADDRLO, RelativeJMPDisplacement}},
    {.Jnbe, {{.Literal, 8, 0, 0b0111_0111}, ADDRLO, RelativeJMPDisplacement}},
    {.Jnp, {{.Literal, 8, 0, 0b0111_1011}, ADDRLO, RelativeJMPDisplacement}},
    {.Jno, {{.Literal, 8, 0, 0b0111_0001}, ADDRLO, RelativeJMPDisplacement}},
    {.Jns, {{.Literal, 8, 0, 0b0111_1001}, ADDRLO, RelativeJMPDisplacement}},
    {.Loop, {{.Literal, 8, 0, 0b1110_0010}, ADDRLO, RelativeJMPDisplacement}},
    {.Loopz, {{.Literal, 8, 0, 0b1110_0001}, ADDRLO, RelativeJMPDisplacement}},
    {.Loopnz, {{.Literal, 8, 0, 0b1110_0000}, ADDRLO, RelativeJMPDisplacement}},
    {.Jcxz, {{.Literal, 8, 0, 0b1110_0011}, ADDRLO, RelativeJMPDisplacement}},
    // INT = Interrupt
    {.Int, {{.Literal, 8, 0, 0b1100_1101}, DATA}},
    {.Int3, {{.Literal, 8, 0, 0b1100_1100}}},
    {.Into, {{.Literal, 8, 0, 0b1100_1110}}},
    {.Iret, {{.Literal, 8, 0, 0b1100_1111}}},
    // PROCESSOR CONTROL
    {.Clc, {{.Literal, 8, 0, 0b1111_1000}}},
    {.Cmc, {{.Literal, 8, 0, 0b1111_0101}}},
    {.Stc, {{.Literal, 8, 0, 0b1111_1001}}},
    {.Cld, {{.Literal, 8, 0, 0b1111_1100}}},
    {.Std, {{.Literal, 8, 0, 0b1111_1101}}},
    {.Cli, {{.Literal, 8, 0, 0b1111_1010}}},
    {.Sti, {{.Literal, 8, 0, 0b1111_1011}}},
    {.Hlt, {{.Literal, 8, 0, 0b1111_0100}}},
    {.Wait, {{.Literal, 8, 0, 0b1001_1011}}},
    {.Esc, {{.Literal, 5, 0, 0b1101_1}, XXX, MOD, YYY, RM}},
    {.Lock, {{.Literal, 8, 0, 0b1111_0000}}},
    {.Segment, {{.Literal, 3, 0, 0b001}, SR, {.Literal, 3, 0, 0b110}}}, // Table notes this as having REG, but there's only room for SR! (and that makes sense)
}
