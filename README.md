# Evnia Control 1.0.35 — English edition

Menu-bar brightness, volume and audio attenuation for Philips Evnia displays
on Apple Silicon, using the supplied project’s Liquid Glass interface.

## Version 1.0.35

- First single left click on the status icon opens the main panel.
- Second click on the same icon closes the panel and keeps the application running.
- Exactly one action is handled on mouse-down, with no toggle on release.
- Losing key-window status during an icon press no longer closes and reopens the panel.
- Both mouse monitors identify the icon’s screen bounds, including windowless events.
- Outside clicks dismiss immediately; Escape and application switching also dismiss the panel.
- Options… explicitly closes the main panel before showing settings.
- English interface, accessibility text, built-in messages and installer.

Saved settings and brightness/volume controls remain shared with the French
edition. Brightness uses 5-point steps; volume uses 5% steps, or 1% with
Option+Shift. Feedback popups keep their 2-second timeout and pause on
hover/drag. Audio attenuation ranges from −60 to 0 dB in 3 dB steps.

## Installation and verification

Extract and run `install.command`. Existing requirements are retained:
Apple Silicon, macOS 27+, macOS 27+ SDK and Internet. See `INSTALLATION_EN.md`.

Source code and an installer are included; no precompiled macOS application
is included. Checks performed on Linux: zsh script syntax, bundle metadata,
translation coverage, installer control flow with mocked macOS tools, and
archive integrity. Native compilation, all 14 Swift keyboard routing checks,
and AppKit/hardware behavior must still be validated on a Mac using
`verify.command` and `MANUAL_TESTS_EN.md`.
