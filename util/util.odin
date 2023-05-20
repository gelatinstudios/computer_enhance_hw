
package hw_util

eat_byte :: proc (bytes: ^[]byte) -> (byte, bool) {
	if len(bytes^) == 0 do return 0, false
	
	result := bytes[0]
	bytes^ = bytes[1:]
	return result, true
}