package sim8086

import "core:fmt"
import "core:mem"

Registers :: struct {
  using _ : struct #raw_union {
    ax: u16,
    using _ : struct {
      ah: u8,
      al: u8,
    },
  },
  using _ : struct #raw_union {
    bx: u16,
    using _ : struct {
      bh: u8,
      bl: u8,
    },
  },
  using _ : struct #raw_union {
    cx: u16,
    using _ : struct {
      ch: u8,
      cl: u8,
    },
  },
  using _ : struct #raw_union {
    dx: u16,
    using _ : struct {
      dh: u8,
      dl: u8,
    },
  },
  sp: u16,
  bp: u16,
  si: u16,
  di: u16,
  es: u16,
  cs: u16,
  ss: u16,
  ds: u16,
  ip: u16,
  flags: u16,
}

OperandAccess :: struct {
  address: union {
    ^u8,
    ^u16,
  },
  value: int,
}

simulate_instruction :: proc(disassembly_context: ^DisassemblyContext, registers: ^Registers, instruction: Instruction) {
  access0 := extract_operand_access(disassembly_context, registers, instruction.operands[0])
  access1 := extract_operand_access(disassembly_context, registers, instruction.operands[1])

  #partial switch instruction.op {
    case .Mov:
      switch address in access0.address {
        case (^u8):
          address^ = (u8)(access1.value)
        case (^u16):
          address^ = (u16)(access1.value)
      }
      break
  }
}

extract_operand_access :: proc(disassembly_context: ^DisassemblyContext, registers: ^Registers, operand: Operand) -> (operand_access: OperandAccess) {
  switch operand.type {
    case .None:
      break
    case .Register:
      reg_access := operand.value.(RegisterAccess)
      assert(reg_access.offset <= 1)
      assert(reg_access.count >= 1 && reg_access.count <= 2)
      assert(reg_access.offset + reg_access.count <= 2)


      target_register := mem.ptr_offset((^u16)(registers), (int)(reg_access.index) - 1)
      if reg_access.offset == 1 { // hi
        operand_access.address = mem.ptr_offset((^u8)(target_register), 1)
        operand_access.value = (int)(operand_access.address.(^u8)^)
      } else if reg_access.count == 1 { // lo
        operand_access.address = (^u8)(target_register)
        operand_access.value = (int)(operand_access.address.(^u8)^)
      } else {
        operand_access.address = (target_register)
        operand_access.value = (int)(target_register^)
      }
      break
    case .Memory:
      break
    case .Immediate:
      operand_access.value = (int)(operand.value.(Immediate).value)
  }
  return operand_access
}
