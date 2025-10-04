package sim8086

import "core:os"
import "core:fmt"

main :: proc() {
    if len(os.args) < 2 {
        fmt.println("Please provide path to file!")
        return
    }
    memory := new(Memory)
    filepath := os.args[1]
    fmt.printf("; %s disassembly\n", filepath)
    num_bytes := load_file_into_memory(filepath, memory)
    assert(num_bytes < 0x10000)
    disassemble_from_memory(memory, u16(num_bytes))
}

disassemble_from_memory:: proc(memory: ^Memory, num_bytes: u16) {
    at_seg: SegmentAccess
    registers: Registers
    disassembly_context := DisassemblyContext({
        default_segment = .DS, // The Data Segment is the default segment.
    })
    bytes_left := num_bytes
    fmt.println("bits 16\n")
    for bytes_left > 0 {
        instruction := decode_instruction(&disassembly_context, memory, &at_seg)
        if instruction.op == .None {
            fmt.println("; ERROR: Could not decode instruction: Unable to match opcode.")
            break;
        }
        if bytes_left >= instruction.size {
            bytes_left = bytes_left - instruction.size
        } else {
            fmt.println("; ERROR: Instruction in stream exceeded total number of bytes given to decode.")
            break;
        }
        accept_instruction(&disassembly_context, instruction)
        if is_printable(instruction) {
            print_instruction(&instruction)
        }

        // print_registers(&registers)
        simulate_instruction(&disassembly_context, &registers, instruction)
    }
    print_registers(&registers)
}
