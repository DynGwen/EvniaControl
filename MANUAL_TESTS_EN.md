# Evnia Control 1.0.37 — Manual checks (English edition)

The checkboxes are **tests to perform on a Mac**, not completed test results.

## Installation and language

- [ ] Apple Silicon Mac on macOS 27+ with macOS 27+ SDK.
- [ ] `verify.command` compiles and passes all 14 keyboard routing checks.
- [ ] Installed version 1.0.37 in `/Applications/Evnia Control.app`.
- [ ] Main menu, feedback popups, options, messages and VoiceOver labels in English, including when macOS is in French.
- [ ] Switching from the French edition preserves preferences.

## Slider and percentage appearance

- [ ] **Solid white thumbs** in light mode, with no translucent glass center.
- [ ] **Solid white thumbs** in dark mode, matching light mode.
- [ ] Brightness and volume percentages readable with primary text contrast in the main menu.
- [ ] Percentages equally readable in keyboard feedback popups.
- [ ] Opaque audio attenuation thumb, while window Liquid Glass is maintained.
- [ ] Drag controls work in light/dark modes and with Reduce Transparency enabled.

## Behavior

- [ ] First icon click opens main panel; second click closes it while app runs.
- [ ] Outside click, Escape or switching apps dismiss the panel.
- [ ] Options… closes the panel and opens settings.
- [ ] Brightness sun keys: 5-point steps (without Fn where emitted by keyboard).
- [ ] Volume: 5% steps, Option+Shift: 1%, mute/unmute.
- [ ] Feedback popups auto-dismiss after 2 seconds, pausing while hovering or dragging.
- [ ] Reconnect, wake, 0–100 boundaries and DDC refresh work correctly.
- [ ] Audio attenuation −60 to 0 dB, 21 graduations, wake recovery.

AppKit, Carbon, DDC/CI and audio behavior need real Mac and monitor testing.
