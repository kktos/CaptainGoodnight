# captain-goodnight

Captain Goodnight and the Islands of Fear (Broderbund, 1985), rehosted: both sides of the disk on one 800K ProDOS
`.po`, booted by tiny-dos (from [conan](../conan)) from a SmartPort / block device in any slot, instead of the
original's own track readers driving a Disk II in slot 6. No disk to flip. Needs a 128K Apple //e (or //c, IIgs):
tiny-dos lives in the aux language card.

The game is the SAN Inc crack's code and data, untouched: only its disk code is replaced.

The full notes: [docs/CAPTAIN_GOODNIGHT_RE.md](docs/CAPTAIN_GOODNIGHT_RE.md).

## Setup

```sh
B=https://mirrors.apple2.org.za/ftp.apple.asimov.net/images/games/action/captain_goodnight
curl -o assets/CAPTAIN_GOODNIGHT_A.dsk "$B/captain%20goodnight%20a%20%28san%20inc%20crack%29.dsk"   # not in the repo
curl -o assets/CAPTAIN_GOODNIGHT_B.dsk "$B/captain%20goodnight%20b%20%28san%20inc%20crack%29.dsk"
# optional, to compare: the ACE crack
curl --create-dirs -o assets/ace/ACE_A.dsk "$B/Captain%20Goodnight%20%28Cracked%20by%20ACE%20with%20codes%29%20-%20Side%20A.DSK"
curl --create-dirs -o assets/ace/ACE_B.dsk "$B/Captain%20Goodnight%20%28Cracked%20by%20ACE%20with%20codes%29%20-%20Side%20B.DSK"
./build.sh                      # -> mem/ snapshots, out/ listings, notes/, bin/ (tools/extract.py),
                                #    dist/captain.po (checked by tools/check.py), out/loadtest/
```

The build alone: `python3 tools/extract.py && tsasm captain-conf.yaml && python3 tools/check.py`.

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

The game runs with LC bank 1 switched in (the CAPTAIN module: `WAITING` `$D000`, `DRAWGOOD` `$D023`, `CERASE`
`$D19C`, `INITCAPT` `$D32E`). Three trampolines switch bank 2 in and bank 1 back: `JMPDISK` `$1D17` (`LOAD_SECTION`
A, then `JMP $6300`), `JMPTIME` `$1D2B` (`$D003`, then `RTS`) and `JMPGOVER` `$1D3B` (`$D006`, the game over, then
`JMP $6300`); names from the developers' equates left on side A (T14 S8-SC). The disk layer is a read-only RWTS (`$D00C` data field, `$D0E4`
seek, `$D121` address field, `$D300` a track's sectors to a page list), `LOAD_TRACK` (`$D3A6`: track A+1 to pages
Y.., with the game's zero page `$00-$1F` swapped with `$D400`) and `LOAD_SECTION` (`$D502`, through `$D000`):

- A = section n: its tracks, `TRACK_LISTS` + 8n (`$DF0B`, track - 1, `$FF` ends) to `PAGE_LISTS` + 8n (`$DF6B`),
  from side `SECTION_SIDE[n]` (`$D552`). The `$6300` page loaded must then hold `$6303` = `SECTION_MARK[n]`
  (`$D55E`) and `$6304` = the side, else "PLEASE FLIP DISK AND PRESS A KEY." / "PLEASE INSERT DISK AND PSESS A KEY"
  (sic), and it loads again.
- A = `$FF`: `LOAD_TRACK` X to pages Y.., from the side in the drive, no check.

[tools/extract.py](tools/extract.py) does all of these loads, with the game's checks, and writes the boot images and
every track read to `bin/`. It also fails on any call into the loaders that it doesn't know about.

| Load                    | Who                                                    | Side | Tracks                              | To                         |
| ----------------------- | ------------------------------------------------------ | ---- | ----------------------------------- | -------------------------- |
| intro                   | its script at `$631A` (opcode 0: X, Y), `$63F2`        | A    | T11-T1D                             | `$7000-$BFFF`, a track at a time |
| section 1               | the intro, on a key (`$699D`)                          | B    | T01-T05                             | `$6300-$B2FF`              |
| sections 2-6            | the previous section at its end; 2 also from game over (bank 2 `$DC90`) | B | T06-T0B, T0C-T10, T11-T16, T17-T1C, T1D-T22 | `$6300-$B2FF` + `$B000-$BFFF` |
| section 9               | section 6's end (`$B8D1`, `$B8DA`)                     | A    | T1E, T1F, T10                       | `$6300-$92FF`              |
| section 11              | section 6's end (`$B8EC`), section 9                   | A    | T21, T22                            | `$6300-$82FF`              |
| `LOAD_TRACK`            | section 11 (`$7455`)                                   | A    | T20                                 | `$B000-$BFFF`              |
| `LOAD_TRACK`            | the game over, `GOVER` (`$D006`, bank 2 `$DA71`, `$DC75`), until `$B802` = `$9A`, then `JMP $B800` | B | T22 | `$B000-$BFFF` |

Section 6's end picks the next section from the outcome in `$80` (and `$81`): 8 (`$80` = 1), 10 (`$80` = 0, `$81` =
0), 11 (`$80` = 4, or 0 with `$81` <> 0), 9 otherwise.

