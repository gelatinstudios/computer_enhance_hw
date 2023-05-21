
package hw_2

import "core:fmt"
import "core:os"

eat_byte :: proc (bytes: ^[]byte) -> (byte, bool) {
	if len(bytes^) == 0 do return 0, false
	
	result := bytes[0]
	bytes^ = bytes[1:]
	return result, true
}

eat_u16 :: proc (bytes: ^[]byte) -> (result: u16, ok: bool) {
    low  := eat_byte(bytes) or_return
    high := eat_byte(bytes) or_return

    return u16(high) << 8 | u16(low), true
}

Register :: enum {
    None,
    // w = 0
    al,
    cl,
    dl,
    bl,
    ah,
    ch,
    dh,
    bh,

    // w = 1
    ax,
    cx,
    dx,
    bx,
    sp,
    bp,
    si,
    di,
}

decode_reg :: proc(r: u8, is_wide: u8) -> Register {
    return Register(((is_wide << 3) | r) + 1)
}

Immediate :: struct {
    size_in_bytes: u8,
    value: u16,
}

Calculated_Address :: struct {
    reg1: Register,
    reg2: Register,
    disp: u16,
}

Operand :: union {
    Immediate,
    Calculated_Address,
    Register,
}

Opcode :: enum {
    error,
    mov,
}

Instruction :: struct {
    opcode: Opcode,
    dest: Operand,
    source: Operand,
}

eat_immediate :: proc (bytes: ^[]byte, size_in_bytes: u8) -> (result: u16, ok: bool) {
    if size_in_bytes == 0 {
	ok = true
    }
    if size_in_bytes == 1 {
	result = u16(eat_byte(bytes) or_return)
	ok = true
    }
    if size_in_bytes == 2 {
	return eat_u16(bytes)
    }
    return
}

decode :: proc(bytes: ^[]byte) -> (result: Instruction, ok: bool) {
    instruction_byte := eat_byte(bytes) or_return
    
    if instruction_byte >> 2 == 0b100010 { // register/memory to/from register
	result.opcode = .mov
	
	d := (instruction_byte >> 1) & 1
	w := (instruction_byte >> 0) & 1
	
	mod_reg_rm := eat_byte(bytes) or_return
	
	mod := (mod_reg_rm >> 6) & 0b11
	reg := (mod_reg_rm >> 3) & 0b111
	rm  := (mod_reg_rm >> 0) & 0b111

	a, b: Operand
	a = decode_reg(reg, w)
	if mod == 0b11 {
	    b = decode_reg(rm, w)
	} else {
	    disp_byte_size := mod
	    if mod == 0 && rm == 0b110 {
		disp_byte_size = 2
	    }

	    disp := eat_immediate(bytes, disp_byte_size) or_return
	    
	    reg1, reg2: Register
	    switch rm {
	    case 0b000: reg1,reg2 = .bx, .si
	    case 0b001: reg1,reg2 = .bx, .di
	    case 0b010: reg1,reg2 = .bp, .si
	    case 0b011: reg1,reg2 = .bp, .di
	    case 0b100: reg1 = .si
	    case 0b101: reg1 = .di
	    case 0b110: if mod != 0 do reg1 = .bp
	    case 0b111: reg1 = .bx
	    }

	    b = Calculated_Address {
		reg1 = reg1,
		reg2 = reg2,
		disp = disp
	    }
	}

	if d == 1 {
	    result.dest, result.source = a, b
	} else {
	    result.dest, result.source = b, a
	}
    } else if instruction_byte >> 4 == 0b1011 { // immediate to register
	result.opcode = .mov
	
	reg := instruction_byte & 0b111
	w := (instruction_byte >> 3) & 1

	size_in_bytes := w + 1
	
	result.dest = decode_reg(reg, w)
	result.source = Immediate {
	    value = eat_immediate(bytes, size_in_bytes) or_return,
	    size_in_bytes = size_in_bytes,
	}
    }

    
    return result, true
}

instruction_to_string :: proc(instruction: Instruction) -> string {
    return fmt.tprintf("{} {}, {}", instruction.opcode,
	       operand_to_string(instruction.dest),
	       operand_to_string(instruction.source))

    operand_to_string :: proc(operand: Operand) -> string {
	switch op in operand {
	case Immediate: return fmt.tprint(op.value)
	case Register:  return fmt.tprint(op)
	case Calculated_Address:
	    s: [3]string
	    count: int

	    maybe_add :: proc(s: ^[3]string, count: ^int, thing: $T) {
		if thing != {} {
		    s[count^] = fmt.tprint(thing)
		    count^ += 1
		}
	    }

	    maybe_add(&s, &count, op.reg1)
	    maybe_add(&s, &count, op.reg2)
	    maybe_add(&s, &count, op.disp)

	    // there's probably a join() i could use here but i don't really care
	    if count == 1 do return fmt.tprintf("[{}]", s[0])
	    if count == 2 do return fmt.tprintf("[{} + {}]", s[0], s[1])
	    if count == 3 do return fmt.tprintf("[{} + {} + {}]", s[0], s[1], s[2])
	}

	return ""
    }
}

main :: proc() {
    bytes, ok := os.read_entire_file(os.args[1])
    
    fmt.println("bits 16")
    fmt.println(";", os.args[1])

    for len(bytes) > 0 {
	free_all(context.temp_allocator)
	
	instruction, ok := decode(&bytes)
	assert(ok)

	// this sucks lol
	fmt.println(instruction_to_string(instruction))
    }
}
