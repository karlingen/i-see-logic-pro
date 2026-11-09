# I See Logic Pro

A light theme for Logic Pro 13. Logic Pro has only a dark interface. This project changes its colors to light colors while Logic Pro runs.

The theme is a small library that Logic Pro loads at launch. It changes nothing in the Logic Pro app or on disk. If you start Logic Pro from the Dock, you get the normal dark interface. A small launcher app starts Logic Pro with the theme and lets you set the brightness.

This project is a prototype. It is not from Apple, and Apple does not support it.

## Requirements

- Logic Pro 13.0 (build 7801). Other versions are not tested.
- A Mac with Apple silicon. The library is built for arm64 only.
- macOS 26. Other versions are not tested.
- The Xcode Command Line Tools. If you do not have them, run `xcode-select --install`.

## Install

1. Clone this repository.
2. Quit Logic Pro.
3. Build the launcher app and the theme library:

   ```sh
   app/build.sh
   ```

4. Optional: move `app/I See Logic Pro.app` to your Applications folder.

The build reads the color names from your copy of Logic Pro. It writes `theme/light-theme.dylib` and copies it into `app/I See Logic Pro.app`. It signs both for your Mac only.

## Use

1. Quit Logic Pro.
2. Open `I See Logic Pro.app`.
3. Select a preset in the sidebar, or move the sliders.
4. Click Start Logic Pro.

The app starts Logic Pro with the theme, and then it quits. The theme loads only at launch, so a change takes effect the next time that you start Logic Pro.

The preview in the app shows some Logic Pro tracks with the current values. The app paints it with the same gray rule as the theme, so it is close to what Logic Pro shows. If Logic Pro is open or if Logic Pro changed after the build, the status line at the bottom tells you what to do.

## Change the brightness

The app has these controls:

| Control | Range | Effect |
| --- | --- | --- |
| Lightness | 0.65 to 1 | The lightest gray. A lower value gives a darker interface. |
| Middle grays | 0.5 to 1.5 | The curve between dark and light grays. A higher value makes the middle grays darker. |

The presets are Light (1 and 0.75), Soft (0.85 and 0.85) and Gray (0.68 and 1). Values below 0.65 are not allowed, because black text then becomes hard to read.

## Use from a terminal

You can also start Logic Pro with the theme from a terminal:

```sh
theme/launch.sh
```

To open projects at the same time, add their paths:

```sh
theme/launch.sh ~/Music/Logic/MySong.logicx
```

If Logic Pro is open, `launch.sh` stops and tells you to quit Logic Pro first. `launch.sh` uses the settings of the app. Two environment variables override them for one launch:

```sh
LP_SURFACE_MAX=0.85 LP_GAMMA=0.85 theme/launch.sh
```

`LP_SURFACE_MAX` is the lightness, and `LP_GAMMA` is the middle grays value. To change the stored settings without the app, use `defaults`:

```sh
defaults write io.github.karlingen.i-see-logic-pro surfaceMax -float 0.85
```

## After a Logic Pro update

Run `app/build.sh` again. An update can change the color names and the internal functions that the theme uses. If you moved the app to your Applications folder, move the new app there too. If the build or the launch fails after an update, open an issue with your Logic Pro version.

## Remove

1. Delete the repository folder. If you moved the app, delete it too.
2. Delete the stored settings:

   ```sh
   defaults delete io.github.karlingen.i-see-logic-pro
   ```

3. Start Logic Pro from the Dock as usual.

## Known limits

- Some text and controls stay dark or have low contrast. Examples are the automation inspector and the active Mute button in the Mixer.
- The theme depends on internal parts of Logic Pro. An update can make parts of the interface dark again.
- Logic Pro loads the library because Logic Pro 13 allows `DYLD_INSERT_LIBRARIES`. If a future version blocks it, the theme stops working.

## How it works

At launch, `theme/light-theme.m` replaces some AppKit and CoreUI methods. It maps the dark grays of Logic Pro to light grays and keeps saturated colors such as track colors. It also recolors some images and keeps glyphs white on colored buttons. `CLAUDE.md` describes the parts in more detail.
