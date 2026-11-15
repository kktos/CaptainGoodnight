#!/usr/bin/env python3
"""Apple II .dsk (DOS 3.3 order) reader.

Usage:
  dsk.py IMAGE map                    # sector usage map (empty / non-empty)
  dsk.py IMAGE catalog                # DOS 3.3 catalog, if any
  dsk.py IMAGE dump T S [count]       # hex dump of sectors
  dsk.py IMAGE extract T S count OUT  # raw sectors (linear, logical order) -> file
  dsk.py IMAGE file NAME OUT          # extract a DOS 3.3 file (follows T/S list)
"""
import sys

SECT = 256
NSECT = 16


class Disk:
    def __init__(self, path):
        self.data = open(path, "rb").read()
        assert len(self.data) == 143360, "expected 140K .dsk image"

    def sector(self, t, s):
        o = (t * NSECT + s) * SECT
        return self.data[o:o + SECT]

    def sectors(self, t, s, count):
        """Linear run of logical sectors, wrapping to next track."""
        out = b""
        for _ in range(count):
            out += self.sector(t, s)
            s += 1
            if s == NSECT:
                s, t = 0, t + 1
        return out

    # ---- DOS 3.3 ----
    def vtoc(self):
        v = self.sector(17, 0)
        if v[3] not in (3,) or v[0x27] != 0x7A:
            return None
        return v

    def catalog(self):
        v = self.vtoc()
        if not v:
            return []
        t, s = v[1], v[2]
        out, seen = [], set()
        while t and (t, s) not in seen:
            seen.add((t, s))
            c = self.sector(t, s)
            for i in range(7):
                e = c[0x0B + i * 35: 0x0B + (i + 1) * 35]
                if e[0] in (0, 0xFF):
                    continue
                name = bytes(b & 0x7F for b in e[3:33]).decode("ascii").rstrip()
                typ = e[2]
                out.append(dict(ts=(e[0], e[1]), type=typ, name=name,
                                length=e[33] | e[34] << 8))
            t, s = c[1], c[2]
        return out

    def file(self, name):
        ent = next((e for e in self.catalog() if e["name"] == name), None)
        if not ent:
            raise KeyError(name)
        t, s = ent["ts"]
        out, seen = b"", set()
        while t and (t, s) not in seen:
            seen.add((t, s))
            tsl = self.sector(t, s)
            for i in range(122):
                dt, ds = tsl[0x0C + 2 * i], tsl[0x0D + 2 * i]
                if dt == 0 and ds == 0:
                    break
                out += self.sector(dt, ds)
            t, s = tsl[1], tsl[2]
        return ent, out


TYPES = {0: "T", 1: "I", 2: "A", 4: "B", 8: "S", 0x10: "R", 0x20: "a", 0x40: "b"}


def hexdump(data, base=0):
    for i in range(0, len(data), 16):
        row = data[i:i + 16]
        h = " ".join(f"{b:02X}" for b in row)
        a = "".join(chr(b & 0x7F) if 32 <= (b & 0x7F) < 127 else "." for b in row)
        print(f"{base + i:04X}: {h:<47}  {a}")


def main():
    d = Disk(sys.argv[1])
    cmd = sys.argv[2]
    if cmd == "map":
        print("    " + "".join(f"{s:X}" for s in range(16)))
        for t in range(35):
            row = ""
            for s in range(16):
                sec = d.sector(t, s)
                row += "." if len(set(sec)) == 1 else "#"
            print(f"T{t:02X} {row}")
    elif cmd == "catalog":
        v = d.vtoc()
        if not v:
            print("no DOS 3.3 VTOC")
            return
        for e in d.catalog():
            lk = "*" if e["type"] & 0x80 else " "
            print(f"{lk}{TYPES.get(e['type'] & 0x7F, '?')} {e['length']:03d} "
                  f"T{e['ts'][0]:02X}S{e['ts'][1]:X} {e['name']}")
    elif cmd == "dump":
        t, s = int(sys.argv[3], 0), int(sys.argv[4], 0)
        n = int(sys.argv[5], 0) if len(sys.argv) > 5 else 1
        hexdump(d.sectors(t, s, n))
    elif cmd == "extract":
        t, s, n = (int(x, 0) for x in sys.argv[3:6])
        open(sys.argv[6], "wb").write(d.sectors(t, s, n))
    elif cmd == "file":
        ent, data = d.file(sys.argv[3])
        open(sys.argv[4], "wb").write(data)
        print(f"{len(data)} bytes")


if __name__ == "__main__":
    main()
