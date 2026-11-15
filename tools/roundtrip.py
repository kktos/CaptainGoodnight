#!/usr/bin/env python3
"""Round-trip check: META -> tsasm source -> tsasm -> compare with the stream.

  roundtrip.py META [TSASM]     (TSASM default: $TSASM or `tsasm`)
Writes out/asm/<name>/{<name>.asm, project.yaml, <name>.bin, listing, symbols}.
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
from dis import Dis, Meta  # noqa: E402

meta = sys.argv[1]
tsasm = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("TSASM", "tsasm")
name = os.path.splitext(os.path.basename(meta))[0]
d = Dis(Meta(meta))
d.metapath = meta
d.run()
src = d.render_asm()
m = d.m
cks = sorted(d.chunks(), key=lambda c: m.addr(c[0]))
lo = m.addr(cks[0][0])
hi = max(m.addr(c0) + c1 - c0 for c0, c1 in cks)
expect = bytearray(hi - lo)
for c0, c1 in cks:
    a = m.addr(c0) - lo
    expect[a:a + c1 - c0] = m.stream[c0:c1]

wd = os.path.join(os.path.dirname(meta), "..", "out", "asm", name)
os.makedirs(wd, exist_ok=True)
open(os.path.join(wd, f"{name}.asm"), "w").write(src)
open(os.path.join(wd, "project.yaml"), "w").write(f"""input:
    cpu: 65C02
    source: {name}.asm
    segments:
        - {{ name: CODE, start: 0x{lo:04X}, size: 0, resizable: true }}
output:
    object:
        path: {name}.bin
    listing:
        path: {name}.lst
        pass2: true
    symbols:
        enabled: true
""")
r = subprocess.run(tsasm.split() + ["project.yaml"], cwd=wd, capture_output=True, text=True)
if r.returncode:
    print(r.stdout + r.stderr)
    sys.exit(f"{name}: tsasm failed")
got = open(os.path.join(wd, f"{name}.bin"), "rb").read()
if got == bytes(expect):
    print(f"{name}: OK  ${lo:04X}-${hi - 1:04X} ({len(got)} bytes, {len(cks)} region(s))")
    sys.exit(0)
diffs = [i for i in range(max(len(got), len(expect)))
         if i >= len(got) or i >= len(expect) or got[i] != expect[i]]
print(f"{name}: MISMATCH  got {len(got)} bytes, expected {len(expect)}; "
      f"{len(diffs)} differing bytes")
for i in diffs[:10]:
    g = f"{got[i]:02X}" if i < len(got) else "--"
    e = f"{expect[i]:02X}" if i < len(expect) else "--"
    print(f"  ${lo + i:04X}: got {g} expected {e}")
sys.exit(1)
