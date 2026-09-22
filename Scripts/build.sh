#!/bin/bash
# Local ad-hoc bundle, not a notarized distribution. Publish only after verification.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/UTUVO Drop.app"
mkdir -p "$BUILD"
# A failed build must not leave a prior successful-looking bundle at the output path.
rm -rf "$APP"
STAGE="$(mktemp -d "$BUILD/.bundle.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
printf '[1/4] swift build -c release -j 2\n'
swift build --package-path "$ROOT" -c release -j 2
BIN="$(swift build --package-path "$ROOT" -c release --show-bin-path)"
test -x "$BIN/UTUVODrop"
DEST="$STAGE/UTUVO Drop.app"
mkdir -p "$DEST/Contents/MacOS" "$DEST/Contents/Resources"
printf '[2/4] assemble and validate\n'
cp "$BIN/UTUVODrop" "$DEST/Contents/MacOS/UTUVODrop"
cp "$ROOT/Resources/AppIcon.icns" "$DEST/Contents/Resources/AppIcon.icns"
cp -R "$BIN/UTUVODrop_UTUVODropApp.bundle" "$DEST/Contents/Resources/"
cp "$ROOT/Resources/Info.plist" "$DEST/Contents/Info.plist"
printf 'APPL????' > "$DEST/Contents/PkgInfo"
plutil -lint "$DEST/Contents/Info.plist"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$DEST/Contents/Info.plist")" = UTUVODrop
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DEST/Contents/Info.plist")" = com.utuvo.drop
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundlePackageType' "$DEST/Contents/Info.plist")" = APPL
file "$DEST/Contents/MacOS/UTUVODrop"
/usr/bin/otool -hv "$DEST/Contents/MacOS/UTUVODrop"
printf '[3/4] ad-hoc sign complete bundle and verify\n'
/usr/bin/codesign --force --sign - "$DEST"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$DEST"
printf '[4/4] publish verified bundle\n'
mv "$DEST" "$APP"
printf 'OK: %s\n' "$APP"
