#!/usr/bin/env bash
# Write the commits on top of the upstream tag back into clearprop/patches/.
#   clearprop/export-patches.sh ios-v6.25.0 ~/src/maplibre-native
set -euo pipefail
TAG=${1:?usage: export-patches.sh <upstream tag> <maplibre-native dir>}
SRC=${2:?usage: export-patches.sh <upstream tag> <maplibre-native dir>}
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=$(mktemp -d)
git -C "$SRC" format-patch --zero-commit --no-signature -o "$OUT" "$TAG..HEAD"
# Keep the existing descriptive file names where the patch number matches.
rm -f "$HERE"/patches/*.patch.new
for new in "$OUT"/*.patch; do
  number=$(basename "$new" | cut -c1-4)
  old=$(ls "$HERE"/patches/"$number"-*.patch 2>/dev/null | head -1 || true)
  cp "$new" "${old:-$HERE/patches/$(basename "$new")}.new"
done
rm -f "$HERE"/patches/*.patch
for f in "$HERE"/patches/*.patch.new; do mv "$f" "${f%.new}"; done
rm -rf "$OUT"
ls "$HERE"/patches
