# i-see-logic-pro

A light theme for Logic Pro 13. Logic Pro has only a dark interface. This project changes its colors to light colors while Logic Pro runs.

The theme is a small library that Logic Pro loads at launch. It changes nothing in the Logic Pro app or on disk. If you start Logic Pro from the Dock, you get the normal dark interface.

This project is a prototype. It is not from Apple, and Apple does not support it.

## Requirements

- Logic Pro 13.0 (build 7801). Other versions are not tested.
- A Mac with Apple silicon. The library is built for arm64 only.
- macOS 26. Other versions are not tested.
- The Xcode Command Line Tools. If you do not have them, run `xcode-select --install`.

## Install

1. Clone this repository.
2. Quit Logic Pro.
3. Build the library:

   ```sh
   theme/build.sh
   ```

The build reads the color names from your copy of Logic Pro. It writes `theme/light-theme.dylib` and signs it for your Mac only.

## Use

Quit Logic Pro, then start it with the theme:

```sh
theme/launch.sh
```

To open projects at the same time, add their paths:

```sh
theme/launch.sh ~/Music/Logic/MySong.logicx
```

The theme loads only at launch. If Logic Pro is open, `launch.sh` stops and tells you to quit Logic Pro first.

## Change the brightness

Two environment variables control the grays:

| Variable | Default | Effect |
| --- | --- | --- |
| `LP_SURFACE_MAX` | `1` | The lightest gray, from `0.65` to `1`. A lower value gives a darker interface. |
| `LP_GAMMA` | `0.75` | The curve between dark and light grays. A lower value makes the middle grays brighter. |

If the theme is too bright for you, try a lower `LP_SURFACE_MAX`:

```sh
LP_SURFACE_MAX=0.85 LP_GAMMA=0.85 theme/launch.sh
```

Values below `0.65` are not allowed, because black text then becomes hard to read.

## After a Logic Pro update

Run `theme/build.sh` again. An update can change the color names and the internal functions that the theme uses. If the build or the launch fails after an update, open an issue with your Logic Pro version.

## Remove

Delete the repository folder. Then start Logic Pro from the Dock as usual. Nothing else was installed.

## Known limits

- If `LP_SURFACE_MAX` is below `1`, the title bar and the control bar stay white.
- Some text and controls stay dark or have low contrast. Examples are the automation inspector and the Mixer `M` and `S` buttons.
- The theme depends on internal parts of Logic Pro. An update can make parts of the interface dark again.
- Logic Pro loads the library because Logic Pro 13 allows `DYLD_INSERT_LIBRARIES`. If a future version blocks it, the theme stops working.

## How it works

At launch, `theme/light-theme.m` replaces some AppKit and CoreUI methods. It maps the dark grays of Logic Pro to light grays and keeps saturated colors such as track colors. It also recolors some images and keeps glyphs white on colored buttons. `CLAUDE.md` describes the parts in more detail.
