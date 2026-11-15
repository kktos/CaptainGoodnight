"""
The rehost's changes to the extracted tracks (bin/), outside the disk layer: what the build's sources change, so
tools/check.py and tools/loadtest.py expect the patched bytes, and nothing else differs.

  PATCHES[bin name] = [(offset in the 4K, the new bytes, why)]
"""

PATCHES = {
    "b.T01.bin": [
        # src/modules/tracks/part1.asm
        (0x000B, bytes([0xEA] * 0x1C), "PART1 $630B-$6326: LC bank 2, SLOT16 from DISK_SLOT16, the RNG seed from the "
         "Disk II data latch (TAX / LDA $C08C,X / EOR $80 / STA RND), LC bank 1: NOPs"),
    ],
    "a.T21.bin": [
        # src/modules/tracks/end11.asm
        (0x046E, bytes([0x4C, 0x40, 0x03] + [0xEA] * 13), "END11 $676E-$677D: the reboot, JMP $Cn00 built from "
         "SLOT16: JMP REBOOT ($0340), NOPs"),
    ],
}


def patched(name, data):
    """data, a bin/ file's content, with the rehost's patches applied."""
    out = bytearray(data)
    for at, new, _ in PATCHES.get(name, []):
        out[at:at + len(new)] = new
    return bytes(out)
