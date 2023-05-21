@echo off

odin run source -out:build/test.exe -- %1 > output/output.asm
nasm output/output.asm -o output/output
fc output\output %1