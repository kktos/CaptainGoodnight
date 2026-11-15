#!/usr/bin/env python3
"""List traced instructions whose absolute operand falls in [LO, HI].
  refs.py META LO HI [FROM TO]     (FROM/TO: only instructions located there)"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from dis import Dis, Meta, OPS
m = Meta(sys.argv[1]); d = Dis(m); d.run()
lo, hi = int(sys.argv[2].lstrip("$"), 16), int(sys.argv[3].lstrip("$"), 16)
f0, f1 = (int(x.lstrip("$"), 16) for x in sys.argv[4:6]) if len(sys.argv) > 5 else (0, 0xFFFF)
for off, sz in sorted(d.size.items()):
    if d.ikind.get(off) != "op" or sz != 3:
        continue
    a = m.addr(off)
    if not f0 <= a <= f1:
        continue
    raw = m.stream[off:off + 3]
    v = raw[1] | raw[2] << 8
    if lo <= v <= hi:
        mn, md, _ = OPS[raw[0]]
        print(f"${a:04X}  {mn} ${v:04X}{'' if md == 'abs' else ' ' + md}")
