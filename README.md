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
# optional, to compare: the ACE crack
curl --create-dirs -o assets/ace/ACE_A.dsk "$B/Captain%20Goodnight%20%28Cracked%20by%20ACE%20with%20codes%29%20-%20Side%20A.DSK"
curl --create-dirs -o assets/ace/ACE_B.dsk "$B/Captain%20Goodnight%20%28Cracked%20by%20ACE%20with%20codes%29%20-%20Side%20B.DSK"
./build.sh                      # -> mem/ snapshots, out/ listings, notes/, bin/ (tools/extract.py)
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

The game runs with LC bank 1 switched in. Three trampolines switch bank 2 in for the disk layer
([meta/lc2.meta](meta/lc2.meta)) and bank 1 back: `$1D17` (`LOAD_SECTION` A, then `JMP $6300`), `$1D2B` (`$D003`,
then `RTS`) and `$1D3B` (`$D006`, then `JMP $6300`). The disk layer is a read-only RWTS (`$D00C` data field, `$D0E4`
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
| `LOAD_TRACK`            | the endings, `$D006` (bank 2 `$DA71`, `$DC75`), until `$B802` = `$9A`, then `JMP $B800` | B | T22 | `$B000-$BFFF` |

Section 6's end picks the next section from the outcome in `$80` (and `$81`): 8, 9, 10 or 11.

Leftovers: section 0 (T0E-T10 to `$0800`/`$1800`/`$6000`, the original's main code load: empty on this crack, which
reads those pages from T05-T07 at boot, and nothing calls it); sections 7, 8 and 10 have no tracks; side A T08 S0 -
T0B S7 is a copy of bank 2 `$D800-$DFFF`, `$0800-$27FF` and `$6000-$6FFF`, which nothing reads. The intro's tracks
hold some junk that looks like code (side A T11 SE).

The ACE crack (also on asimov) has the same section tables. It packs side A T00-T0F differently, and patches out
section 11's `LOAD_TRACK T20`, whose sectors S0, S5, S6 and SF the SAN crack fills: probably the original's
protection check at the end of the game.

## Open questions

- Sections 8 and 10 load nothing, so `LOAD_SECTION` checks the marks of the `$6300` page that is already there,
  section 6's (side B): it would ask to flip the disk forever. When does section 6 end with `$80` = 1, or `$80` = 4
  and `$81` = 0? To test on the rehosted build.
- `$D003` (`$D654`) and `$D006` (`$DA6D`, A = 0): what they draw.
- Free memory for tiny-dos in bank 2, once the disk layer is replaced: `$D00C-$D3D7` and `$D3E4-$D62B` (the work
  areas `$D400-$D4FF` included), minus what `SWAP_ZP` keeps at `$D400-$D41F` if it stays. `DELAY` (`$D3D8`) and
  `FILL_MSG_ROWS` (`$D62C`) are still called by the rest of bank 2. Which bank is in at each call from the main code
  is to confirm in the emulator.
