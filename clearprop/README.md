# ClearProp MapLibre iOS patches

This branch (`clearprop`) publishes MapLibre Native iOS builds with ClearProp's
engine fixes. Each release is upstream `ios-vX.Y.Z` plus the patches in
`patches/`, tagged `X.Y.Z-clearprop.N`. The ClearProp app pins that tag in
`mobile/app.config.ts` (`spmSpec`), and a test there fails if the pin stops
pointing at a `-clearprop.` release of this fork.

Keep every engine change in `patches/`. A build made any other way loses the
fix on the next upgrade.

## Patches

| Patch | Why | Upstream |
| ----- | --- | -------- |
| `0001-hillshade-remove-unused-render-targets` | Hillshade render targets of tiles that left the render set kept their offscreen passes running every frame. | Port of maplibre-native #4754. Drop when the upstream tag includes it. |
| `0002-metal-offscreen-no-wait` | `OffscreenTexture::swap()` waited for the GPU once per hillshade tile, stalling the render thread while panning or zooming terrain. Waits only in `readStillImage()` now. | maplibre-native #4684 |
| `0003-xcode-27-sdk-build-fixes` | Lets the tag build with the Xcode 27 SDK (iOS 15.1 minimum, a removed header, `std::nullopt`, an enum cast). No behaviour change. | Drop once upstream builds with Xcode 27. |

Releases: `6.25.0-clearprop.1` = `ios-v6.25.0` + 0001-0003 (the release's
attached `.patch` is the same change as the series, as one diff).

Not here on purpose: the iOS tile download concurrency fix (20 connections per
host instead of 8, matching MapLibre Android) uses MapLibre's public
`MLNNetworkConfiguration` API from the app (`withIosMapTileConcurrency` config
plugin), so it needs no engine patch.

## Upgrading to a new MapLibre iOS version

Needs Xcode, Bazelisk (`brew install bazelisk`), `gh` signed in as an account
that can push here, and about 30% free memory for the build.

```sh
git switch clearprop
# 1. Apply the series onto the new upstream tag (clones it if needed).
clearprop/apply-patches.sh ios-v6.26.0 ~/src/maplibre-native
#    On a conflict: fix the files, `git am --continue`, then write the
#    updated series back and commit it here:
clearprop/export-patches.sh ios-v6.26.0 ~/src/maplibre-native
# 2. Build the xcframework (upstream's release command) and the combined patch.
clearprop/build-xcframework.sh ~/src/maplibre-native out
# 3. Point Package.swift at the release, tag, push and publish it.
clearprop/release.sh 6.26.0-clearprop.1 out/MapLibre.dynamic.xcframework.zip \
  out/maplibre-ios-v6.26.0-clearprop.patch
```

Then in the ClearProp repo bump `version` in `spmSpec` (`mobile/app.config.ts`)
to the new tag and match MapLibre React Native's engine version
(`$MLRN_NATIVE_VERSION` in its podspec). Make a new native build; an engine
change cannot ship as an OTA. A patch fix without an upstream change is
`X.Y.Z-clearprop.N+1` from the same tag.

`main` follows upstream's distribution repo and its `release.yml`; leave it
alone. Only the `clearprop` branch and its tags are ours.
