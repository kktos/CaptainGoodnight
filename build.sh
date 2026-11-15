#!/bin/sh
# Rebuild memory snapshots, listings, tsasm sources, and round-trip check them.
#   TSASM="node /path/to/tsAsm/dist/tsasm" ./build.sh   (default: tsasm in PATH)
cd "$(dirname "$0")"
python3 tools/mem.py meta/loadmap.txt
python3 tools/extract.py > /dev/null || exit 1
mkdir -p out notes
for m in meta/*.meta; do
	[ -e "$m" ] || continue
	n=$(basename "$m" .meta)
	python3 tools/dis.py "$m" -o "out/$n.lst" 2>"out/$n.warn"
	python3 tools/roundtrip.py "$m" || echo "   ^^^ $n does not round-trip"
done
for d in A B; do python3 tools/srcfrag.py assets/CAPTAIN_GOODNIGHT_$d.dsk > notes/srcfrag_$d.txt; done
