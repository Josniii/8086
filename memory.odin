package sim8086

import "core:os"
import "core:fmt"

/*
 Main memory of the 8086.
 The maximum addressable memory is 1MB (20 bit), 
 and the chip is using 4 segment registers to keep track of segments of 64 KB.
 The segment registers are:
 CS (Code Segment)
 DS (Data Segment)
 ES (Extra (data) Segment)
 SS (Stack Segment)
 */
Memory :: struct {
    bytes: [1024*1024]u8,
}
// This mask is used to ensure that addresses are within the addressable 1MB.
MemoryMask :: 0xFFFFF

SegmentAccess :: struct {
    segment: u16,
    offset: u16,
}

read_memory :: proc(memory: ^Memory, address: u32) -> u8 {
    return memory.bytes[address];
}

// Compute x86 Real Mode address.
get_real_address :: proc {
    get_real_address_segment_access,
    get_real_address_u16,
}

get_real_address_segment_access :: proc(segment_access: SegmentAccess, extra_offset: u16 = 0) -> u32 {
    return get_real_address_u16(segment_access.segment, segment_access.offset, extra_offset)
}

get_real_address_u16 :: proc(segment: u16, offset: u16, extra_offset: u16 = 0) -> u32 {
    return ((u32)(segment << 4) + (u32)(offset + extra_offset)) & MemoryMask
}

load_file_into_memory :: proc(filepath: string, memory: ^Memory) -> (int) {
    f, err_open := os.open(filepath)
    result, err_read := os.read(f, memory.bytes[:])
    os.close(f)
    return result
}
