#!/usr/bin/env python3
"""Find leftover high-bit assembler source text in a .dsk and dump it readably.

  srcfrag.py IMAGE [MIN]     prints each sector holding >= MIN (default 60) text chars;
                             consecutive text sectors are joined. Non-text bytes -> '~'.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from dsk import Disk  # noqa: E402

d = Disk(sys.argv[1])
mn = int(sys.argv[2]) if len(sys.argv) > 2 else 60


def is_src(sec):
    txt = "".join(chr(b & 0x7F) if (0xA0 <= b < 0xFF or b == 0x8D) else "\0" for b in sec)
    runs = re.findall(r"[^\0]{12,}", txt)
    good = [r for r in runs if "\r" in r and sum(c.isalpha() for c in r) > len(r) // 3]
    return sum(len(r) for r in good) >= mn


cur = None
for t in range(35):
    for s in range(16):
        sec = d.sector(t, s)
        if not is_src(sec):
            cur = None
            continue
        if cur is None:
            print(f"\n=============== T{t:02X}S{s:X}")
        else:
            print(f"\n----- T{t:02X}S{s:X}")
        cur = (t, s)
        out = []
        for b in sec:
            if b == 0x8D:
                out.append("\n")
            elif 0xA0 <= b < 0xFF:
                out.append(chr(b & 0x7F))
            else:
                out.append("~")
        print("".join(out))
