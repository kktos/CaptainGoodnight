#!/usr/bin/env python3
"""Meta-driven 65C02 disassembler.

  dis.py META [-o LISTING] [-a TSASM_SOURCE]

The META file describes one byte stream and what we know about it.
Lines: `<directive> ...` or `<offset> <directive> ...`; `#` starts a comment line.
Offsets are stream offsets ($hex, 0x.., or decimal). Anything after ` ; ` on a
line is attached as an inline comment.

Stream (global):
  source FILE                       whole file
  source DSK T<t>S<s> [count N]     N logical sectors from a .dsk (default 1)
  include FILE                      read more meta (e.g. symbol files)
  cpu 6502|65c02                    default 65c02
  sym NAME $ADDR [LEN]              global symbol (ROM, I/O, zero page, ...); with LEN, the
                                    LEN bytes from ADDR print as NAME+n (a block of variables)
  window $START $END                only render this address range (repeatable)
  rebase $ADDR EXPR                 indexed operands (,X / ,Y) equal to ADDR print as EXPR
                                    (tables indexed from 1: rebase $793F TABLE-1)

Per offset:
  $off org $ADDR                    from here, address = ADDR + (off - $off)
  $off code                         code entry point: trace from here
  $off stop                         force end of trace (data follows)
  $off db [N]                       N data bytes (default 1)
  $off dw [N]                       N little-endian words
  $off ptr [N]                      N words that are code addresses (traced)
  $off rts [N]                      N words = addr-1 (RTS jump tables, traced)
  $off text [N]                     N bytes of (high-bit) ASCII
  $off lohi N                       N lo bytes followed by N hi bytes (ptr table)
  $off label NAME                   label at this offset
  $off comment TEXT                 block comment line(s) before this offset
  $off note TEXT                    inline comment on this line
  $off skip N                       N bytes not shown (filler)
  $off operand EXPR                 print the address operand of this instruction as EXPR
                                    (e.g. TABLE-1); the round-trip check verifies it
Address forms: any `$off` may be written `@$ADDR` to mean "the offset that
currently maps to ADDR" (first matching org range).
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from dsk import Disk  # noqa: E402

# ---------------------------------------------------------------- opcodes
OPS = {}


def _def(spec, cmos=False):
    for item in spec.split(","):
        op, mn, md = item.split()
        OPS[int(op, 16)] = (mn, md, cmos)


_def("00 BRK imp,01 ORA izx,05 ORA zp,06 ASL zp,08 PHP imp,09 ORA imm,0A ASL acc,"
     "0D ORA abs,0E ASL abs,10 BPL rel,11 ORA izy,15 ORA zpx,16 ASL zpx,18 CLC imp,"
     "19 ORA aby,1D ORA abx,1E ASL abx,20 JSR abs,21 AND izx,24 BIT zp,25 AND zp,"
     "26 ROL zp,28 PLP imp,29 AND imm,2A ROL acc,2C BIT abs,2D AND abs,2E ROL abs,"
     "30 BMI rel,31 AND izy,35 AND zpx,36 ROL zpx,38 SEC imp,39 AND aby,3D AND abx,"
     "3E ROL abx,40 RTI imp,41 EOR izx,45 EOR zp,46 LSR zp,48 PHA imp,49 EOR imm,"
     "4A LSR acc,4C JMP abs,4D EOR abs,4E LSR abs,50 BVC rel,51 EOR izy,55 EOR zpx,"
     "56 LSR zpx,58 CLI imp,59 EOR aby,5D EOR abx,5E LSR abx,60 RTS imp,61 ADC izx,"
     "65 ADC zp,66 ROR zp,68 PLA imp,69 ADC imm,6A ROR acc,6C JMP ind,6D ADC abs,"
     "6E ROR abs,70 BVS rel,71 ADC izy,75 ADC zpx,76 ROR zpx,78 SEI imp,79 ADC aby,"
     "7D ADC abx,7E ROR abx,81 STA izx,84 STY zp,85 STA zp,86 STX zp,88 DEY imp,"
     "8A TXA imp,8C STY abs,8D STA abs,8E STX abs,90 BCC rel,91 STA izy,94 STY zpx,"
     "95 STA zpx,96 STX zpy,98 TYA imp,99 STA aby,9A TXS imp,9D STA abx,A0 LDY imm,"
     "A1 LDA izx,A2 LDX imm,A4 LDY zp,A5 LDA zp,A6 LDX zp,A8 TAY imp,A9 LDA imm,"
     "AA TAX imp,AC LDY abs,AD LDA abs,AE LDX abs,B0 BCS rel,B1 LDA izy,B4 LDY zpx,"
     "B5 LDA zpx,B6 LDX zpy,B8 CLV imp,B9 LDA aby,BA TSX imp,BC LDY abx,BD LDA abx,"
     "BE LDX aby,C0 CPY imm,C1 CMP izx,C4 CPY zp,C5 CMP zp,C6 DEC zp,C8 INY imp,"
     "C9 CMP imm,CA DEX imp,CC CPY abs,CD CMP abs,CE DEC abs,D0 BNE rel,D1 CMP izy,"
     "D5 CMP zpx,D6 DEC zpx,D8 CLD imp,D9 CMP aby,DD CMP abx,DE DEC abx,E0 CPX imm,"
     "E1 SBC izx,E4 CPX zp,E5 SBC zp,E6 INC zp,E8 INX imp,E9 SBC imm,EA NOP imp,"
     "EC CPX abs,ED SBC abs,EE INC abs,F0 BEQ rel,F1 SBC izy,F5 SBC zpx,F6 INC zpx,"
     "F8 SED imp,F9 SBC aby,FD SBC abx,FE INC abx")
_def("04 TSB zp,0C TSB abs,12 ORA izp,14 TRB zp,1A INC acc,1C TRB abs,32 AND izp,"
     "34 BIT zpx,3A DEC acc,3C BIT abx,52 EOR izp,5A PHY imp,64 STZ zp,72 ADC izp,"
     "74 STZ zpx,7A PLY imp,7C JMP iax,80 BRA rel,89 BIT imm,92 STA izp,9C STZ abs,"
     "9E STZ abx,B2 LDA izp,D2 CMP izp,DA PHX imp,F2 SBC izp,FA PLX imp", cmos=True)

SIZE = dict(imp=1, acc=1, imm=2, zp=2, zpx=2, zpy=2, izx=2, izy=2, izp=2, rel=2,
            abs=3, abx=3, aby=3, ind=3, iax=3)
FMT = dict(imp="", acc="", imm="#{}", zp="{}", zpx="{},X", zpy="{},Y", izx="({},X)",
           izy="({}),Y", izp="({})", rel="{}", abs="{}", abx="{},X", aby="{},Y",
           ind="({})", iax="({},X)")
DISKII = ["DRV_PH0OFF", "DRV_PH0ON", "DRV_PH1OFF", "DRV_PH1ON", "DRV_PH2OFF",
          "DRV_PH2ON", "DRV_PH3OFF", "DRV_PH3ON", "DRV_MOTOROFF", "DRV_MOTORON",
          "DRV_DRV1EN", "DRV_DRV2EN", "DRV_Q6L", "DRV_Q6H", "DRV_Q7L", "DRV_Q7H"]
ENDS = {"RTS", "RTI", "JMP", "BRA", "BRK"}


# ---------------------------------------------------------------- meta
def num(s):
    s = s.strip()
    if s.startswith("$"):
        return int(s[1:], 16)
    return int(s, 0)


class Meta:
    def __init__(self, path):
        self.stream = b""
        self.cpu = "65c02"
        self.syms = {}          # addr -> name (global)
        self.symblocks = []     # (addr, len, name): bytes print as name+n
        self.orgs = []          # (off, addr)
        self.windows = []       # (start_addr, end_addr) rendered; empty = all
        self.rebases = {}       # indexed operand address -> expression
        self.items = []         # (offkey, directive, args, inline_comment)
        self.load(path)

    def load(self, path):
        base = os.path.dirname(path)
        for raw in open(path):
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            note = None
            if " ; " in line:
                line, note = line.split(" ; ", 1)
            parts = line.split()
            if parts[0].startswith(("$", "@")) or parts[0][0].isdigit():
                key, d, args = parts[0], parts[1], parts[2:]
                if d in ("comment", "note", "operand"):
                    args = [line.split(None, 2)[2] if len(parts) > 2 else ""]
                self.items.append((key, d, args, note))
                if d == "org":
                    self.orgs.append((num(key), num(args[0])))
                continue
            d, args = parts[0], parts[1:]
            if d == "source":
                p = os.path.join(base, args[0])
                if len(args) == 1:
                    self.stream += open(p, "rb").read()
                else:
                    m = re.fullmatch(r"T([0-9A-Fa-f]+)S([0-9A-Fa-f]+)", args[1])
                    t, s = int(m[1], 16), int(m[2], 16)
                    n = num(args[3]) if len(args) > 3 and args[2] == "count" else 1
                    self.stream += Disk(p).sectors(t, s, n)
            elif d == "include":
                self.load(os.path.join(base, args[0]))
            elif d == "rebase":
                self.rebases[num(args[0])] = args[1]
            elif d == "window":
                self.windows.append((num(args[0]), num(args[1])))
            elif d == "cpu":
                self.cpu = args[0].lower()
            elif d == "sym":
                self.syms[num(args[1])] = args[0]
                if len(args) > 2:
                    self.symblocks.append((num(args[1]), num(args[2]), args[0]))
            else:
                raise SyntaxError(f"unknown directive: {raw.strip()}")

    # offset <-> address
    def addr(self, off):
        best = None
        for o, a in self.orgs:
            if o <= off and (best is None or o >= best[0]):
                best = (o, a)
        return off if best is None else best[1] + off - best[0]

    def off_of(self, addr, near=None):
        """Offset mapping to addr. Prefer the org range containing `near`."""
        rngs = sorted(self.orgs)
        cands = []
        for i, (o, a) in enumerate(rngs):
            end = rngs[i + 1][0] if i + 1 < len(rngs) else len(self.stream)
            if a <= addr < a + (end - o):
                cands.append((o, end, o + addr - a))
        if not cands:
            return None
        if near is not None:
            for o, end, x in cands:
                if o <= near < end:
                    return x
        return cands[0][2]

    def key(self, k):
        if k.startswith("@"):
            o = self.off_of(num(k[1:]))
            if o is None:
                raise ValueError(f"address {k} not in stream")
            return o
        return num(k)


# ---------------------------------------------------------------- engine
class Dis:
    def __init__(self, meta):
        self.m = meta
        n = len(meta.stream)
        self.kind = [None] * n      # 'op','opx'(operand),'db','dw','text',... per byte
        self.size = {}              # off -> item size (for starts)
        self.ikind = {}             # off -> item kind
        self.labels = {}            # off -> name
        self.comments = {}          # off -> [lines]
        self.notes = {}             # off -> str
        self.xref = {}              # target off -> set(src off)
        self.ext = {}               # abs addr outside stream refs -> set(src off)
        self.stops = set()
        self.skips = {}
        self.operands = {}          # off -> operand expression override (address part)
        self.entries = []
        self.warnings = []

    def run(self):
        m = self.m
        typed = []
        for k, d, args, note in m.items:
            off = m.key(k)
            if note:
                self.notes[off] = note
            if d == "org":
                pass
            elif d == "code":
                self.entries.append(off)
            elif d == "stop":
                self.stops.add(off)
            elif d == "label":
                self.labels[off] = args[0]
            elif d == "comment":
                self.comments.setdefault(off, []).append(args[0])
            elif d == "note":
                self.notes[off] = args[0]
            elif d == "operand":
                self.operands[off] = args[0]
            elif d == "skip":
                self.skips[off] = num(args[0])
            elif d in ("db", "dw", "ptr", "rts", "text", "lohi"):
                typed.append((off, d, num(args[0]) if args else 1))
            else:
                raise SyntaxError(f"unknown directive {d}")
        # data first (data wins over tracing)
        for off, d, n in typed:
            self.mark_data(off, d, n)
        for off in self.skips:
            for i in range(off, off + self.skips[off]):
                self.kind[i] = "skip"
        # trace
        work = list(self.entries)
        while work:
            work.extend(self.trace(work.pop()))
        # auto labels for referenced offsets
        for t in self.xref:
            if t not in self.labels and self.kind[t] in ("op",) or \
               (t not in self.labels and self.kind[t] is not None and t in self.size):
                a = m.addr(t)
                self.labels.setdefault(t, f"L{a:04X}")

    def mark_data(self, off, d, n):
        m = self.m
        if d == "db" or d == "text":
            self.size[off], self.ikind[off] = n, d
            for i in range(off, off + n):
                self.kind[i] = d
        elif d in ("dw", "ptr", "rts"):
            for j in range(n):
                o = off + 2 * j
                self.size[o], self.ikind[o] = 2, d
                self.kind[o] = self.kind[o + 1] = d
                if d in ("ptr", "rts"):
                    a = m.stream[o] | m.stream[o + 1] << 8
                    if d == "rts":
                        a += 1
                    t = m.off_of(a, near=o)
                    if t is not None:
                        self.xref.setdefault(t, set()).add(o)
                        self.entries.append(t)
        elif d == "lohi":
            for j in range(n):
                a = m.stream[off + j] | m.stream[off + n + j] << 8
                self.notes.setdefault(off + j, f"-> ${a:04X}")
            for o in (off, off + n):
                self.size[o], self.ikind[o] = n, "db"
                for i in range(o, o + n):
                    self.kind[i] = "db"

    def trace(self, off):
        m, s = self.m, self.m.stream
        new = []
        while 0 <= off < len(s):
            if self.kind[off] == "op":
                return new          # already traced
            if self.kind[off] is not None:
                self.warnings.append(f"trace ran into {self.kind[off]} at "
                                     f"${m.addr(off):04X} (off ${off:04X})")
                return new
            op = s[off]
            info = OPS.get(op)
            if info is None or (info[2] and m.cpu == "6502"):
                self.warnings.append(f"bad opcode ${op:02X} at ${m.addr(off):04X} "
                                     f"(off ${off:04X})")
                return new
            mn, md, _ = info
            n = SIZE[md]
            if off + n > len(s) or any(self.kind[i] for i in range(off + 1, off + n)):
                self.warnings.append(f"overlap at ${m.addr(off):04X}")
                return new
            self.kind[off] = "op"
            for i in range(off + 1, off + n):
                self.kind[i] = "opx"
            self.size[off], self.ikind[off] = n, "op"
            # targets
            tgt = None
            if md == "rel":
                r = s[off + 1]
                tgt = (m.addr(off) + 2 + (r - 256 if r > 127 else r)) & 0xFFFF
            elif n == 3:
                tgt = s[off + 1] | s[off + 2] << 8
            elif n == 2 and md != "imm":
                tgt = s[off + 1]
            if tgt is not None:
                t = m.off_of(tgt, near=off) if md not in ("zp", "zpx", "zpy", "izx",
                                                          "izy", "izp") else None
                if t is not None:
                    self.xref.setdefault(t, set()).add(off)
                    if md == "rel" or (mn in ("JMP", "JSR") and md == "abs"):
                        new.append(t)
                else:
                    self.ext.setdefault(tgt, set()).add(off)
            if mn in ENDS or (off + n) in self.stops:
                return new
            off += n
        return new

    # ------------------------------------------------------------ output
    def sym(self, addr, near, zp=False):
        t = self.m.off_of(addr, near=near) if not zp else None
        if t is not None and t in self.labels and \
                not (re.fullmatch(r"L[0-9A-F]{4}", self.labels[t]) and addr in self.m.syms):
            return self.labels[t]
        if t is not None:
            # inside an item: label+n
            for k in range(1, 256):
                if t - k in self.labels and self.size.get(t - k, 0) > k:
                    return f"{self.labels[t - k]}+{k}"
                if t - k in self.size and t - k in self.labels:
                    break
        if addr in self.m.syms:
            return self.m.syms[addr]
        for b, n, name in self.m.symblocks:
            if b < addr < b + n:
                return f"{name}+{addr - b}"
        return f"${addr:02X}" if zp else f"${addr:04X}"

    def render(self):
        m, s = self.m, self.m.stream
        out = []
        out.append(f"; generated by dis.py  cpu={m.cpu}  stream=${len(s):04X} bytes")
        used = sorted(a for a in self.ext if a in m.syms)
        if used:
            out.append(";")
            for a in used:
                out.append(f"{m.syms[a]:<16} = ${a:04X}" if a > 255 else
                           f"{m.syms[a]:<16} = ${a:02X}")
        orgset = dict(m.orgs)
        off = 0
        win = m.windows
        while off < len(s):
            if win and not any(a0 <= m.addr(off) <= a1 for a0, a1 in win):
                off += 1
                if any(m.addr(off) == a0 for a0, _ in win):
                    out.append("")
                    out.append(f"{'':16}.org ${m.addr(off):04X}")
                continue
            if off in orgset:
                out.append("")
                out.append(f"{'':16}.org ${orgset[off]:04X}")
            for c in self.comments.get(off, []):
                out.append(f"; {c}")
            if off in self.labels and self.ikind.get(off) == "op" and \
               off not in self.comments:
                out.append("")
            a = m.addr(off)
            k = self.kind[off]
            if k == "skip":
                n = self.skips.get(off, 1)
                out.append(f"{a:04X}-  {'':9} {'':16}.res {n}   ; (skipped)")
                off += n
                continue
            if k == "op":
                n = self.size[off]
                raw = s[off:off + n]
                mn, md, _ = OPS[raw[0]]
                if md == "rel":
                    r = raw[1]
                    t = (a + 2 + (r - 256 if r > 127 else r)) & 0xFFFF
                    opnd = self.sym(t, off)
                elif n == 3:
                    v = raw[1] | raw[2] << 8
                    if md in ("abx", "aby") and 0xC080 <= v <= 0xC08F:
                        opnd = DISKII[v - 0xC080]   # slot-indexed Disk II I/O
                    else:
                        opnd = self.operands.get(off) or \
                            (m.rebases.get(v) if md in ("abx", "aby") else None) or self.sym(v, off)
                elif md == "imm":
                    opnd = f"${raw[1]:02X}"
                elif n == 2:
                    opnd = self.sym(raw[1], off, zp=True)
                else:
                    opnd = "A" if md == "acc" else ""
                text = f"{mn} {FMT[md].format(opnd)}" if md not in ("imp", "acc") \
                    else (f"{mn} A" if md == "acc" else mn)
                line = self.line(off, a, raw, text)
                out.append(line)
                if mn in ENDS:
                    out.append(f"{'':16};")
                off += n
                continue
            # data
            if k in ("dw", "ptr", "rts") and off in self.size:
                v = s[off] | s[off + 1] << 8
                txt = f".word {self.sym(v, off)}" if k == "ptr" else \
                    (f".word {self.sym(v + 1, off)}-1" if k == "rts" else f".word ${v:04X}")
                out.append(self.line(off, a, s[off:off + 2], txt))
                off += 2
                continue
            if k == "text":
                n = self.size.get(off, 1)
                chunk = s[off:off + n]
                hi = all(b & 0x80 for b in chunk)
                txt = "".join(chr(b & 0x7F) for b in chunk)
                if all(32 <= ord(c) < 127 for c in txt) and '"' not in txt:
                    d = ".hstr" if hi else ".str"
                    out.append(self.line(off, a, chunk[:3], f'{d} "{txt}"'))
                    off += n
                    continue
                k = "db"
            # db or untyped: up to 8 bytes, break at labels/next item
            n = 1
            while n < 8 and off + n < len(s) and self.kind[off + n] == k and \
                    (off + n) not in self.labels and (off + n) not in self.comments \
                    and (off + n) not in orgset and (off + n) not in self.size \
                    and (off + n) not in self.notes:
                n += 1
            chunk = s[off:off + n]
            # collapse long runs of one value
            if k is None:
                r = off
                while r < len(s) and self.kind[r] is None and s[r] == s[off] and \
                        (r == off or (r not in self.labels and r not in orgset
                                      and r not in self.comments)):
                    r += 1
                if r - off >= 16:
                    out.append(f"{a:04X}-  {s[off]:02X} ...    {'':16}"
                               f".res {r - off},${s[off]:02X}")
                    off = r
                    continue
            txt = ".byte " + ",".join(f"${b:02X}" for b in chunk)
            out.append(self.line(off, a, chunk[:3], txt))
            off += n
        return "\n".join(out) + "\n"

    def line(self, off, a, raw, text):
        lab = self.labels.get(off, "")
        h = " ".join(f"{b:02X}" for b in raw[:3])
        line = f"{a:04X}-  {h:<9} {lab:<16}{text}"
        cm = []
        if off in self.notes:
            cm.append(self.notes[off])
        if off in self.xref and self.ikind.get(off) == "op":
            srcs = sorted(self.m.addr(x) for x in self.xref[off])
            if len(srcs) <= 4:
                cm.append("<- " + " ".join(f"{x:04X}" for x in srcs))
            else:
                cm.append(f"<- {len(srcs)} refs")
        if cm:
            line = f"{line:<56}; " + " | ".join(cm)
        return line

    # ------------------------------------------------------------ tsasm source
    def chunks(self):
        """Contiguous rendered regions: [(start_off, end_off)] (end exclusive)."""
        m, n = self.m, len(self.m.stream)
        orgs = {o for o, _ in m.orgs}
        vis = [not m.windows or any(a0 <= m.addr(o) <= a1 for a0, a1 in m.windows)
               for o in range(n)]
        out, start = [], None
        for o in range(n + 1):
            brk = o == n or not vis[o] or (o in orgs and start is not None)
            if brk and start is not None:
                out.append((start, o))
                start = None
            if o < n and vis[o] and start is None:
                start = o
        return out

    def render_asm(self, cpu="65C02"):
        m, s = self.m, self.m.stream
        self.used = set()
        self.outside = {}
        body = []
        self._cks = self.chunks()
        cks = sorted(self._cks, key=lambda c: m.addr(c[0]))
        for i in range(1, len(cks)):
            p, c = cks[i - 1], cks[i]
            if m.addr(c[0]) < m.addr(p[0]) + (p[1] - p[0]):
                raise SystemExit(f"overlapping regions at ${m.addr(c[0]):04X}: "
                                 "overlays need separate metas")
        for c0, c1 in cks:
            body.append("")
            body.append(f"\t.org ${m.addr(c0):04X}")
            self.asm_chunk(c0, c1, body)
        head = [f"; generated by dis.py from {os.path.basename(self.metapath)}",
                f"\t.cpu {cpu}", ""]
        for a in sorted(self.used):
            head.append(f"{m.syms[a]} = ${a:02X}" if a < 256 else
                        f"{m.syms[a]} = ${a:04X}")
        if self.outside:
            head.append("; labels outside the rendered window(s)")
            for n, a in sorted(self.outside.items(), key=lambda x: x[1]):
                head.append(f"{n} = ${a:04X}")
        return "\n".join(head + body) + "\n"

    def asym(self, addr, near, zp=False):
        r = self.sym(addr, near, zp)
        if addr in self.m.syms and r == self.m.syms[addr]:
            self.used.add(addr)
        elif "+" in r and any(r.startswith(name + "+") for _, _, name in self.m.symblocks):
            base = r.split("+")[0]
            self.used.add(next(b for b, _, name in self.m.symblocks if name == base))
        elif not r.startswith("$"):
            base = r.split("+")[0]
            t = next((o for o, n in self.labels.items() if n == base), None)
            if t is not None and not any(c0 <= t < c1 for c0, c1 in self._cks):
                self.outside[base] = self.m.addr(t)   # label not in the source
        return r

    def asm_chunk(self, off, end, out):
        m, s = self.m, self.m.stream

        def emit(o, text):
            lab = self.labels.get(o)
            cm = []
            if o in self.notes:
                cm.append(self.notes[o])
            if o in self.xref and self.ikind.get(o) == "op":
                srcs = sorted(m.addr(x) for x in self.xref[o])
                cm.append("<- " + (" ".join(f"${x:04X}" for x in srcs)
                                   if len(srcs) <= 4 else f"{len(srcs)} refs"))
            if lab:
                out.append(f"{lab}:")
            line = f"\t{text}"
            if cm:
                line = f"{line:<40}; " + " | ".join(cm)
            out.append(line)

        while off < end:
            for c in self.comments.get(off, []):
                out.append(f"; {c}")
            a = m.addr(off)
            k = self.kind[off]
            if k == "op" and off + self.size[off] <= end:
                n = self.size[off]
                raw = s[off:off + n]
                mn, md, _ = OPS[raw[0]]
                mn = mn.lower()
                if md == "rel":
                    r = raw[1]
                    t = (a + 2 + (r - 256 if r > 127 else r)) & 0xFFFF
                    opnd = self.asym(t, off)
                elif n == 3:
                    v = raw[1] | raw[2] << 8
                    if md in ("abx", "aby") and 0xC080 <= v <= 0xC08F:
                        opnd = f"${v:04X}"          # slot-indexed Disk II I/O
                        self.notes.setdefault(off, DISKII[v - 0xC080])
                    else:
                        opnd = self.operands.get(off) or \
                            (m.rebases.get(v) if md in ("abx", "aby") else None) or self.asym(v, off)
                    if v < 0x100 and md in ("abs", "abx", "aby"):
                        mn += ".w"                  # absolute form of a zp address
                elif md == "imm":
                    opnd = f"${raw[1]:02X}"
                elif n == 2:
                    opnd = self.asym(raw[1], off, zp=True)
                if md == "imp":
                    text = mn
                elif md == "acc":
                    text = f"{mn} a"
                else:
                    text = f"{mn} {FMT[md].format(opnd).replace(',X', ',x').replace(',Y', ',y')}"
                emit(off, text)
                if mn in ("rts", "rti", "jmp", "bra", "brk"):
                    out.append("")
                off += n
                continue
            if k in ("dw", "ptr", "rts") and off in self.size and off + 2 <= end:
                v = s[off] | s[off + 1] << 8
                txt = f".dw {self.asym(v, off)}" if k == "ptr" else \
                    (f".dw {self.asym(v + 1, off)}-1" if k == "rts" else f".dw ${v:04X}")
                emit(off, txt)
                off += 2
                continue
            if k == "text":
                n = min(self.size.get(off, 1), end - off)
                chunk = s[off:off + n]
                txt = "".join(chr(b & 0x7F) for b in chunk)
                if all(32 <= ord(c) < 127 for c in txt) and '"' not in txt \
                        and '\\' not in txt:
                    if not any(b & 0x80 for b in chunk):
                        emit(off, f'.text "{txt}"')
                    else:
                        self.notes.setdefault(off, f'"{txt}"')
                        emit(off, ".db " + ",".join(f"${b:02X}" for b in chunk))
                    off += n
                    continue
            # bytes: db, skip, untyped, partial items at chunk end
            run = 1
            while off + run < end and s[off + run] == s[off] and \
                    self.kind[off + run] in (None, "skip") and \
                    (off + run) not in self.labels and (off + run) not in self.comments:
                run += 1
            if run >= 16 and k in (None, "skip"):
                emit(off, f".fill {run}, ${s[off]:02X}")
                off += run
                continue
            n = 1
            while n < 8 and off + n < end and self.kind[off + n] in (k, "opx") and \
                    self.kind[off + n] != "op" and \
                    (off + n) not in self.labels and (off + n) not in self.comments \
                    and (off + n) not in self.size and (off + n) not in self.notes:
                n += 1
            emit(off, ".db " + ",".join(f"${b:02X}" for b in s[off:off + n]))
            off += n


def main():
    args = sys.argv[1:]
    out = asm = None
    if "-a" in args:
        i = args.index("-a")
        asm = args[i + 1]
        del args[i:i + 2]
    if "-o" in args:
        i = args.index("-o")
        out = args[i + 1]
        del args[i:i + 2]
    d = Dis(Meta(args[0]))
    d.metapath = args[0]
    d.run()
    txt = d.render()
    if asm:
        open(asm, "w").write(d.render_asm())
    for w in d.warnings:
        print("warning:", w, file=sys.stderr)
    if out:
        open(out, "w").write(txt)
    else:
        sys.stdout.write(txt)


if __name__ == "__main__":
    main()
