@echo off

odin run source -out:test.exe -- %1 > output.asm
if errorlevel == 0 (
	nasm output.asm -o output
	fc output %1
)