# Development

UTUVO Drop uses Swift Package Manager and native AppKit. The current build is verified
on Apple Silicon. The deployment target is macOS 14. No third-party packages are required.

```bash
bash Scripts/build.sh
open "build/UTUVO Drop.app"
```

The script creates `build/UTUVO Drop.app`, copies the SwiftPM resource bundle, validates
bundle metadata and verifies a local ad-hoc signature. It does not notarize or install the app.

## Focused verification

```bash
swift test --filter UTUVODropAppTests
"build/UTUVO Drop.app/Contents/MacOS/UTUVODrop" --smoke-test
```

Tests use unique temporary files and pasteboards. AppKit tests and the bundle smoke mode
need a logged-in macOS desktop session. Do not substitute real user folders or change live
system settings for tests. `swift test` also includes the Foundation model tests.

## Design previews

```bash
"build/UTUVO Drop.app/Contents/MacOS/UTUVODrop" --preview
"build/UTUVO Drop.app/Contents/MacOS/UTUVODrop" --render-preview build/screenshots
```

These are opt-in development modes with synthetic files and in-memory preferences, cleaned up on normal exit.
Use `--language en` or `--language zh-Hant` before `--render-preview <directory>` to choose a preview locale.
The render command uses an owned neutral backdrop and captures the app; it requires
Screen Recording permission. Normal app use does not capture screenshots or require it.

## Code map

- `Sources/UTUVODropCore`: in-memory references, deduplication, file status and pasteboard URL reader.
- `Sources/UTUVODropApp`: native panel, drag source/destination, cat layers, tail and thought bubble.
- `Tests`: isolated model and AppKit tests.
- `Resources`: bundle metadata and icon.
- `docs`: static bilingual presskit, artwork and public documentation.

## Presskit

The static pages have no framework or network dependency. To regenerate their text and ZIP:

```bash
python3 Scripts/build-presskit.py
python3 -m http.server 8765 --bind 127.0.0.1 --directory docs
```

The PNG originals and WebP page images are checked in. Regeneration does not invoke an
image model. See `docs/media/ARTWORK.md` for the hero prompt and image provenance.

## Signed releases

The published 1.1.0 download targets Apple Silicon and macOS 14+. To create a release,
use your own Developer ID Application identity and an existing notarytool Keychain profile:

```bash
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="your-notary-profile" bash Scripts/package-release.sh
```

This uploads the app and DMG to Apple for notarization. The script enables Hardened Runtime,
adds secure timestamps, verifies Accepted responses, staples both artifacts, checks Gatekeeper,
and writes `build/distribution/<version>/SHA256SUMS.txt`. It does not publish to GitHub.
Keep credentials in Keychain; never commit signing keys or notarization credentials.
Before publishing, mount the resulting DMG, copy its app to an isolated temporary directory,
and verify its signature, ticket and `--smoke-test` there. Preserve an existing release output
before retrying. Release artifacts belong in GitHub Releases, not in Git history.
