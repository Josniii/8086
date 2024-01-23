# Disassembler for Intel's 8086 assembly instruction set.
This repository contains homework code for Computer Enhance's Performance Aware Programming Series. Written in [Odin](https://odin-lang.org/) to try out the language. Hopefully one day I'll get around to the simulating at least some of the processor here as well.

An old version of the disassembler is included in oldmain. This is basically a giant switch statement (because it was easy to start with) and once it became clear that decoding instructions was a bit more involved (and that instruction simulation was coming), I rewrote the program to be based around a table of instructions.

## Build / test.
Build with `odin build`. Thats about it.

Test with `python3 test.py` (Requires NASM installed). This runs the disassembler on all the provided sample assembly files as well as a few extra instructions which used to not be included in the homework, reassembles the output with NASM and compares the result with the original. 

Any errors in the results should appear (no output is good!).
