
package hw_1

import "core:fmt"
import "core:os"

eat_byte :: proc (bytes: ^[]byte) -> (byte, bool) {
	if len(bytes^) == 0 do return 0, false
	
	result := bytes[0]
	bytes^ = bytes[1:]
	return result, true
}

main :: proc() {
    bytes, ok := os.read_entire_file(os.args[1])
	assert(ok)
    
    fmt.println("bits 16")
    fmt.println(";", os.args[1])

    for len(bytes) > 0 {
	instruction_byte, _ := eat_byte(&bytes)
	
	opcode := instruction_byte >> 2
	assert(opcode == 0b100010) // we're only dealing with mov's

	d := (instruction_byte >> 1) & 1
	w := (instruction_byte >> 0) & 1

	operand_byte, ok := eat_byte(&bytes)
	assert(ok)

	mod := (operand_byte >> 6) & 0b11
	reg := (operand_byte >> 3) & 0b111
	rm  := (operand_byte >> 0) & 0b111

	assert(mod == 0b11) // only register mov's!!

	source := reg
	dest   := rm
	if d == 1 {
	    source, dest = dest, source
	}

	reg_tab := [?]string {
	    // w = 0
	    "al",
	    "cl",
	    "dl",
	    "bl",
	    "ah",
	    "ch",
	    "dh",
	    "bh",

	    // w = 1
	    "ax",
	    "cx",
	    "dx",
	    "bx",
	    "sp",
	    "bp",
	    "si",
	    "di",
	}

	dest   = (w<<3) | dest
	source = (w<<3) | source
	
	fmt.printf("mov {}, {}\n", reg_tab[dest], reg_tab[source])
    }
}
