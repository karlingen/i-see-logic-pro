# CLAUDE.md

This file gives guidance to Claude Code (claude.ai/code) for the code in this repository.

This project adds a light theme to Logic Pro 13.0 (build 7801, `com.apple.logic10`, arm64). The theme is one library that loads at launch with `DYLD_INSERT_LIBRARIES`. It changes nothing on disk.

## Rules for a running Logic Pro

A developer can have a themed Logic Pro open while you work. Run `pgrep -x 'Logic Pro'` before any build or test.

- If Logic Pro is running, do not rebuild the library, because that session loaded it.
- If Logic Pro is running, do not start a second copy, and do not quit or attach to the running copy. Ask the developer to quit it.
- Do not open the real projects of the developer in a test. Copy a project to a temporary folder, and delete the copy after the test. The demo song `/Library/Application Support/Logic/Logic Pro X Demosongs/Manzana.logicx` is a good source.
- Start tests with `open -g`, because a test window in front can receive the keystrokes of the developer.
- If `DYLD_INSERT_LIBRARIES` names a missing file, dyld stops Logic Pro at launch.

## Commands

```sh
theme/build.sh                # Generates logic-colors.h, then builds and ad-hoc signs light-theme.dylib
theme/launch.sh [project...]  # Starts Logic Pro with the theme, and rebuilds if the source is newer
LP_GAMMA=0.75 theme/launch.sh # Tunes the gray curve. A lower value is brighter
LP_SURFACE_MAX=0.85 theme/launch.sh # Sets the lightest gray (minimum 0.65)
```

Run `theme/build.sh` again after a Logic Pro update, because the color list and the symbol names can change. Git ignores `theme/logic-colors.h` and `*.dylib`. Do not commit `logic-colors.h`, because its data comes from the Logic Pro bundle.

There is no linter and no unit test suite. Tests are real launches. `LP_OUT` and `LP_DELAY` make the library render each visible window to a PNG file and then end Logic Pro with no save prompt:

```sh
open -g -n --env DYLD_INSERT_LIBRARIES="$PWD/theme/light-theme.dylib" --env LP_OUT=<out-dir> --env LP_DELAY=40 -a '/Applications/Logic Pro.app' <copy-of-a-project>.logicx
```

If the project opens slowly, the render finds no visible window. Use an `LP_DELAY` of 55 in that case. The render omits the playhead. For a true capture, use `screencapture -x -o -l <window-number>`.

## Architecture

All theme code is in `theme/light-theme.m`. The constructor `start()` installs every hook. Logic Pro has no light theme to turn on, so the library changes colors at the points where they reach the screen. These layers work together:

- Appearance: `+[NSAppearance appearanceNamed:]` maps the dark names to light names, and `NSApp.appearance` stays `Aqua`.
- Catalog colors: `-[CUINamedColor cgColor]` is the path for both AppKit and SwiftUI. `copyMappedColor` decides the result by color name. It tries `isBrightVariant`, `fixedGray`, `isAccent`, `isWell`, `isTransportText` and the gray mapping, in that order. Saturated colors do not change. Only names in `logic-colors.h` are mapped, which are the names with one appearance.
- Gray mapping: `mapGray` returns `surfaceMax * pow(1 - white, grayGamma)`. `LP_SURFACE_MAX` and `LP_GAMMA` set the two values.
- Literal colors: if the caller is inside the Logic Pro bundle, the `NSColor` factory hooks (`WHITE_HOOK`, `RGB_HOOK`, `NAMED_HOOK`) map grays. `addImage` records those code ranges and `isLogicCaller` checks them. `DARKENED_LITERALS` lists saturated literals that must change.
- Images: `copyRecoloredImage` changes pixels by `ImageStyle`. Named assets pass through `MAAssetManager` and `assetStyle`. Track header images come from a C++ cache and have no names, so `drawStyle` identifies them by size and call stack, once per image. The results stay in associated objects.
- Nibs: `hookNibDecode` maps literal cell colors and `hookAppearanceDecode` maps a stored `DarkAqua`. Nib decoding skips the factory hooks and `+appearanceNamed:`.
- Buttons: `hookToolbarImage` and `hookButtonImage` keep glyphs white on active colored fills. In the track header, `repOnBevel` and `interposeFillColor` do this at draw time.
- Title bar: on macOS 26, system glass draws the title bar, and it is white in `Aqua`. If `surfaceMax` is below 1, `hookOrderWindow` makes each titled window's title bar transparent, so the window background shows through. Editor windows such as the Piano Roll and the Mixer use the system `windowBackgroundColor`, so the hook gives them the mapped `BackgroundViewControlbar` instead.
- System colors: the theme maps only Logic catalog colors, because system colors do not pass through `-[CUINamedColor cgColor]`. If `surfaceMax` is below 1, `hookClipBackground` replaces the system `controlBackgroundColor` of clip views with a gray at `surfaceMax`. Legacy scroller tracks show this color.
- Special cases: `interposeDrawPath` recolors region outlines. The `CTooltipView` hooks keep help tag text white. The `CLgNotesTextView` hooks make note text black.

Color data comes from `*Mapping.plist` asset sets and `.car` catalogs inside the app bundle. Read them with `plutil` and `assetutil -I`. For a color with an unknown source, interpose a CoreGraphics call (for example `CGContextDrawImage`) and log `+[NSThread callStackSymbols]`. A guess from a color name is often wrong.

## Limits of the approach

- The region outline depends on the symbols `drawRegionInArrangeViewWithFlex` and `drawRegionFrame`, and on three adjacent functions. If a Logic Pro update removes them, the outline stays black.
- The knob and volume slider styles depend on the symbols `DoTrackHeader` and `HOTSPOTauknob127Pan*::Print`, and on the symbols after them. If a Logic Pro update removes them, those images stay dark.
- Do not call `+[NSThread callStackSymbols]` or `dladdr` while Logic Pro draws. A lookup scans the Logic symbol table and stops the interface. Compare return addresses with `isCalledFrom`.
- The image match limits are tuned. `OVERLAY_ALPHA_MAX` must stay at 25 percent, because a higher value turns the volume thumb dark.
- Some text does not reach any hook. `sRGBColorWithRed:green:blue:alpha:` bypasses the factory hooks, and SwiftUI `.secondary` text needs a code patch.
- The library loads only because Logic Pro 13 has no hardened runtime. If Apple turns it on, `DYLD_INSERT_LIBRARIES` stops working.
