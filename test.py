#!/usr/bin/python3

import os

for file in os.listdir("tests/computer_enhance/perfaware/part1"):
    if not file.endswith(".asm"):
        out_file = os.path.join("out", file)
        with open(out_file, "w") as f:
            os.system(f"8086 tests/computer_enhance/perfaware/part1/{file} > {out_file}.asm")
        os.system(f"nasm {out_file}.asm -o {out_file}")
        os.system(f"diff {out_file} tests/computer_enhance/perfaware/part1/{file}")