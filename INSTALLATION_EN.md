# Evnia Control 1.0.37 — English edition installation

This archive contains the **source code** and an installer that builds the app
on your Mac. No precompiled `.app` is included.

Requirements: Apple Silicon Mac, macOS 27 or later, Xcode or Command Line Tools
with macOS 27+ SDK, and Internet access for CoreAudioTapKit and m1ddc.

1. Extract the archive into a **new writable folder**.
2. Double-click `install.command`, or in Terminal run:

   ```sh
   chmod +x install.command
   ./install.command
   ```

3. Allow the build and the 14 keyboard routing checks to finish.
4. Approve installation in Applications when macOS asks.
5. Click the display icon in the menu bar to open controls. A second click on
   the icon dismisses the panel **without exiting the app**.

An outside click, Escape or switching apps also dismisses the panel.
“Options…” closes the main panel and opens settings.

The installer replaces `/Applications/Evnia Control.app`. The English and French
editions are two separate distributions, but **only one edition is installed
at a time**. Saved brightness, volume, mute and attenuation preferences carry
over when switching editions.

Keep Evnia Control enabled in System Settings > Privacy & Security >
Accessibility to use media keys. Audio attenuation may require System Audio
Recording permission.

`verify.command` checks the source, builds the Release app and runs 14 keyboard
routing tests. See `MANUAL_TESTS_EN.md` for visual, keyboard and hardware
validation. Native compilation and hardware tests must be run on the target Mac.
