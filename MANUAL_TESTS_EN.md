# Evnia Control 1.0.35 — Mac verification

These boxes describe checks to perform; they are not completed test results.

## Installation and language

- [ ] Apple Silicon Mac with macOS and SDK 27 or later.
- [ ] `verify.command` builds Release and passes all 14 keyboard routing checks.
- [ ] `install.command` prepares the replacement before stopping the old app.
- [ ] Installed version: 1.0.35, with only one active app in Applications.
- [ ] Menu, popups, options and built-in messages are English, including on French macOS.
- [ ] Switching from the French edition retains saved preferences.

## Status icon and main panel

- [ ] On launch: icon visible, panel closed.
- [ ] With another app in front, the first single left click opens the panel.
- [ ] The second click on the same icon closes it without reopening on release.
- [ ] The third click reopens it. Repeat 20 cycles, slowly and quickly.
- [ ] A double-click performs two toggles and leaves the panel closed.
- [ ] Close by clicking another app, then immediately click the icon: the panel stays open.
- [ ] Clicking inside the panel and dragging sliders keeps it open.
- [ ] Clicking outside in Options, on the desktop, or in another app closes it.
- [ ] Escape closes it; the next icon click reopens it.
- [ ] Command-Tab closes it even when the pointer remains over the status icon.
- [ ] Options… closes the panel and opens settings; the next icon click opens the panel.
- [ ] Closing the panel keeps the app and media keys active; Quit terminates the app.
- [ ] Repeat after wake, on each display, and with a full-screen application.
- [ ] Icon clicks also work without Accessibility permission and with no DDC display connected.

## Regression checks

- [ ] Small/large sun without Fn: one −5/+5 point step; Fn+sun and F1/F2 remain available as emitted by the keyboard.
- [ ] Holding/releasing a key repeats without double steps and stops on release.
- [ ] 0/100 limits, disconnect, reconnect and wake.
- [ ] Volume: 5% steps, Option+Shift: 1%, mute and volume restoration.
- [ ] Brightness/Volume popups below the icon preserve keyboard focus; dismiss after 2 seconds, pause on hover/drag.
- [ ] Opening the main menu hides an existing popup; no popup overlaps the menu.
- [ ] No popup at startup or during automatic refresh.
- [ ] Liquid Glass, light/dark mode, Reduce Transparency, English VoiceOver labels.
- [ ] Options: launch at login, −60 to 0 dB attenuation, 21 graduations and audio recovery after wake.

Physical key reception, AppKit event ordering, Carbon registration, DDC/CI and
audio hardware require these checks on the target Mac.
