#!/bin/sh
# Rebuild everything: memory snapshots, listings, tsasm sources (round-trip checked), bin/, the .po (checked),
# the load test.   TSASM="node /path/to/tsAsm/dist/tsasm" ./build.sh   (default: tsasm in PATH)
cd "$(dirname "$0")"
TSASM=${TSASM:-tsasm}
python3 tools/mem.py meta/loadmap.txt
python3 tools/extract.py > /dev/null || exit 1
mkdir -p out notes dist
for m in meta/*.meta; do
	[ -e "$m" ] || continue
	n=$(basename "$m" .meta)
	python3 tools/dis.py "$m" -o "out/$n.lst" 2>"out/$n.warn"
	python3 tools/roundtrip.py "$m" "$TSASM" || echo "   ^^^ $n does not round-trip"
done
for d in A B; do python3 tools/srcfrag.py assets/CAPTAIN_GOODNIGHT_$d.dsk > notes/srcfrag_$d.txt; done
$TSASM captain-conf.yaml > /dev/null || exit 1
python3 tools/check.py || exit 1
python3 tools/loadtest.py cases > /dev/null && (cd test && $TSASM loadtest.yaml > /dev/null) || exit 1
