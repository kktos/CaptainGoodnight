# Captain Goodnight (Apple II, Broderbund 1985) — rehosting notes

How the SAN Inc crack of Captain Goodnight and the Islands of Fear loads, and how this repo puts it on an 800K ProDOS
volume booted by tiny-dos. The README is the short version, this file the full picture: the method, every disk access
of the game, the rehost's design, what's still open, and how it was found.

All addresses are **run-time memory addresses** (what the 6502 sees when the code runs). Disk positions are `Ttt Ss`
(track, sector, hex, DOS 3.3 logical order as in a `.dsk`). Names in `UPPER_SNAKE` are ours; names in the developers'
case (`JMPDISK`, `ylow`, `DOTEXT`) come from their leftover source (section 10).

Contents

1. [Workspace and method](#1-workspace-and-method)
2. [Tools reference](#2-tools-reference)
3. [The disks](#3-the-disks)
4. [Boot chain (side A)](#4-boot-chain-side-a)
5. [Comparison with the ACE crack](#5-comparison-with-the-ace-crack)
6. [Memory map at game start](#6-memory-map-at-game-start)
7. [The disk layer (LC bank 2)](#7-the-disk-layer-lc-bank-2)
8. [Run-time loads](#8-run-time-loads)
9. [The rehost](#9-the-rehost)
10. [Leftover original source](#10-leftover-original-source)
11. [Open questions and caveats](#11-open-questions-and-caveats)
12. [How it was found (chronology)](#12-how-it-was-found-chronology)

---

## 1. Workspace and method

### Principle

The binary is never edited. What is learned lives in text files under git:

- **Load map** (`meta/loadmap.txt`, replayed by `tools/mem.py`): the boot's disk reads, sector by sector, into 64K
  snapshots in `mem/` (`boot0.bin`, `stage2.bin`, `loader.bin`, `page3.bin`, `lc1.bin`, `lc2.bin`, `lchi.bin`,
  `game.bin`). Code is disassembled at the address it runs at, with the data it runs with.
- **Metas** (`meta/*.meta`): what each stream is (source, org, code entry points, data typing, labels, comments).
  `boot0`, `stage2`, `loader`, `page3`, `lc2` (its disk layer).
- **Extractor** (`tools/extract.py`): every run-time load, done as the game does it, with the game's own checks, into
  `bin/`. It fails on a check the data doesn't pass, and on a call into the loaders it doesn't know.

### Round-trip check

Every meta becomes tsasm source (`out/asm/<name>/`), is assembled, and compared byte for byte with the original
(`tools/roundtrip.py`). All five pass. For the rehost, `tools/check.py` compares the built volume with `bin/`, and the
load test (`tools/loadtest.py`) compares what each load really loads in vm6502.

### Build

```sh
./build.sh      # mem/, out/ (listings, round-trips), notes/, bin/, dist/captain.po (checked), out/loadtest/
```

The disk images are not in the repo: the README has the commands that fetch them into `assets/`.

## 2. Tools reference

| Tool | Job |
| --- | --- |
| `tools/dsk.py` | `.dsk` reader: sector map, DOS 3.3 catalog, dumps, extraction (from conan-rev-eng) |
| `tools/mem.py` | replays a load map into snapshots; ops `disk`, `read`, `copy`, `fill`, `eor` (added here, for boot0's decryption), `save` |
| `tools/dis.py` | meta-driven 65C02 disassembler; `operand` now also works on zero-page operands (changed here) |
| `tools/roundtrip.py` | meta -> tsasm source -> assemble -> compare; writes tsasm 2.0.24's `listing: {path, pass2}` (changed here) |
| `tools/refs.py` | instructions whose absolute operand falls in a range |
| `tools/srcfrag.py` | leftover high-bit source text in a `.dsk` -> `notes/srcfrag_A.txt`, `_B.txt` |
| `tools/extract.py` | the boot images and the 53 tracks read at run time -> `bin/`, with the game's checks |
| `tools/check.py` | the built `.po`, read as tiny-dos reads it, against `bin/`; every track found as `AuxLoadTrack` finds it |
| `tools/loadtest.py`, `test/loadtest.asm` | the load test in vm6502: cases, harness, comparison |

The meta directives are `dis.py`'s docstring (conan-rev-eng's `docs/CONAN_RE.md` section 2 has them too). The
changes to `mem.py`, `dis.py` and `roundtrip.py` are to port back to conan-rev-eng.

## 3. The disks

`assets/CAPTAIN_GOODNIGHT_A.dsk`, `_B.dsk`: "captain goodnight a / b (san inc crack).dsk" from the asimov mirror. Neither
has a DOS: no VTOC at T11 S0 (side A has game data there, side B a `$6300` page), no catalog. Everything is read as raw
tracks.

| Side | Used | What |
| --- | --- | --- |
| A | T00 S0, S6, S7, SD, SE | boot0 (S0), the loader (logical 7, E, 6, D = physical 1-4) |
| A | T01-T07 | the boot image: LC bank 1, `$E000-$FFFF`, LC bank 2, `$0800-$27FF`, `$6000-$6FFF` |
| A | T08 S0 - T0B S7 | a copy of bank 2 `$D800-$DFFF`, `$0800-$27FF`, `$6000-$6FFF`: nothing reads it |
| A | T0C-T0F | empty |
| A | T10-T22 | the intro's pictures (T11-T1D), sections 9 (T1E, T1F, T10) and 11 (T21, T22), T20 |
| B | T00 S0 | a boot sector: "THIS SIDE DOES NOT BOOT / TURN DISK OVER AND PRESS A KEY", then reboots |
| B | T01-T22 | sections 1-6, and T22 for the game over |

vm6502 can't boot side A: stage 2 calls the Disk II PROM's ReadSector (`JSR $Cn5C`), which in slot 5 is the
SmartPort card's ROM, and the loader reads the data latch itself. vm6502's RWTS emulation only serves a DOS 3.3-style
RWTS (entry `STY $48 / STA $49`). It hangs at `$072F`, polling `$C0DC`. So the original was studied statically, and
vm6502 tested the rehost.

## 4. Boot chain (side A)

| Stage | Where | Meta | Does |
| --- | --- | --- | --- |
| boot0 | `$0800` (T00 S0) | `boot0` | clears `$2000-$5FFF`, HGR page 1 full screen, decrypts `$0850-$094F` (EOR `$A5`) into `$0060-$015F`, SP = `$FF`, `RTS` |
| stage 2 | `$0060-$010F` | `stage2` | a chain of return addresses in the stack page: `SET_PROLOGUE` `$00B4` (`$00-$03` = D4 D5 D6 D7, unused), `READ_STAGE3` `$0060` |
| | | | `READ_STAGE3`: `$0801` = `RTS` (the PROM's ReadSector ends with `JMP $0801`), `$7C` = `$Cn`, 4 x `JSR $Cn5C`: T00 physical 1-4 -> `$0400-$07FF`, then `RTS` to `$0400` (an `RTS`), to `$0401` (`JMP $0406`) |
| | `$007F-$00A8` | | a 4-and-4 reader that never runs (ReadSector's `CMP $0800` leaves C = 1): a decoy |
| loader | `$0406` | `loader` | the SAN crack's loader, below |

The loader (`LOADER` `$0406`, meta `loader`):

1. AN3 on, 40 columns, 80STORE off. `PAGE3_SRC` `$063D-$073C` -> `$0300` (meta `page3`), `SET_TRAPS` `$0363`.
2. `$BFFF` = the boot slot * 16; `REBOOT`'s `$Cn` (`$0342`).
3. `LC_TEST`: LC RAM at `$F000`, else `FATAL` 'M'.
4. `STRIPES`: `$4000-$5FFF` AA/D5, HGR page 2 shown.
5. From phase 0, `SEEK` track 1, then `READ_TRACK` (`$06CF`) for each pair of `DEST_TABLE` (`$04C3`) entries:

| `DEST_TABLE` | Track | Load |
| --- | --- | --- |
| `D1 D9` | T01 | LC bank 1 `$D000-$DFFF` (bit 0: bank 1) |
| `E0 E8`, `F0 F8` | T02, T03 | LC `$E000-$FFFF` |
| `D0 D8` | T04 | LC bank 2 `$D000-$DFFF` |
| `08 10`, `18 20` | T05, T06 | `$0800-$27FF` |
| `60 68` | T07 | `$6000-$6FFF` |

6. `CHECK` `$05E3`: XOR and sum of the 28 half tracks against `CHECKSUM` `$0404/$0405` (`$20 $2C`), else `FATAL` 'L'.
   `extract.py` does the same sum on the extracted data.
7. `SET_VECTORS` `$0366`, `$D40E` = the head position (bank 2), `JMP $6300`.

`READ_TRACK` reads a whole track in any order, logical sector s to page start+s (`LOGICAL_TO_PHYSICAL` `$07AE`, DOS 3.3's
interleave). It sets itself up on the first call: it patches the slot into its `LDA $C08C,X` / `LDY $C0EC`, builds the
denibble table at `$01EA`, and its `LDY #$40` becomes `LDY #$00` so the `BEQ` skips that set-up afterwards. Its data
field read has two passes, the second entered through the operand of a `BEQ` that is never taken (`$076B`, its `$18` a
`CLC`). `SEEK` `$0544` is DOS 3.3's SEEKABS with its ONTABLE / OFFTABLE. `$048C-$0543` is an unused 4-and-4 reader of
2-page sectors with custom marks (`$0630-$063C`): probably what was left of the original's loader. `$05D0` holds
"ROLAND WAS HERE !!!".

The `$0300` page (meta `page3`): CSW, KSW, BRK (`$03F0`) and IRQ (`$FFFE`) go to `TRAP_BRK` `$0300` ('P'), RESET
(`$03F2`, `$FFFC`) to `TRAP_RESET` `$0303` ('R'). `FATAL` `$0305` shows the letter top left, clears `$0800-$BFFF` with a
click per page, copies the ROM into the LC again, makes the power-up byte invalid and jumps to `$Cn00`: a cold reboot.

## 5. Comparison with the ACE crack

"Captain Goodnight (Cracked by ACE with codes) - Side A / B.DSK" from the same mirror (optional, `assets/ace/`):

- side B: the same, but T0F S0 and T1E S2;
- side A: T00-T0F laid out differently (T0C-T0F have data, where SAN's are empty), T10-T22 the same but T20 S0, S5, S6,
  SF (empty on ACE) and T22 S1, S2, SF;
- the same section tables (its T05 S3 and T0C S9), so the empty sections (7, 8, 10) are the game's;
- ACE's T22 S1 replaces section 11's `LOAD_TRACK T20` (`LDA #$FF / LDX #$1F / LDY #$B0 / JSR $D000`) with its own
  code, where SAN fills T20's sectors: probably the original's protection check near the end of the game.

## 6. Memory map at game start

At `JMP $6300` (LC bank 2 read/write):

| Range | What |
| --- | --- |
| `$0000-$01FF` | the loader's zero page and stack |
| `$0300-$03FF` | the traps (meta `page3`); `$0392-$03FF` the rest of the copy |
| `$0400-$07FF` | the loader, left there |
| `$0800-$27FF` | game code and data, T05-T06: `draw` `$0807`, `phase` `$17EA`, the hires row tables `yhigh` `$18EA` / `ylow` `$19AA`, `DOTEXT` `$1A6A`, `EXT` `$1AD2`, `drawC` `$1BC0`, `INITANIM` `$1CB2`, `SHOURS` `$1CDD` / `SMINUTES` `$1CDE` / `SUBTIME` `$1CDF`, the trampolines `JMPDISK` `$1D17`, `JMPTIME` `$1D2B`, `JMPGOVER` `$1D3B` |
| `$2800-$3FFF` | cleared (boot0) |
| `$4000-$5FFF` | the loader's stripes |
| `$6000-$62FF` | utilities, T07: `FLIP` `$6000`, `PREAD` `$6018`, `SUBTRACT` `$6075`, `STARINIT` `$60EA`, `STARS` `$60FD`, `RANDOM` `$61BF`, `EXEC` `$61D8`, `SCLICK` `$621C`, `WAIT` `$6225`, `SETSCRN` `$6231`, `BRIEFON` `$624C`, `TIMEINIT` `$62D9` |
| `$6300-$6FFF` | the intro (T07), replaced by each section's code |
| `$7000-$BFFF` | free: the intro's pictures, then the sections (`$6300-$B2FF` + `$B000-$BFFF`) |
| `$BFFF` | the boot slot * 16 |
| LC bank 1 | the CAPTAIN module (T01): `WAITING` `$D000`, `DRAWGOOD` `$D023`, `CERASE` `$D19C`, `INITCAPT` `$D32E` |
| LC bank 2 | the disk layer (section 7), `TIME`, `GOVER`, and the rest not read yet (T04) |
| `$E000-$FFFF` | T02-T03, not read yet; the vectors |

The game runs with LC bank 1 in. The trampolines switch bank 2 in for its entries, and bank 1 back:

| Trampoline | Calls | Then |
| --- | --- | --- |
| `JMPDISK` `$1D17` | `$D000` = `LOAD_SECTION` (A) | `JMP $6300` |
| `JMPTIME` `$1D2B` | `$D003` = `TIME` `$D654` | `RTS` |
| `JMPGOVER` `$1D3B` | `$D006` = `GOVER` `$DA6D` (A) | `JMP $6300` |

## 7. The disk layer (LC bank 2)

Meta `lc2`, `$D000-$D653`:

| Name | Address | What |
| --- | --- | --- |
| `LOAD_SECTION_V`, `TIME_V`, `GOVER_V` | `$D000`, `$D003`, `$D006` | the jump table |
| `DISK_SLOT16` | `$D009` | slot * 16, from `$BFFF` at the first `LOAD_SECTION` |
| `READ_DATA` | `$D00C` | a data field into `BUF` (`$06`): in place, ProDOS-style, 3 passes merging the 86 aux nibbles (`AUX_NIBS` `$D4AA`) |
| `SEEK` | `$D0E4` | A = track, from `CUR_PHASE` (`$0E`, saved in `$D40E`) |
| `DENIB` | `$D100` | its code doubles as the denibble table's start; the 6-and-2 merge table at `$D200` |
| `READ_ADDRESS` | `$D121` | D5 AA 96, volume / track / sector / checksum, DE AA |
| `READ_TRACK` | `$D300` | `TRACK`, a 16-page list (0: skip) -> pages by physical sector (`PHYS_PAGES` `$D480`), 255 address fields at most |
| `READ_TRACK_AT` | `$D36B` | A = first page; failed: `SIDE_MARK` (`$6304`) = `$FF` |
| `LOAD_TRACK` | `$D3A6` | A = track - 1, Y = first page; the game's zero page `$00-$1F` swapped with `ZP_SAVE` `$D400` (`SWAP_ZP` `$D3C6`) |
| `DELAY` | `$D3D8` | also used by the rest of bank 2 |
| `LOAD_SECTION` | `$D502` | below |
| `ASK_FLIP`, `ASK_INSERT` | `$D56A`, `$D5A7` | "PLEASE FLIP DISK AND PRESS A KEY." / "PLEASE INSERT DISK AND PSESS A KEY" (sic), until a key or a button, then `LOAD_SECTION` again |
| `FILL_MSG_ROWS` | `$D62C` | the message band (rows 0-6 of both pages) |
| `TRACK_LISTS`, `PAGE_LISTS` | `$DF0B`, `$DF6B` | 8 bytes a section |

It's read-only: no write path. The text is in the game's characters (`$00` A ... `$19` Z, `$27` space, `$24` '.',
`$FF` end).

`LOAD_SECTION` (A = section n):

1. `SECTION` (`$D501`) = n; for each track of `TRACK_LISTS` + 8n (track - 1, `$FF` ends), `LOAD_TRACK` to the page of
   `PAGE_LISTS` + 8n.
2. The `$6300` page now there must hold `$6304` = `SECTION_SIDE[n]` (`$D552`: 0 side A, 1 side B), else `ASK_FLIP`,
   and `$6303` = `SECTION_MARK[n]` (`$D55E`), else `ASK_INSERT`. Each asks, then loads again.

With A = `$FF`, `LOAD_TRACK` X (track - 1) to pages Y.., no check, from whatever side is in the drive.

## 8. Run-time loads

All found by searching every loaded byte for `JSR` / `JMP` to `$D000`, `$D502`, `$D3A6`, `$1D17` (and the RWTS's own
entries), each hit checked by disassembly. `extract.py` keeps that list and fails on any other.

| Load | Who | Side | Tracks | To |
| --- | --- | --- | --- | --- |
| intro | its script at `$631A`, through `$63F2` | A | T11-T1D | `$7000-$BFFF`, a track at a time |
| section 1 | the intro, on a key (`$699D`) | B | T01-T05 | `$6300-$B2FF` |
| sections 2-6 | the previous section's end; 2 also from `GOVER` (`$DC90`) | B | T06-T0B, T0C-T10, T11-T16, T17-T1C, T1D-T22 | `$6300-$B2FF` + `$B000-$BFFF` |
| section 9 | section 6's end (`$B8D1`, `$B8DA`) | A | T1E, T1F, T10 | `$6300-$92FF` |
| section 11 | section 6's end (`$B8EC`), section 9 (`$662A`) | A | T21, T22 | `$6300-$82FF` |
| `LOAD_TRACK` | section 11 (`$7455`) | A | T20 | `$B000-$BFFF` |
| `LOAD_TRACK` | `GOVER` (`$DA71`, `$DC75`), until `$B802` = `$9A` | B | T22 | `$B000-$BFFF`, then `JMP $B800` |

| Section | Side | `SECTION_MARK` | Tracks |
| --- | --- | --- | --- |
| 0 | A | `$A2` | T0E-T10 -> `$0800`, `$1800`, `$6000`: the original's main code load. Empty on this crack (T0E-T0F), which reads those pages at boot from T05-T07; nothing calls it. The boot `$6300` page carries its marks (`$A2 $00`) |
| 1-6 | B | `$B4`, `$C6`, `$D8`, `$EA`, `$FC`, `$0E` | above |
| 7, 8, 10 | B, A, A | `$59`, `$11`, `$35` | none |
| 9, 11 | A | `$23`, `$47` | above |

The intro's script (`$631A-$63A2`, run by `$63A3`): opcode 0 X Y = `LOAD_TRACK`; 1 a: `$F9` = a, `$6628`; 2: `$65EF`;
3 a: `$664F` with X = a; 4: `$667C`; 5 / 6: HGR page 1 / 2; 7 a b: `$F1` = a, `$F9` = b, `$6828` (a picture?); 8: goes on
if `$7FFF` = `$AA`, else ends the intro (`$68A4`, C = 1); anything else (`$FF`): `$67C6`, then from the start again. A key or a button: `$68A4`, the "TURN DISK OVER
AND PRESS ANY KEY." (`$6984`), section 1.

Section 6's end (side B T22 at `$B8BB`, after a key or a button), from the outcome in `$80` (and `$81`):

| `$80` | Next | `$80` set to |
| --- | --- | --- |
| 0, `$81` <> 0 | section 11 | 0 |
| 0, `$81` = 0 | section 10 | |
| 1 | section 8 | |
| 2 | section 9 | 1 |
| 4 | section 11 | 0 |
| other | section 9 | 0 |

## 9. The rehost

### The volume

800K ProDOS (`DISK_KB` in `captain-conf.yaml`), named `GOODNIGHT`, linker `link/captain.linker.asm` (conan's): a file
per module, its segments each from a block boundary.

| File | Load | Blocks |
| --- | --- | --- |
| `CAPTAIN` | `$7000`: `Init` (2 blocks), then `AUX_LOADER` (`$7400`) | 3 |
| `GAME` | `$0300`, `$0800-$27FF`, `$6000-$6FFF` | 1 + 16 + 8 |
| `LC` | at `$8000-$BFFF`: LC1, LC2 (the disk layer replaced), LCHI | 32 |
| `INTRO` | side A T11-T1D | 13 x 8 |
| `PART1`-`PART6` | sections 1-6, side B | 5-6 x 8 |
| `END9`, `END11`, `T20` | section 9, section 11, section 11's T20; side A | 3, 2, 1 x 8 |

504 blocks of 1600. `src/segments.asm` has a segment per track, at the address it loads to.

### tiny-dos in the aux language card

The game uses all of its 64K: the free space in bank 2 once the old disk layer is gone (`$D00C-$D3A5`, ~920 bytes)
holds tiny-dos (`$300`), but not its 512-byte buffer as well. The game never touches the //e's aux memory (no
`RAMRD`, `RAMWRT`, `ALTZP` or 80STORE write anywhere in the code it loads), so tiny-dos goes into the **aux language
card**, bank 2: its code at `$D000`, its buffer at `$DE00`, and with ALTZP on, its own zero page and stack. What it
loads still goes to main memory: ALTZP doesn't change `$0200-$BFFF`. The cost: a 128K machine.

tiny-dos is conan's (16-bit block numbers, paths) with Karateka's `LoadFromFileAt` (a file's blocks to a given
address); `dbgAddMemRegion`, its vm6502 hypercall, isn't called (section 11).

- **Bootloader** (`src/modules/boot/bootloader.asm`): reads block 1, switches to the aux LC (`STA SETALTZP`), copies
  tiny-dos to `$D000`, patches its SmartPort entry, sets the unit in the aux zero page, loads `CAPTAIN`, switches back
  and jumps to `$7000`.
- **`Init`** (`src/modules/captain/init.asm`): boot0's and the loader's screens; `GAME`'s 3 parts; `LC` at `$8000`, then
  copied to LC bank 1 and bank 2 (tiny-dos, in the aux LC, would write the aux one); `AUX_LOADER` to the aux LC at
  `AUX_SWITCH`, the aux NMI / RESET / IRQ vectors to an `RTI`; `$BFFF`, `REBOOT`'s slot, `SET_VECTORS`; `JMP $6300`.
  Main code calls tiny-dos from main RAM: `STA SETALTZP` / `JSR` / `STA SETSTDZP` (`LoadAt`).
- **`LOAD_TRACK`** (`src/modules/game/loadtrack.asm`, at `$D3A6`, guarded): X = `SECTION_SIDE[SECTION]`, the side of
  the last section asked for, which is the disk the original would have in the drive (the intro runs with section 0:
  side A; `GOVER` after sections 1-6: side B; T20 from section 11: side A). `PHP`, `SEI`, then `STA SETALTZP` at
  `AUX_SWITCH` (`$D3B0`): the next instruction is fetched from the aux LC, at `$D3B3`.
- **`AuxLoadTrack`** (`src/modules/captain/auxloader.asm`, aux `$D3B3`): `TrackMap` (side A T00-T22, side B T00-T22:
  file << 4 | index, `$FF` none) gives the file (`FileRecords`) and the track's index in it; `LoadFromFileAt` loads its 8
  blocks at Y's page; back through `STA SETSTDZP` at aux `AUX_SWITCH`, to main's `$D3B3`: `PLP`, `RTS`. A track no file
  has sets `SIDE_MARK` = `$FF`, as a read error did. Each side keeps its stack balanced, so SP is the same on both, and
  the game's return address stays on the main stack.

`LOAD_SECTION`, its checks and its prompts are untouched; `$D00C-$D3A5` is free.

### Checks

- `tools/check.py`: `GAME` and `LC` are the extracted images (LC2 but `$D00C-$D3C5`); every track of `bin/`, found
  through the built `TrackMap` and `FileRecords` (from `CAPTAIN` and `dist/captain.sym`), is its 4K; `TrackMap` has no
  other track. A wrong `TrackMap` entry fails it (tried).
- vm6502: it boots to the intro (credits, then pictures from `INTRO`), and a key starts section 1 from `PART1`.
- Load test (`tools/loadtest.py`, `test/loadtest.asm` at `$3F00`): from the running intro, 23 calls of `LOAD_SECTION`
  (sections 1-6, 9, 11, the 13 intro tracks, T20, `GOVER`'s T22), each followed by a 16-bit sum of what it loaded,
  against the same sums over `bin/` (overlaps replayed): all equal. Sections' mark checks passed: a failed one would
  never have returned.
- Section 6 then section 8: "PLEASE FLIP DISK AND PRESS A KEY.", forever (section 11).

### Not reproduced

The loader's `$D40E` (the head position, which nothing reads now), its zero page and stack; `ROM_TO_LC`, whose copy
T02-T03 overwrite anyway. `Init` and `AUX_LOADER`'s copy stay at `$7000-$75FF` until the intro's first track. The
intro's "TURN DISK OVER AND PRESS ANY KEY." stays: it's the game's.

## 10. Leftover original source

`tools/srcfrag.py` -> `notes/srcfrag_A.txt`, `notes/srcfrag_B.txt`: Merlin source in sectors the developers' files
left behind, 122 label names in all.

| Where | What |
| --- | --- |
| side A T14 S8-SC (an intro track, in its picture's slack) | the equates of the main code: "Equates for ANIMATION" (`draw` `$0807` ... `JMPGOVER` `$1D3B`), "Equates for UTILITIES" (`FLIP` `$6000` ... `TIMEINIT` `$62D9`), "Equates for CAPTAIN" (`WAITING` `$D000`, `DRAWGOOD` `$D023`, `CERASE` `$D19C`, `INITCAPT` `$D32E`); `MIRROR` `$0200`, `offset` `$0300` |
| side A T06 S7-SF (`$1F00-$27FF` at boot), T09 SF - T0A S7 (its copy) | shape tables (`S34 DFB 3,13` ... `S45`, `HEX` lines) |
| side A T10 S4-S5, SC-SF (section 9's track) | drawing code (`DCHAR2`, `SETADDR`, `shapeind`, `screen1`) |
| side A T01 S3 | a few bytes of a table |
| side B T00 S0 (after the boot message) | game over drawing: `GOVERF3 JSR SETADDR draw bottom frame` |
| side B T05 S8, T0A S8, T0F S0, T22 SF | fragments |

The equates gave `JMPDISK`, `JMPTIME`, `JMPGOVER`, `WAIT`, `DOTEXT`, `ylow` / `yhigh` (two of ours had guessed them as
`WAIT_FRAME`, `DRAW_TEXT`, `LINE_LO` / `LINE_HI`), and showed `$D006` is the game over. Other names in the fragments
(`CODENUM`, `CHKBAD`, `CKBAD2-4`, `GOVER`, `GOVERCLR`, `HOURS`, `SECONDS`, `SUBTIME`, `STARS`, `SHIPC`, `WORLDX`...) are
for code not read yet.

## 11. Open questions and caveats

- Sections 8 and 10 load nothing, so `LOAD_SECTION` checks the marks of the `$6300` page already there, section 6's
  (side B), and asks to flip the disk forever: in vm6502, section 6 then 8 does. It's the game's code (ACE has the same
  tables). When does section 6 end with `$80` = 1, or `$80` = 0 and `$81` = 0? What were sections 7, 8, 10 for?
- `TIME` (`$D654`) and `GOVER` with A = 0 (`$DA6D`): what they draw. `GOVER`'s `$DC8E` loads section 2 again: play
  again? Its choice is `$DA69`.
- T20 on side A: SAN fills S0, S5, S6, SF; ACE leaves them empty and patches the load out. What did the original's T20
  hold? (The protection check, probably.)
- Played only to section 1's start. The other sections are checked by the load test, not by playing; the endings
  (sections 9, 11) and the game over never ran.
- The rehost needs 128K. The bootloader's own `addMemRegion` hypercall stays (it runs from main RAM); on real hardware a
  `BRK` there would stop the boot, as in conan's and Karateka's.
- vm6502: a hypercall from the aux language card stops as a plain `BRK` (`readDebug` reads 16-bit addresses from the
  main bank). In its `TODO.md` (2026-11-15, PR #110); tiny-dos's `dbgAddMemRegion` isn't called meanwhile.
- `$E000-$FFFF`, LC bank 1, most of bank 2, the game's code: not read. This was a rehost: only the disk paths are
  documented.

## 12. How it was found (chronology)

1. **The disks**: in vm6502's library, the SAN Inc crack, side A and B, fetched into `assets/`. No VTOC, no catalog on
   either: raw tracks. Side B's boot sector only says to turn the disk over.
2. **Booting side A in vm6502** hung at `$072F` polling `$C0DC`: a nibble reader of its own, which the RWTS emulation
   can't serve (it needs a DOS 3.3-style entry). From then on, static.
3. **boot0** decrypts `$0850` into the zero page and stack page and `RTS`es: the stack page is a chain of return
   addresses. Decoding it gave `$00B4`, `$0060`, `$0400`, `$0401`; the self-modified `JSR $Cn5C` and the patched `$0801`
   showed stage 2 borrows the PROM's ReadSector, 4 sectors, physical 1-4, which are exactly the used logical sectors of
   T00.
4. **The loader** (`$0406`): `DEST_TABLE` and `READ_TRACK` gave the boot load map; its own checksum (`$20 $2C`) over the
   replayed load map confirmed it.
5. **The game's disk code**: searching the loaded image for `$C08C,X` reads and D5 AA / AD prologues led to LC bank 2,
   its jump table and `LOAD_SECTION` / `LOAD_TRACK`. A `JSR $D0D0` from main code looked like a write path, but `$D0D0`
   is mid-instruction in bank 2: the main code calls bank 1, the game's resident bank.
6. **The section tables**, decoded, with their marks checked against each section's `$6300` page. A first reading of
   `SECTION_MARK` off by one made section 9 look wrong; read again, it was right.
7. **The intro's script**: `$63F2`'s `LOAD_TRACK` sat in the boot `$6300` code, which turned out to be the intro
   interpreting `$631A`.
8. **The section chain**, from the callers of `$1D17` with their `LDA #n`: intro -> 1 -> ... -> 6 -> 8 / 9 / 10 / 11.
   Sections 8 and 10 load nothing.
9. **Side A's T08-T0B**: compared page by page with the boot image, a copy nothing reads; T0C-T0F empty, section 0's
   tracks among them: what the crack left of the original layout.
10. **The ACE crack**, compared: same tables, a different side A layout, section 11's T20 load patched out.
11. **The memory budget**: bank 2's hole fits tiny-dos but not its buffer. The user's question "why not use aux
    memory?" settled it, once a scan showed the game never touches the aux switches.
12. **The build's guards** caught the first layout: the switch to aux was at `$D3B0`, not where the aux side expected
    it; one constant, `AUX_SWITCH`, for both since.
13. **First boot**: stopped on tiny-dos's hypercall `BRK` in the aux LC: a vm6502 bug (its `TODO.md`), the call removed.
14. **Second boot**: `Init` overwrote itself. A write breakpoint on `$7000-$70FF` caught `MemCopy` copying 64K: a
    resizable segment's `.size` is 0 in tsasm (the size given, not the content's). An end label since, and `MemCopy`
    returns on 0.
15. **It boots**: intro, pictures, section 1. The load test checked every load; section 6 then 8 showed the endless
    "flip" prompt.
16. **The leftover equates** (side A T14 S8-SC), read last, gave the developers' names for the trampolines and the
    utilities, and showed `$D006` is the game over: names fixed in the metas, the tools and the README.
