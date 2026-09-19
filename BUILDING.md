# Building Ultimate Soccer Manager

This project builds a native macOS application using SwiftUI and SceneKit. It
does not use Wine, emulation, a web view, or downloaded Swift packages.

## Requirements

- macOS 14 or newer
- Apple Command Line Tools or Xcode
- Swift 5.9 or newer
- Python 3 (needed by the optional asset-import tools, not by the normal build)

The checked-in `Sources/USMApp/Resources` directory already contains the
runtime database, artwork, music, sound effects, and commentary. The excluded
legacy source dumps are not needed to build or run the game.

## Build from a fresh clone

```sh
git clone https://github.com/AlisterRWood/USM98-99-Remake.git
cd USM98-99-Remake
swift run -c release USMVerify
./tools/build-app.sh
open "dist/Ultimate Soccer Manager.app"
```

The verifier is the automated build gate and should report 43 scenarios with
0 failures. The build script creates an ad-hoc signed application at
`dist/Ultimate Soccer Manager.app`. `dist/` is generated output and is ignored
by Git.

## Development build

For a faster compile while editing core logic:

```sh
swift build
swift run USMVerify
```

The app itself can be run from SwiftPM with:

```sh
swift run USM98
```

For a clean rebuild:

```sh
swift package clean
./tools/build-app.sh
```

## Optional asset import

`tools/extract_assets.py` is for maintainers who have separately obtained and
keep the original source data locally. It refreshes bundled data and assets;
it is not part of the normal clone/build workflow, and the original source
folders are intentionally ignored by Git.

## Common issues

- `swift: command not found`: install Apple Command Line Tools with
  `xcode-select --install`, or install Xcode and select it with
  `sudo xcode-select --switch /Applications/Xcode.app`.
- Framework search-path warnings mentioning Command Line Tools can appear on
  some Xcode/Command Line Tools installations; they are harmless if the build
  completes.
- macOS may show a first-launch security prompt because the app is ad-hoc
  signed rather than notarized. Open it from Finder or approve it in System
  Settings if required.
- If an old generated bundle is behaving strangely, run
  `swift package clean` and rebuild. Do not delete the ignored legacy source
  folders; they are unrelated to the runtime bundle.

## Save data

The game stores native JSON saves under:

```text
~/Library/Application Support/USM98Native/career.json
```

The application does not read original Windows save files.
