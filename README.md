# UTUVO Drop

**A little cat. A place for your files.**

![UTUVO Drop cat holding a document — brand illustration](docs/assets/hero-1280.webp)

[Press kit & website](https://mickyyang-1407.github.io/utuvo-drop/) · [繁體中文](README.zh-Hant.md) · [Build instructions](docs/DEVELOPMENT.md)

A tiny macOS file shelf with a cat at the edge of your screen. Bring files to its tail,
watch it come out to collect them, then drag them to your next app.

## How it works

- **Drop in.** The cat opens its mouth, swallows file icons and grows a little rounder.
- **See what it is holding.** Its thought bubble opens automatically with file names,
  source folders and sizes. Click the cat or tail to open it again.
- **Take files out.** Drag a row, the “全部帶走” handle, or the whole cat to an app that
  accepts file drops. A successful copy handoff clears those references; cancelling keeps them.
- **Tuck it away.** Close the bubble and the cat hides again, leaving only its wagging tail.

![Actual Drop interface with synthetic sample files](docs/assets/drop-light.webp)

Actual app screenshot with sample files. Interface supports English and Traditional Chinese, with a Follow System option.

## Download

[Download UTUVO Drop 1.1.0 for Apple Silicon](https://github.com/mickyyang-1407/utuvo-drop/releases/download/v1.1.0/UTUVO-Drop-1.1.0-arm64.dmg)

Requires macOS 14 or later. The app and DMG are Developer ID-signed, notarized by Apple
and stapled. Open the DMG, drag UTUVO Drop into Applications, and launch it there.
Drag the tail or the thought bubble’s move handle to reposition the cat. Option-drag the cat also works. Right-click it or use the menu-bar cat icon to choose English, Traditional Chinese or Follow System. Position and language are remembered.

[Release notes and SHA-256 checksum](https://github.com/mickyyang-1407/utuvo-drop/releases/tag/v1.1.0)

## Build locally

macOS 14 or later, Apple Silicon, and a Swift 5.9+ toolchain with the macOS SDK.
No third-party runtime packages.

```bash
git clone https://github.com/mickyyang-1407/utuvo-drop.git
cd utuvo-drop
bash Scripts/build.sh
open "build/UTUVO Drop.app"
```

Local source builds are ad-hoc signed. The downloadable release uses Developer ID signing
and Apple notarization. See [development notes](docs/DEVELOPMENT.md) for builds and release packaging.

## Files stay yours

Drop stores **file references in memory**, not file copies. Removing an entry, clearing
the shelf or quitting Drop does not move or delete the original file. The receiving app
decides whether to copy or import a file you drag into it.

- The shelf is temporary: quitting or restarting clears its list. Position and language preferences are saved.
- No account, analytics, network access or clipboard monitoring.
- No global drag detection: files must reach the visible tail area.
- File URLs only; text snippets and web links are not accepted.
- Missing or unreadable references are marked and cannot be dragged out.
- The app is not sandboxed. macOS privacy controls and filesystem permissions still apply.
- Reduce Motion disables the tail, entrance and belly animations while preserving feedback.

## Press materials

[Download the press kit](https://mickyyang-1407.github.io/utuvo-drop/UTUVO-Drop-Press-Kit.zip)
for campaign artwork, real interface screenshots, an app icon and English / Traditional
Chinese product descriptions. The hero is an illustration; the interface screenshots use
synthetic files. Artwork notes are in [NOTICE.md](NOTICE.md).

## Contributing

Small, focused improvements are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before
opening a pull request. Report reproducible issues through [GitHub Issues](https://github.com/mickyyang-1407/utuvo-drop/issues).

## License

[MIT](LICENSE) · UTUVO contributors
