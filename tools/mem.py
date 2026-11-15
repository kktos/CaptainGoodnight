#!/usr/bin/env python3
"""Replay a load map into a 64K memory image and save snapshots.

  mem.py LOADMAP

Load map lines (# comments):
  disk FILE                    .dsk image to read from (relative to loadmap)
  read TT S0-S1 PAGE           read track TT (hex) sectors S0..S1 (hex, may be
                               descending) into pages PAGE, PAGE+-1, ... following
                               the same direction as the sectors
  copy SRC DST LEN             memory copy ($hex)
  fill START END VALUE         fill [START, END] with VALUE
  eor SRC DST LEN VALUE        memory copy, each byte EORed with VALUE (decryption)
  save FILE START END          write memory [START, END] to FILE
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from dsk import Disk  # noqa: E402


def num(s):
    return int(s[1:], 16) if s.startswith("$") else int(s, 16)


def main():
    path = sys.argv[1]
    base = os.path.dirname(path)
    mem = bytearray(65536)
    disk = None
    for raw in open(path):
        line = raw.split("#")[0].split()
        if not line:
            continue
        c = line[0]
        if c == "disk":
            disk = Disk(os.path.join(base, line[1]))
        elif c == "read":
            t = int(line[1], 16)
            s0, s1 = (int(x, 16) for x in line[2].split("-"))
            page = num(line[3])
            step = 1 if s1 >= s0 else -1
            for i, s in enumerate(range(s0, s1 + step, step)):
                p = (page + i * step) * 256
                mem[p:p + 256] = disk.sector(t, s)
        elif c == "copy":
            src, dst, n = (num(x) for x in line[1:4])
            mem[dst:dst + n] = mem[src:src + n]
        elif c == "eor":
            src, dst, n, v = (num(x) for x in line[1:5])
            mem[dst:dst + n] = bytes(b ^ v for b in mem[src:src + n])
        elif c == "fill":
            a, b, v = (num(x) for x in line[1:4])
            mem[a:b + 1] = bytes([v]) * (b + 1 - a)
        elif c == "save":
            a, b = num(line[2]), num(line[3])
            out = os.path.join(base, line[1])
            os.makedirs(os.path.dirname(out), exist_ok=True)
            open(out, "wb").write(mem[a:b + 1])
            print(f"saved {line[1]} ${a:04X}-${b:04X}")
        else:
            raise SyntaxError(raw)


if __name__ == "__main__":
    main()
