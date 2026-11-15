# captain-goodnight

Captain Goodnight and the Islands of Fear (Broderbund, 1985), rehosted: on a ProDOS `.po` booted by tiny-dos (from
[conan](../conan)) from a SmartPort / block device, instead of the original's own track reader driving a Disk II in
slot 6. Work in progress.

The game is the SAN Inc crack's code and data, untouched: only its disk code is replaced.

## Setup

```sh
B=https://mirrors.apple2.org.za/ftp.apple.asimov.net/images/games/action/captain_goodnight
curl -o assets/CAPTAIN_GOODNIGHT_A.dsk "$B/captain%20goodnight%20a%20%28san%20inc%20crack%29.dsk"   # not in the repo
curl -o assets/CAPTAIN_GOODNIGHT_B.dsk "$B/captain%20goodnight%20b%20%28san%20inc%20crack%29.dsk"
./build.sh                      # -> mem/ snapshots, out/ listings, notes/
```

## How the original boots (side A)

No DOS on either side: tracks are read raw. Side B is data only (its boot sector says "THIS SIDE DOES NOT BOOT").
The load map is [meta/loadmap.txt](meta/loadmap.txt).

1. boot0 (`$0800`) decrypts `$0850` (EOR `$A5`) into `$0060-$015F` and `RTS`es into a chain of return addresses
   in the stack page.
2. Stage 2 (`$00B4`, `$0060`) reads T00 physical sectors 1-4 to `$0400-$07FF` through the PROM's ReadSector
   (`JSR $Cn5C`, its `JMP $0801` patched to an `RTS`), then returns into `$0401`.
3. The loader (`$0406`) puts the anti-tamper page at `$0300` and reads whole tracks with its own reader (slot 6
   hard-wired), sector s to page start+s:

| Track   | Load                  |
| ------- | --------------------- |
| T01     | LC bank 1 `$D000-$DFFF` |
| T02-T03 | LC `$E000-$FFFF`      |
| T04     | LC bank 2 `$D000-$DFFF` |
| T05-T06 | `$0800-$27FF`         |
| T07     | `$6000-$6FFF`         |

   It checks a XOR / sum of all of it against `$0404/$0405`, puts the head position in `$D40E` and jumps to `$6300`.

Every later disk access goes through LC bank 2: the jump table at `$D000` (section loader `$D502`), the track
loader `$D3A6`, a DOS 3.3-derived RWTS at `$D00C`. Side B's sections are checked against the side in the drive.
