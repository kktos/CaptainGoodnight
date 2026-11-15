#!/usr/bin/env python3
"""
Load test of the rehosted build in vm6502: every load the game does, called directly, checksummed, compared
with what tools/extract.py extracted (with tools/patches.py's patches). Nobody plays far enough to reach every section.

  tools/loadtest.py cases        -> out/loadtest/cases.bin (at $3C00) and expect.json; assemble the harness:
                                    (cd test && tsasm loadtest.yaml) -> out/loadtest/loadtest.bin (at $3F00)
  tools/loadtest.py check DUMP   compares the sums, DUMP: a read_memory dump of $3D80, 16 bytes a case

In vm6502, from a state where the game runs (the intro, say): load_binary cases.bin at $3C00, loadtest.bin at
$3F00 with set_pc, run_until $3F8D (`done`, see out/loadtest/loadtest.lst), read_memory $3D80, 16 * cases.
A case: SECTION set (the side LOAD_TRACK reads), LOAD_SECTION ($D000) with A / X / Y, then a 16-bit sum of each
4K it loaded. A failed mark check never returns ("PLEASE FLIP DISK"): run_until times out.
"""

import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from patches import patched  # noqa: E402

here = os.path.dirname(os.path.abspath(__file__))
BIN = os.path.join(here, "..", "bin")
OUT = os.path.join(here, "..", "out", "loadtest")


def track(side, t):
    name = f"{side}.T{t:02X}.bin"
    return patched(name, open(os.path.join(BIN, name), "rb").read())


def cases():
    lc2 = open(os.path.join(BIN, "lc2.D000-DFFF.bin"), "rb").read()
    out = []
    for n in (1, 2, 3, 4, 5, 6, 9, 11):
        side, loads = "ab"[lc2[0x552 + n]], []
        for i in range(8):
            t = lc2[0xF0B + n * 8 + i]
            if t == 0xFF:
                break
            loads.append((t + 1, lc2[0xF6B + n * 8 + i]))
        out.append((f"section {n}", n, 0, 0, n, side, loads))
    # LOAD_TRACK (A = $FF): the intro's script ($631A), from section 0's side (A)
    game = open(os.path.join(BIN, "game.6000-6FFF.bin"), "rb").read()
    script, pc = game[0x31A:0x3A2], 0
    args = {0: 2, 1: 1, 2: 0, 3: 1, 4: 0, 5: 0, 6: 0, 7: 2, 8: 0}
    while script[pc] in args:
        if script[pc] == 0:
            t, p = script[pc + 1] + 1, script[pc + 2]
            out.append((f"intro T{t:02X}", 0xFF, t - 1, p, 0, "a", [(t, p)]))
        pc += 1 + args[script[pc]]
    out.append(("T20 (section 11)", 0xFF, 0x1F, 0xB0, 11, "a", [(0x20, 0xB0)]))
    out.append(("T22 game over (section 6)", 0xFF, 0x21, 0xB0, 6, "b", [(0x22, 0xB0)]))
    return out


def main():
    if sys.argv[1:2] == ["cases"]:
        os.makedirs(OUT, exist_ok=True)
        table, expect = bytearray(), []
        for name, a, x, y, section, side, loads in cases():
            mem = {}
            for t, p in loads:  # in order: a later track can overlap an earlier one
                data = track(side, t)
                for k in range(16):
                    mem[p + k] = data[k * 256 : (k + 1) * 256]
            starts = [p for _, p in loads]
            sums = [sum(b"".join(mem[p + k] for k in range(16))) & 0xFFFF for p in starts]
            table += bytes([a, x, y, section] + starts + [0] * (8 - len(starts)))
            expect.append((name, sums))
        table += bytes([0, 0, 0, 0xFE] + [0] * 8)
        if len(table) > 0x3D80 - 0x3C00 or 16 * len(expect) > 0x3F00 - 0x3D80:
            sys.exit("loadtest: too many cases for $3C00-$3EFF")
        open(os.path.join(OUT, "cases.bin"), "wb").write(table)
        json.dump(expect, open(os.path.join(OUT, "expect.json"), "w"))
        print(f"{len(expect)} cases: read_memory $3D80, {16 * len(expect)} bytes")
    elif sys.argv[1:2] == ["check"] and len(sys.argv) > 2:
        mem = {}
        for line in open(sys.argv[2]):
            m = re.match(r"\s*([0-9A-Fa-f]+):((?: [0-9A-Fa-f]{2})+)", line)
            if m:
                for i, b in enumerate(m[2].split()):
                    mem[int(m[1], 16) + i] = int(b, 16)
        bad = 0
        for c, (name, sums) in enumerate(json.load(open(os.path.join(OUT, "expect.json")))):
            at = 0x3D80 + 16 * c
            got = [mem[at + 2 * i] | mem[at + 2 * i + 1] << 8 for i in range(len(sums))]
            ok = got == sums
            bad += not ok
            print(f"{'OK ' if ok else 'BAD'} {name:24}", " ".join(f"{g:04X}" for g in got),
                  "" if ok else "expected " + " ".join(f"{s:04X}" for s in sums))
        sys.exit(f"loadtest: {bad} bad" if bad else 0)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
