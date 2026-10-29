#!/usr/bin/env bash
# Publish a ClearProp MapLibre iOS release from the fork's clearprop branch.
#   clearprop/release.sh 6.26.0-clearprop.1 out/MapLibre.dynamic.xcframework.zip [combined.patch]
# Points Package.swift at the new release (URL and checksum), commits it,
# tags the commit with the version (SwiftPM resolves the tag), pushes, and
# creates the GitHub release with the zip and the combined patch attached.
set -euo pipefail
VERSION=${1:?usage: release.sh <X.Y.Z-clearprop.N> <xcframework zip> [patch]}
ZIP=${2:?usage: release.sh <X.Y.Z-clearprop.N> <xcframework zip> [patch]}
PATCH=${3:-}
REPO=${REPO:-vmal/maplibre-gl-native-distribution}
ROOT=$(cd "$(dirname "$0")/.." && pwd)

case "$VERSION" in
  *.*.*-clearprop.*) ;;
  *) echo "Version must look like X.Y.Z-clearprop.N" >&2; exit 1 ;;
esac
[ "$(basename "$ZIP")" = "MapLibre.dynamic.xcframework.zip" ] || {
  echo "The zip must be named MapLibre.dynamic.xcframework.zip" >&2; exit 1; }
cd "$ROOT"
[ "$(git rev-parse --abbrev-ref HEAD)" = "clearprop" ] || {
  echo "Run from the clearprop branch" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "Working tree not clean" >&2; exit 1; }
if git rev-parse -q --verify "refs/tags/$VERSION" >/dev/null; then
  echo "Tag $VERSION already exists" >&2; exit 1
fi

CHECKSUM=$(swift package compute-checksum "$ZIP" 2>/dev/null || shasum -a 256 "$ZIP" | cut -d' ' -f1)
URL="https://github.com/$REPO/releases/download/$VERSION/MapLibre.dynamic.xcframework.zip"
sed -i.bak -E \
  -e "s#url: \"[^\"]*\"#url: \"$URL\"#" \
  -e "s#checksum: \"[^\"]*\"#checksum: \"$CHECKSUM\"#" Package.swift
rm Package.swift.bak
grep -q "$CHECKSUM" Package.swift && grep -q "$VERSION" Package.swift

git commit -m "Release $VERSION" Package.swift
git tag "$VERSION"
git push origin clearprop "refs/tags/$VERSION"
assets=("$ZIP")
[ -n "$PATCH" ] && assets+=("$PATCH")
gh release create "$VERSION" -R "$REPO" --verify-tag --title "$VERSION" \
  --notes "MapLibre iOS with the ClearProp patch series (clearprop/patches at $(git rev-parse --short HEAD))." \
  "${assets[@]}"
echo "Released $VERSION. Bump spmSpec in clearprop mobile/app.config.ts to $VERSION."
