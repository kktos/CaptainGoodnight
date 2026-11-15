#!/usr/bin/env python3
"""
Check the built volume against what tools/extract.py took from the original disks, before booting it.

Reads dist/captain.po as tiny-dos does (the volume directory, each file's index block), and checks:
  GAME   = page3, game.0800-27FF, game.6000-6FFF
  LC     = lc1, lc2, lchi; lc2 may differ only in $D00C-$D3C5, the disk layer replaced
  tracks: every bin/{a,b}.Txx.bin, found as AuxLoadTrack finds it, from the TrackMap and FileRecords of the
          AUX_LOADER the build put in CAPTAIN (addresses from dist/captain.sym), is the same 4K; and TrackMap
          gives no other track

usage: tools/check.py [volume.po] [symbols.sym] [bindir]
"""

import os
import re
import sys

BLOCK = 512


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    po = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "..", "dist", "captain.po")
    symfile = sys.argv[2] if len(sys.argv) > 2 else os.path.join(here, "..", "dist", "captain.sym")
    bindir = sys.argv[3] if len(sys.argv) > 3 else os.path.join(here, "..", "bin")

    vol = open(po, "rb").read()
    errors = []

    def block(n):
        return vol[n * BLOCK : (n + 1) * BLOCK]

    # the volume directory, blocks 2-5: name -> (key block, storage type, aux type)
    files = {}
    n = 2
    while n:
        b = block(n)
        for e in range(13):
            entry = b[4 + e * 0x27 : 4 + (e + 1) * 0x27]
            storage, namelen = entry[0] >> 4, entry[0] & 0x0F
            if storage in (0, 0xE, 0xF):
                continue
            name = entry[1 : 1 + namelen].decode()
            files[name] = (entry[0x11] | entry[0x12] << 8, storage, entry[0x1F] | entry[0x20] << 8)
        n = b[2] | b[3] << 8

    def data(name, first=0, count=None):
        """The file's data blocks first.., through its index block: low bytes, then high bytes."""
        if name not in files:
            sys.exit(f"check: no file {name} on the volume")
        key, storage, _ = files[name]
        if storage != 2:
            sys.exit(f"check: {name} isn't a sapling file (storage type {storage})")
        index = block(key)
        out = b""
        i = first
        while i < 256 and (count is None or i < first + count):
            nb = index[i] | index[256 + i] << 8
            if nb == 0:
                break
            out += block(nb)
            i += 1
        return out

    def binfile(name):
        return open(os.path.join(bindir, name), "rb").read()

    def same(what, got, want):
        if got != want:
            at = next((i for i in range(min(len(got), len(want))) if got[i] != want[i]), min(len(got), len(want)))
            errors.append(f"{what}: differs at +${at:04X} ({len(got)} bytes, {len(want)} expected)")
            return False
        return True

    # the boot image
    same("GAME $0300", data("GAME", 0, 1)[:0x100], binfile("page3.0300-03FF.bin"))
    same("GAME $0800-$27FF", data("GAME", 1, 16), binfile("game.0800-27FF.bin"))
    same("GAME $6000-$6FFF", data("GAME", 17, 8), binfile("game.6000-6FFF.bin"))
    lc = data("LC")
    same("LC bank 1", lc[0x0000:0x1000], binfile("lc1.D000-DFFF.bin"))
    lc2, lc2_orig = lc[0x1000:0x2000], binfile("lc2.D000-DFFF.bin")
    same("LC bank 2 $D000-$D00B", lc2[:0x00C], lc2_orig[:0x00C])
    same("LC bank 2 $D3C6-$DFFF", lc2[0x3C6:], lc2_orig[0x3C6:])
    same("LC $E000-$FFFF", lc[0x2000:0x4000], binfile("lchi.E000-FFFF.bin"))

    # the tracks, as AuxLoadTrack finds them
    syms = {}
    for line in open(symfile):
        m = re.match(r"\s*([A-Z0-9_]+): \w+ number = \$([0-9A-F]+)", line)
        if m:
            syms.setdefault(m[1], int(m[2], 16))
    switch, trackmap, records = syms["AUX_SWITCH"], syms["TRACKMAP"], syms["FILERECORDS"]
    captain = data("CAPTAIN")
    aux = captain[0x400:]  # AUX_LOADER, after Init's 2 blocks; at AUX_SWITCH in the aux language card

    def peek(addr):
        return aux[addr - switch]

    tracks = 35
    seen = set()
    for side in "AB":
        for t in range(tracks):
            entry = peek(trackmap + "AB".index(side) * tracks + t)
            path = f"{side.lower()}.T{t:02X}.bin"
            has = os.path.exists(os.path.join(bindir, path))
            if entry == 0xFF:
                if has:
                    errors.append(f"side {side} T{t:02X}: read by the game, but TrackMap has no file for it")
                continue
            if not has:
                errors.append(f"side {side} T{t:02X}: TrackMap has it ({entry:02X}), the game doesn't read it")
                continue
            rec = peek(records + 2 * (entry >> 4)) | peek(records + 2 * (entry >> 4) + 1) << 8
            name = bytes(peek(rec + 5 + i) for i in range(peek(rec + 4))).decode()
            index = entry & 0x0F
            if same(f"side {side} T{t:02X} ({name} #{index})", data(name, index * 8, 8), binfile(path)):
                seen.add(path)

    if errors:
        print("\n".join(errors))
        sys.exit(f"check: {len(errors)} error(s)")
    print(f"check: OK, {os.path.basename(po)}: GAME, LC and {len(seen)} tracks as extracted")


if __name__ == "__main__":
    main()
