#!/bin/bash
# Regenerate the pinned UniKey engine source snapshot this ebuild ships, from
# the vendored copy in the Chrome tree. Run whenever third_party/unikey changes
# so the source shipped for LGPL compliance matches the engine linked into
# ash-chrome. Bump the ebuild PV (and rename the tarball) on a content change.
#
#   CHROME=/path/to/chromium-src/src regen-snapshot.sh [PV]
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
CHROME="${CHROME:-$HERE/../../../../../../../../chromium-src/src}"
SRC="$CHROME/third_party/unikey"
PV="${1:-0.0.1}"
OUT="$HERE/unikey-engine-src-${PV}.tar.gz"

[ -f "$SRC/ukengine.cpp" ] || { echo "no engine source at $SRC (set CHROME=)"; exit 1; }

# Ship source + license + build files; exclude nothing that bears on the linked
# engine. (poc_driver.cc is a host-only correctness driver, kept for context.)
tar czf "$OUT" -C "$SRC" \
  BUILD.gn LICENSE README.chromium charset.h charset_utf8.cpp gen_tables.py \
  inputproc.cpp inputproc.h keycons.h mactab.h mactab_stub.cpp poc_driver.cc \
  ukengine.cpp ukengine.h vnlexi.h vnlexi_tables.cpp
echo "wrote $OUT"
sha256sum "$OUT"
