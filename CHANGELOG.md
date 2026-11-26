# Changelog

This file lists the changes in each release of I See Logic Pro. The newest release is first.

## Unreleased

### Added

- You can install the app with Homebrew: `brew install --cask karlingen/tap/i-see-logic-pro`. Homebrew removes the download flag, so macOS opens the app with no warning.

### Fixed

- In Classic mode, the title bar and the control bar at the top of the window are gray, not black.
- In Classic mode, the line below the control bar and the lines between the panes are dark gray, not black.

## 1.4.0 (2026-11-25)

### Added

- A Start Logic Pro automatically checkbox in the app. If you select it, the app counts down 2 seconds each time that you open it. Then it starts Logic Pro with your last settings. Click Cancel or press Esc to stop the countdown and change the settings. If the status line shows a warning, the app does not count down.

## 1.3.0 (2026-11-24)

### Added

- A Text contrast slider in the app. A higher value makes secondary text darker, so the light theme looks less washed out on a bright screen. The default is 4.5:1, the same contrast as before. Classic mode does not use this setting.
- The `LP_CONTRAST` environment variable sets the text contrast for one launch with `theme/launch.sh`.
- A Check for Updates button in the app. It asks GitHub for the newest release. If a newer release exists, a second button opens its download page. The app never replaces itself.
- A Stock row in the app. It starts Logic Pro as Apple ships it, without the theme. The preview shows the stock grays.

### Changed

- A Logic Pro update can remove a class or a method that the theme changes. The theme then skips that change and writes its name to the system log. If the Logic Pro build is not the tested one, the theme also writes a message. Set `LP_DEBUG=1` to write a full report at each launch.

### Fixed

- The app now finds Logic Pro in the Applications folder by its identity, not by its file name. Before, a special character in the name of Logic Pro gave an error. An example of such a character is a no-break space. The error was "Logic Pro is not in the Applications folder." The theme also works on a copy with such a name. If the Applications folder holds more than one Logic Pro, the app starts the tested build, or else the newest build.

## 1.2.0 (2026-11-20)

### Added

- A Classic row in the app. It keeps Logic Pro dark with white text, and it gives the surfaces the lighter grays of Logic Pro 12. For example, the track rows, the Mixer strips and the Inspector are medium gray again, and the Tracks area stays dark. The Lightness and Middle grays sliders and the tint do not apply to Classic.
- The `LP_CLASSIC=1` environment variable starts Logic Pro in Classic mode for one launch with `theme/launch.sh`.

### Fixed

- When you rename a track, the name is readable. Before this fix, the text was black on a dark gray band. You saw it only in a selection.
- The All Filters popover in the Browser is light. Before this fix, it was dark gray, with dark tags and bright tag text.

## 1.1.1 (2026-11-15)

### Fixed

- Plug-in windows such as Mastering Assistant and Beat Breaker keep their stock colors. Before this fix, their panels were gray with faint text.
- Text has more contrast at the Soft and Gray presets. For example, the Setting buttons and the green Read label in the Mixer are darker. Some small labels in the Mixer still have low contrast at the Gray preset.

## 1.1.0 (2026-11-14)

### Added

- A tint row in the app. It has None and six light tints: Cool, Mist, Sage, Sand, Rose and Lilac. The tint gives the gray surfaces a light color, and text stays black. The preview and the preset squares show the tint.
- The `LP_TINT` environment variable sets a tint for one launch with `theme/launch.sh`.

### Fixed

- The Dark and Light labels beside the sliders looked disabled. They are now normal gray text, and the two sliders have the same length.

## 1.0.3 (2026-11-14)

### Fixed

- Plug-in displays keep their stock colors. Before this fix, the light labels, the grid and the 0 dB line in the Channel EQ display became dark. On the dark display, they were almost invisible. The bars above and below the plug-in display still follow the theme.

## 1.0.2 (2026-11-09)

### Fixed

- The marker names in the ruler are dark text. Before this fix, they were white on the light ruler.
- The center of the track header volume slider has the same light fill as its ends. Before this fix, the center was darker.
- The glass platters behind the toolbar buttons are a step lighter than the gray title bar. Before this fix, they showed as white capsules at the Soft and Gray presets.

## 1.0.1 (2026-11-09)

### Added

- An app icon.

## 1.0.0 (2026-11-09)

### Added

- The launcher app. It starts Logic Pro with the theme and has three brightness presets (Light, Soft and Gray), two sliders and a preview.
- The theme reads the color names of Logic Pro at the first launch of each Logic Pro build. A Logic Pro update does not need a new theme version for the colors.

### Fixed

- The title bars match the surface color at the darker settings.
- The Piano Roll scroll tracks match the surface color at the darker settings.
- The track rename field has a light background.
