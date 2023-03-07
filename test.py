#!/usr/bin/python3

import os

for file in os.listdir("tests"):
    if not file.endswith(".asm"):
        out_file = os.path.join("out", file)
        with open(out_file, "w") as f:
            os.system(f"8086 tests/{file} > {out_file}.asm")
        os.system(f"nasm {out_file}.asm -o {out_file}")
        os.system(f"diff {out_file} tests/{file}")