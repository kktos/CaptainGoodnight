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

## How the game loads (LC bank 2)

Every later disk access goes through LC bank 2, [meta/lc2.meta](meta/lc2.meta): a read-only RWTS (`$D00C` data
field, `$D0E4` seek, `$D121` address field, `$D300` a track's sectors to a page list), `LOAD_TRACK` (`$D3A6`: track
A+1 to pages Y.., with the game's zero page `$00-$1F` swapped with `$D400`) and `LOAD_SECTION` (`$D502`, called
through `$D000`):

- A = section n: its tracks, `TRACK_LISTS` + 8n (`$DF0B`, track - 1, `$FF` ends) to `PAGE_LISTS` + 8n (`$DF6B`).
  Then the `$6300` page loaded must hold `$6303` = `SECTION_MARK[n]` (`$D55E`) and `$6304` = `SECTION_SIDE[n]`
  (`$D552`), else "PLEASE FLIP DISK AND PRESS A KEY." / "PLEASE INSERT DISK AND PSESS A KEY" (sic), and again.
- A = `$FF`: `LOAD_TRACK` X to pages Y.., no check.

| Section | Side | Tracks           | Load                                         |
| ------- | ---- | ---------------- | -------------------------------------------- |
| 0       | A    | T0E-T10          | `$0800`, `$1800`, `$6000` (16 pages each)    |
| 1-6     | B    | T01-T05, T06-T0B, T0C-T10, T11-T16, T17-T1C, T1D-T22 | `$6300-$A2FF` (+ `$B000-$BFFF`) |
| 9       | A    | T1E, T1F, T10    | `$6300-$92FF`                                |
| 11      | A    | T21, T22         | `$6300-$82FF`                                |

## Open questions

- Sections 0, 9 and 11 don't fit side A as it is: T0E-T0F are empty, and section 9 expects mark `$11` where T1E's
  `$6300` page has `$23` (section 10's, whose list is empty). Leftovers the crack doesn't use, or loaded another way?
- Who calls `LOAD_SECTION` with which n, and with `$FF`. The main code also calls `$D0D0`, `$D053`, `$D062`:
  mid-instruction in bank 2, so bank 1 code (which bank is in at each call is to check).
- `$D003` (`$D654`) and `$D006` (`$DA6D`): game code, not disk code, it seems.
- Free memory for tiny-dos: the disk layer (`$D00C-$D3E3`) and its work areas (`$D400-$D4FF`) would be free once
  it is replaced.
