#!/bin/bash
# Build a Developer ID-signed, notarized app and DMG. Credentials stay in Keychain.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${SIGNING_IDENTITY:?Set SIGNING_IDENTITY to a Developer ID Application identity}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to an existing notarytool Keychain profile}"
[[ "$(uname -m)" == arm64 ]] || { echo 'This release targets Apple Silicon.' >&2; exit 1; }
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Resources/Info.plist")
OUTPUT="$ROOT/build/distribution/$VERSION"
STEM="UTUVO-Drop-$VERSION-arm64"
[[ ! -e "$OUTPUT/$STEM.dmg" ]] || { echo 'Release DMG already exists; choose a new version or preserve the existing artifacts first.' >&2; exit 1; }
mkdir -p "$OUTPUT"
WORK=$(mktemp -d "$ROOT/build/.release.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
bash "$ROOT/Scripts/build.sh"
APP="$OUTPUT/UTUVO Drop.app"
[[ ! -e "$APP" ]] || { echo 'A release app already exists; preserve it before retrying.' >&2; exit 1; }
ditto "$ROOT/build/UTUVO Drop.app" "$APP"
lipo -verify_arch arm64 "$APP/Contents/MacOS/UTUVODrop"
codesign --force --sign "$SIGNING_IDENTITY" --options runtime --timestamp "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
notarize() {
    xcrun notarytool submit "$1" --keychain-profile "$NOTARY_PROFILE" --wait --output-format json > "$2"
    python3 - "$2" <<'PY'
import json, sys
result = json.load(open(sys.argv[1]))
print('Notarization:', result.get('id'), result.get('status'))
if result.get('status') != 'Accepted':
    raise SystemExit('Notarization was not accepted; inspect the saved submission result before distribution.')
PY
}
ditto -c -k --sequesterRsrc --keepParent "$APP" "$WORK/app.zip"
notarize "$WORK/app.zip" "$OUTPUT/app-notarization.json"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose=2 "$APP"
mkdir "$WORK/content"
ditto "$APP" "$WORK/content/UTUVO Drop.app"
ln -s /Applications "$WORK/content/Applications"
cat > "$WORK/content/Install.txt" <<'TXT'
UTUVO Drop  •  macOS 14+ / Apple Silicon

Drag UTUVO Drop into Applications, then open it from Applications.
A little tail appears at the edge of your screen. Drop files onto it to begin.
Use the cat icon in the menu bar to move the shelf edge or quit.
The temporary file list is cleared when the app quits; your original files stay in place.

把 UTUVO Drop 拖進 Applications，再從「應用程式」開啟。
螢幕邊緣會出現尾巴，把檔案拖過去就能開始。
點選選單列的貓咪圖示，可以換邊或結束 App。
離開 App 會清空暫放清單，原始檔案不受影響。
TXT
hdiutil create -quiet -fs HFS+ -volname 'UTUVO Drop' -srcfolder "$WORK/content" -format UDZO -imagekey zlib-level=9 "$OUTPUT/$STEM.dmg"
codesign --sign "$SIGNING_IDENTITY" --timestamp "$OUTPUT/$STEM.dmg"
codesign --verify --strict --verbose=2 "$OUTPUT/$STEM.dmg"
notarize "$OUTPUT/$STEM.dmg" "$OUTPUT/dmg-notarization.json"
xcrun stapler staple "$OUTPUT/$STEM.dmg"
xcrun stapler validate "$OUTPUT/$STEM.dmg"
spctl --assess --type open --context context:primary-signature --verbose=2 "$OUTPUT/$STEM.dmg"
(cd "$OUTPUT" && shasum -a 256 "$STEM.dmg" > SHA256SUMS.txt)
printf 'Verified release: %s\n' "$OUTPUT/$STEM.dmg"