Leftovers: section 0 (T0E-T10 to `$0800`/`$1800`/`$6000`, the original's main code load: empty on this crack, which
reads those pages from T05-T07 at boot, and nothing calls it); sections 7, 8 and 10 have no tracks; side A T08 S0 -
T0B S7 is a copy of bank 2 `$D800-$DFFF`, `$0800-$27FF` and `$6000-$6FFF`, which nothing reads. The intro's tracks
hold some junk that looks like code (side A T11 SE).

The ACE crack (also on asimov) has the same section tables. It packs side A T00-T0F differently, and patches out
section 11's `LOAD_TRACK T20`, whose sectors S0, S5, S6 and SF the SAN crack fills: probably the original's
protection check at the end of the game.

## The .po

| File      | Load                                                    | Blocks           |
| --------- | ------------------------------------------------------- | ---------------- |
| `CAPTAIN` | `$7000`: `Init`, what the SAN loader did; then `AUX_LOADER` | 2 + 1        |
| `GAME`    | `$0300` (the traps), `$0800-$27FF`, `$6000-$6FFF`       | 1 + 16 + 8       |
| `LC`      | at `$8000-$BFFF`, copied to LC bank 1 `$D000`, bank 2 `$D000`, `$E000-$FFFF` | 32 |
| `INTRO`   | side A T11-T1D, a track at a time                       | 13 x 8           |
| `PART1`-`PART6` | sections 1-6: side B T01-T05, T06-T0B, T0C-T10, T11-T16, T17-T1C, T1D-T22 | 5-6 x 8 |
| `END9`    | section 9: side A T1E, T1F, T10                          | 3 x 8            |
| `END11`   | section 11: side A T21, T22                              | 2 x 8            |
| `T20`     | section 11's `LOAD_TRACK`: side A T20                    | 8                |

Each segment of a file starts on a block, so a track is 8 blocks at 8 x its index in its file
([src/segments.asm](src/segments.asm), where each track's segment is at the address it loads to).

- Boot: the bootloader (blocks 0-1) moves tiny-dos into the **aux** language card, bank 2 (`$D000`, its buffer at
  `$DE00`), and loads `CAPTAIN` with it. tiny-dos runs with ALTZP on: its code, buffer, zero page and stack are aux
  memory, which the game never uses; what it loads lands in main memory (`$0200-$BFFF` stays main). Main code calls
  it with `STA SETALTZP` / `JSR` / `STA SETSTDZP` from main RAM.
- `Init` ([src/modules/captain/init.asm](src/modules/captain/init.asm)): boot0's and the loader's screen (cleared
  hires pages, `AA`/`D5` stripes on page 2), loads `GAME` and `LC` (`LC` goes through `$8000`: from the aux
  language card, tiny-dos can't write the main one), copies `AUX_LOADER` to the aux language card, sets `$BFFF`,
  `REBOOT`'s slot and the trap vectors as the loader did, and jumps to `$6300`.
- `LOAD_TRACK` (`$D3A6`, [src/modules/game/loadtrack.asm](src/modules/game/loadtrack.asm)): takes the side of the
  last section asked for, `SECTION_SIDE[SECTION]`, the disk the original would have in the drive, then switches to
  the aux language card with `STA SETALTZP` at `AUX_SWITCH` (`$D3B0`). The next instruction is the aux one at
  `$D3B3`: `AuxLoadTrack` ([src/modules/captain/auxloader.asm](src/modules/captain/auxloader.asm)) finds the
  track's file and index in `TrackMap`, loads its 8 blocks with tiny-dos's `LoadFromFileAt`, and comes back through
  the aux `STA SETSTDZP` at `$D3B0`, to main's `$D3B3`: `PLP`, `RTS`. `LOAD_SECTION`, its checks and its prompts are
  untouched. `$D00C-$D3A5` (the RWTS, `READ_TRACK`, `READ_TRACK_AT`) is free.
- Checked: [tools/check.py](tools/check.py) reads the built `.po` as tiny-dos does and finds every track as
  `AuxLoadTrack` does, from the built `TrackMap`; [tools/loadtest.py](tools/loadtest.py) and
  [test/loadtest.asm](test/loadtest.asm) call every load in vm6502 (sections 1-6, 9, 11, the 13 intro tracks, T20,
  the game over's T22) and compare their checksums: all as extracted. It boots to the intro, and a key starts
  section 1.
- Not reproduced: the loader's head position in `$D40E` (nothing reads it now), its zero page and stack; the ROM
  copied to the language card (`ROM_TO_LC`), which T02-T03 overwrite anyway; `Init` and `AUX_LOADER`'s copy stay at
  `$7000-$75FF` until the intro's first track. tiny-dos's `dbgAddMemRegion` hypercall isn't called: from the aux
  language card vm6502 stops on its `BRK` (vm6502 `TODO.md`, 2026-11-15).
- The intro still says "TURN DISK OVER AND PRESS ANY KEY." before section 1 (`$6984`): the game's own prompt.

## Open questions

- Sections 8 and 10 load nothing, so `LOAD_SECTION` checks the marks of the `$6300` page that is already there,
  section 6's (side B): it asks to flip the disk forever (checked in vm6502: section 6, then 8). The game's code, not
  the crack's or the rehost's. When does section 6 end with `$80` = 1, or `$80` = 0 and `$81` = 0?
- `TIME` (`$D003` -> `$D654`) and `GOVER` with A = 0 (`$DA6D`): what they draw. `GOVER`'s `$DC8E` reloads section 2:
  play again?
- Played only to section 1's start: the rest is checked by the load test, not by playing.
