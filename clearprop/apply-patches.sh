#!/usr/bin/env bash
# Apply the ClearProp patch series onto an upstream MapLibre Native tag.
#   clearprop/apply-patches.sh ios-v6.25.0 ~/src/maplibre-native
# Clones the tag into the directory if it does not exist, makes a branch
# clearprop/<tag> and runs `git am --3way` on every patch in order. On a
# conflict, fix it in the checkout, `git am --continue`, then run
# export-patches.sh to write the updated series back here.
set -euo pipefail
TAG=${1:?usage: apply-patches.sh <upstream ios-vX.Y.Z tag> <maplibre-native dir>}
SRC=${2:?usage: apply-patches.sh <upstream ios-vX.Y.Z tag> <maplibre-native dir>}
HERE=$(cd "$(dirname "$0")" && pwd)

if [ ! -d "$SRC/.git" ]; then
  git clone --branch "$TAG" --recurse-submodules --shallow-submodules \
    https://github.com/maplibre/maplibre-native.git "$SRC"
fi
cd "$SRC"
git fetch --tags origin "refs/tags/$TAG:refs/tags/$TAG" 2>/dev/null || true
git checkout -B "clearprop/$TAG" "$TAG"
git submodule update --init --recursive
git -c user.name="${GIT_AUTHOR_NAME:-ClearProp}" \
    -c user.email="${GIT_AUTHOR_EMAIL:-clearprop@users.noreply.github.com}" \
    am --3way --keep-non-patch "$HERE"/patches/*.patch
echo "Applied $(ls "$HERE"/patches/*.patch | wc -l | tr -d ' ') patches onto $TAG in $SRC (branch clearprop/$TAG)."
