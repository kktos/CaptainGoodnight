#!/usr/bin/env python3
"""
Extract Captain Goodnight's memory images and tracks from the SAN Inc crack (.dsk, DOS 3.3 order) into bin/,
as the game's own loaders would read them, with their checks.

Boot (side A): the loader ($0406) reads one whole track per pair of DEST_TABLE ($04C3) entries, sector s to
page start+s, from track 1 on (bit 0 of an entry: LC bank 1), then checks the XOR / sum of it all against
$0404 / $0405. It also copies $063D-$073C to $0300 (the traps page).

Later, everything goes through LC bank 2 (see meta/lc2.meta):
  LOAD_SECTION n   tracks TRACK_LISTS + 8n ($DF0B: track - 1, $FF ends) to PAGE_LISTS + 8n ($DF6B), from the
                   side SECTION_SIDE[n] ($D552); then the $6300 page loaded must hold $6303 = SECTION_MARK[n]
                   ($D55E) and $6304 = the side
  LOAD_TRACK       (LOAD_SECTION with A = $FF) X = track - 1 to pages Y.., from the side in the drive:
                   the intro's script ($631A, opcode 0: X, Y), the game over (GOVER, side B's T22 to $B000,
                   checked by $B802 = $9A), section 11 (side A's T20 to $B000)

Every call into these loaders found in the code (the boot image and every track loaded) must be one listed
here: the script fails on any other, and on any check the game does that the data doesn't pass.

usage: tools/extract.py [sideA.dsk] [sideB.dsk] [outdir]
"""

import os
import sys

