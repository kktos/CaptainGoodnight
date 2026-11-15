# TODO

## 2026-11-15 — Section 11: the Hall of Fame is never saved (`WRITE_HOF`)

Section 11 (`END11`, side A T21-T22, [src/modules/tracks/end11.asm](src/modules/tracks/end11.asm)) is the Hall of
Fame. `LOAD_HOF` (`$744F`) loads it: `LOAD_SECTION $FF`, T20 to `$B000-$BFFF`. A name entered by the player
(`ENTER_NAME` `$63F5`, then `INSERT_NAME` `$63C2`: 20 bytes to `$B100,Y`) is written back by `JSR WRITE_HOF`
(`$632F`, `$63A7`). `$632F` also runs when `LOAD_HOF` fails (C = 1), with `FORMAT` (`$6306`) = 1, to write a new
table.

`WRITE_HOF` (`$7500`) is the SAN crack's `JMP $B500`: its writer lives in T20 S5-S6 (`$B500-$B6FF`). It pre-nibbles
`$B100` (6-and-2, into `$BB00`/`$BC00`), waits for an address field and writes a data field, with slot 6 hard-wired
(`$C0EC`). The original's own 4-and-4 reader and writer (`OLD_READ_HOF` `$7465`, `OLD_WRITE_HOF` `$7505`, `OLD_SEEK`
`$75C2`, `D5 FF DD` marks, the slot from `SLOT16`) are still there, dead.

In the rehost there's no Disk II: `$B500` polls `$C0EC` and would hang (or worse on real hardware, with a card in
slot 6). Not reached yet: nobody has played to the end, and the load test only loads T20.

Options:

- **No save**: `$7500` becomes `RTS`. A new name lasts until the reboot; the table on the `.po` stays SAN's.
- **Save to the `.po`**: a block write next to `AuxLoadTrack` ([auxloader.asm](src/modules/captain/auxloader.asm)):
  find the `T20` file's first data block (`$B000-$B1FF`, which holds `$B100`) from its index block, then a
  SmartPort / ProDOS WRITE of it. tiny-dos only reads. The buffer can stay in main memory: ALTZP doesn't switch
  `$0200-$BFFF`. Needs a writable volume in vm6502.

To check first: which sector of T20 the crack's writer targets (its address-field compare at `$B528-$B55C`), what
T20's S0 (`$B000`) and SF hold, and that `$B100` is the table the game shows (SAN's T20 S1 is all zeros).
