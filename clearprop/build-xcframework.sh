#!/usr/bin/env bash
# Build MapLibre.dynamic.xcframework.zip from a patched checkout, with the
# same Bazel command as upstream's ios-release.yml, and print its checksum.
#   clearprop/build-xcframework.sh ~/src/maplibre-native [out dir]
set -euo pipefail
SRC=${1:?usage: build-xcframework.sh <maplibre-native dir> [out dir]}
OUT=${2:-$PWD}
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
MIN_FREE=${MIN_FREE_MEMORY_PERCENT:-30}

if command -v memory_pressure >/dev/null; then
  free=$(memory_pressure | awk -F': ' '/free percentage/ {gsub("%","",$2); print $2}')
  if [ "${free:-0}" -lt "$MIN_FREE" ]; then
    echo "Only ${free}% memory free (need ${MIN_FREE}%). Close apps or set MIN_FREE_MEMORY_PERCENT." >&2
    exit 1
  fi
fi

cd "$SRC"
bazel build --compilation_mode=opt --features=dead_strip,thin_lto \
  --objc_enable_binary_stripping --apple_generate_dsym --output_groups=+dsyms \
  --//:renderer=metal //platform/ios:MapLibre.dynamic \
  --embed_label=maplibre_ios_"$(cat platform/ios/VERSION)"
built="$(bazel info execution_root)/$(bazel cquery --output=files --compilation_mode=opt --//:renderer=metal //platform/ios:MapLibre.dynamic 2>/dev/null)"
cp "$built" "$OUT/MapLibre.dynamic.xcframework.zip"
chmod +w "$OUT/MapLibre.dynamic.xcframework.zip"
zip -q "$OUT/MapLibre.dynamic.xcframework.zip" LICENSE.md
# The combined patch (upstream tag to HEAD) is attached to the release.
branch=$(git rev-parse --abbrev-ref HEAD)
tag=${branch#clearprop/}
if [ "$tag" != "$branch" ]; then
  git diff "$tag" HEAD > "$OUT/maplibre-$tag-clearprop.patch"
  echo "Wrote $OUT/maplibre-$tag-clearprop.patch"
fi
echo "Built $OUT/MapLibre.dynamic.xcframework.zip"
echo "checksum: $(shasum -a 256 "$OUT/MapLibre.dynamic.xcframework.zip" | cut -d' ' -f1)"