TRACK_SECTORS = 16
SECTOR = 256
TRACK = TRACK_SECTORS * SECTOR


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    assets = os.path.join(here, "..", "assets")
    dsk_a = sys.argv[1] if len(sys.argv) > 1 else os.path.join(assets, "CAPTAIN_GOODNIGHT_A.dsk")
    dsk_b = sys.argv[2] if len(sys.argv) > 2 else os.path.join(assets, "CAPTAIN_GOODNIGHT_B.dsk")
    out = sys.argv[3] if len(sys.argv) > 3 else os.path.join(here, "..", "bin")

    def read_dsk(path):
        data = open(path, "rb").read()
        if len(data) != 35 * TRACK:
            sys.exit(f"{path}: {len(data)} bytes, not a 140K .dsk")
        return data

    disks = {"A": read_dsk(dsk_a), "B": read_dsk(dsk_b)}

    def track(side, t):
        return disks[side][t * TRACK : (t + 1) * TRACK]

    def sector(side, t, s):
        at = (t * TRACK_SECTORS + s) * SECTOR
        return disks[side][at : at + SECTOR]

    def fail(msg):
        sys.exit(f"extract: {msg}")

    os.makedirs(out, exist_ok=True)

    def write(name, data, start=None):
        open(os.path.join(out, name), "wb").write(data)
        where = f"${start:04X}-${start + len(data) - 1:04X}" if start is not None else "(track)"
        print(f"  {name:22} {where:11} {len(data):5} bytes")

    # --- boot: the loader, T00 physical 1-4 = logical 7, E, 6, D -> $0400-$07FF
    loader = b"".join(sector("A", 0, s) for s in (0x7, 0xE, 0x6, 0xD))

    def at(addr, n=1, base=0x0400, mem=None):
        o = addr - base
        return (mem or loader)[o : o + n]

    dest_table = []
    for b in at(0x04C3, 16):
        if b == 0:
            break
        dest_table.append(b)
    if dest_table != [0xD1, 0xD9, 0xE0, 0xE8, 0xF0, 0xF8, 0xD0, 0xD8, 0x08, 0x10, 0x18, 0x20, 0x60, 0x68]:
        fail(f"DEST_TABLE isn't the one this script knows: {bytes(dest_table).hex(' ')}")

    main_mem, lc1, lc2, lchi = {}, {}, {}, {}  # page -> 256 bytes
    for i in range(0, len(dest_table), 2):  # an even entry reads a track: track i/2 + 1
        start, bank1 = dest_table[i] & 0xFE, dest_table[i] & 1
        for s, data in enumerate(track("A", i // 2 + 1)[k * SECTOR : (k + 1) * SECTOR] for k in range(16)):
            page = start + s
            (lchi if page >= 0xE0 else (lc1 if bank1 else lc2) if page >= 0xD0 else main_mem)[page] = data

    def pages(mem, first, last):
        return b"".join(mem[p] for p in range(first, last + 1))

    xor = add = 0
    for e in dest_table:  # CHECK ($05E3): 8 pages per entry
        page, bank1 = e & 0xFE, e & 1
        for p in range(page, page + 8):
            for b in (lchi if p >= 0xE0 else (lc1 if bank1 else lc2) if p >= 0xD0 else main_mem)[p]:
                xor ^= b
                add = (add + b) & 0xFF
    if (xor, add) != tuple(at(0x0404, 2)):
        fail(f"boot checksum {xor:02X} {add:02X}, the loader expects {at(0x0404, 2).hex(' ')}")

    print("boot:")
    write("page3.0300-03FF.bin", at(0x063D, 0x100), 0x0300)
    write("game.0800-27FF.bin", pages(main_mem, 0x08, 0x27), 0x0800)
    write("game.6000-6FFF.bin", pages(main_mem, 0x60, 0x6F), 0x6000)
    write("lc1.D000-DFFF.bin", pages(lc1, 0xD0, 0xDF), 0xD000)
    write("lc2.D000-DFFF.bin", pages(lc2, 0xD0, 0xDF), 0xD000)
    # split around $D00C-$D3C5, the disk layer the build replaces: the RWTS, READ_TRACK, READ_TRACK_AT, LOAD_TRACK
    write("lc2.D000-D00B.bin", pages(lc2, 0xD0, 0xDF)[:0x00C], 0xD000)
    write("lc2.D3C6-DFFF.bin", pages(lc2, 0xD0, 0xDF)[0x3C6:], 0xD3C6)
    write("lchi.E000-FFFF.bin", pages(lchi, 0xE0, 0xFF), 0xE000)

    bank2 = pages(lc2, 0xD0, 0xDF)
    game = bytearray(0x10000)
    for p, data in main_mem.items():
        game[p << 8 : (p + 1) << 8] = data

    def b2(addr, n=1):
        return bank2[addr - 0xD000 : addr - 0xD000 + n]

    # --- run-time loads
    used = {}  # (side, track) -> {page: what loads it there}

    def use(side, t, page, why):
        if len(set(track(side, t))) == 1:
            fail(f"{why}: side {side} T{t:02X} is empty")
        used.setdefault((side, t), {})[page] = why

    # LOAD_SECTION n
    sections = {}
    for n in range(12):
        side = "AB"[b2(0xD552 + n)[0]]
        mark = b2(0xD55E + n)[0]
        loads = []
        for i in range(8):
            t = b2(0xDF0B + 8 * n + i)[0]
            if t == 0xFF:
                break
            loads.append((t + 1, b2(0xDF6B + 8 * n + i)[0]))
        sections[n] = (side, mark, loads)

    # section 0 is the original's main code load, T0E-T10: empty on this crack (its boot image comes from T05-T07
    # instead), and nothing calls it. Sections 7, 8 and 10 load nothing: only the marks of the $6300 page already
    # there are checked.
    calls = {1, 2, 3, 4, 5, 6, 8, 9, 10, 11}
    print("sections:")
    for n, (side, mark, loads) in sections.items():
        if n not in calls:
            continue
        mem = {}
        for t, page in loads:
            for s in range(16):
                mem[page + s] = sector(side, t, s)
            use(side, t, page, f"section {n}")
        desc = " ".join(f"T{t:02X}>${p:02X}00" for t, p in loads) or "(no tracks)"
        if 0x63 in mem:
            if (mem[0x63][3], mem[0x63][4]) != (mark, "AB".index(side)):
                fail(f"section {n}: the $6300 page has marks {mem[0x63][3]:02X} {mem[0x63][4]:02X}, "
                     f"LOAD_SECTION wants {mark:02X} {'AB'.index(side):02X}")
            desc += f"  marks ${mark:02X} OK"
        print(f"  {n:2} side {side}  {desc}")

    # LOAD_TRACK: the intro script, $631A in the boot image
    script, pc = game[0x631A:0x63A2], 0
    intro = []
    args = {0: 2, 1: 1, 2: 0, 3: 1, 4: 0, 5: 0, 6: 0, 7: 2, 8: 0}
    while pc < len(script) and script[pc] in args:
        op = script[pc]
        if op == 0:
            intro.append((script[pc + 1] + 1, script[pc + 2]))
        pc += 1 + args[op]
    if pc != len(script) - 1 or script[pc] != 0xFF:
        fail(f"intro script: stops at ${0x631A + pc:04X} on {script[pc]:02X}, not on its $FF end")
    for t, page in intro:
        use("A", t, page, "intro")
    print("intro:", " ".join(f"T{t:02X}>${p:02X}00" for t, p in intro))

    # LOAD_TRACK: the fixed calls. (code, the bytes there, side, track, page)
    lt = bytes.fromhex("a9ffa2")  # LDA #$FF / LDX #
    fixed = [
        ("bank 2 $DA71 (game over)", b2(0xDA71, 9), "B", 0x22, 0xB0, "20 02 d5"),
        ("bank 2 $DC75 (game over)", b2(0xDC75, 9), "B", 0x22, 0xB0, "20 02 d5"),
        ("section 11 $7455", track("A", 0x22)[0x155:0x15E], "A", 0x20, 0xB0, "20 00 d0"),
    ]
    for where, code, side, t, page, jsr in fixed:
        if code != lt + bytes([t - 1, 0xA0, page]) + bytes.fromhex(jsr):
            fail(f"{where}: {code.hex(' ')} isn't LOAD_TRACK T{t:02X} to ${page:02X}00")
        use(side, t, page, where)
    if sector("B", 0x22, 8)[2] != 0x9A:  # what GOVER checks before JMP $B800
        fail("side B T22: $B802 isn't $9A")
    print("LOAD_TRACK:", ", ".join(f"{w}: {s} T{t:02X}>${p:02X}00" for w, _, s, t, p, _ in fixed))

    # every call into the loaders, in the boot image and in each track loaded: only the known ones
    known = {
        ("boot", 0x1D1F), ("boot", 0x63F2),  # JMPDISK's JSR $D000, the intro's LOAD_TRACK
        ("bank 2", 0xDA77), ("bank 2", 0xDC7B), ("bank 2", 0xDC90),  # GOVER, and its section 2 (play again?)
        ("A T22", 0x745B),  # section 11's LOAD_TRACK T20
    }
    section_calls = {}
    targets = {0xD000: "LOAD_SECTION_V", 0xD502: "LOAD_SECTION", 0xD3A6: "LOAD_TRACK", 0xD36B: "READ_TRACK_AT",
               0xD300: "READ_TRACK", 0xD00C: "READ_DATA", 0x1D17: "JMPDISK"}
    code = [("boot", bytes(game[0x0800:0x2800]), 0x0800), ("boot", bytes(game[0x6000:0x7000]), 0x6000),
            ("bank 1", pages(lc1, 0xD0, 0xDF), 0xD000), ("bank 2", bank2[0x600:], 0xD600),
            ("$E000", pages(lchi, 0xE0, 0xFF), 0xE000)]
    for (side, t), at_pages in sorted(used.items()):
        for p, why in at_pages.items():
            if why != "intro":  # the intro's tracks are pictures (with some junk that looks like code)
                code.append((f"{side} T{t:02X}", track(side, t), p << 8))
    for name, data, base in code:
        for i in range(len(data) - 2):
            if data[i] in (0x20, 0x4C) and data[i + 1] | data[i + 2] << 8 in targets:
                addr, tgt = base + i, data[i + 1] | data[i + 2] << 8
                if tgt == 0x1D17 and i >= 2 and data[i - 2] == 0xA9:
                    section_calls.setdefault(data[i - 1], []).append(f"{name} ${addr:04X}")
                elif (name, addr) not in known:
                    fail(f"{name} ${addr:04X}: a call to {targets[tgt]} this script doesn't know")
    if set(section_calls) | {2} != calls:  # section 2 is also loaded directly, by bank 2's $DC90
        fail(f"JMPDISK is called with {sorted(section_calls)}, not {sorted(calls)}")
    print("JMPDISK callers:", "; ".join(f"{n}: {', '.join(w)}" for n, w in sorted(section_calls.items())))

    # side A T08 S0 - T0B S7: a copy of bank 2 $D800-$DFFF, $0800-$27FF, $6000-$6FFF, which nothing reads
    copy = pages(lc2, 0xD8, 0xDF) + pages(main_mem, 0x08, 0x27) + pages(main_mem, 0x60, 0x6F)
    if disks["A"][8 * TRACK : 8 * TRACK + len(copy)] != copy:
        fail("side A T08-T0B isn't the copy of the boot image it was")

    print("tracks:")
    for (side, t) in sorted(used):
        write(f"{side.lower()}.T{t:02X}.bin", track(side, t))


if __name__ == "__main__":
    main()
