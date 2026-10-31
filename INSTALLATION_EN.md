# Evnia Control 1.0.35 — English installation

This archive contains source code and an installer that builds the application
on your Mac. It does not contain a precompiled macOS application.

Requirements: Apple Silicon Mac, macOS 27 or later, Xcode or Command Line Tools
with the macOS 27 SDK or later, and Internet access for CoreAudioTapKit and
m1ddc. These requirements are inherited from the supplied project.

1. Extract the archive into a new writable folder.
2. Double-click `install.command`. If needed, open Terminal in that folder and run:

   ```sh
   chmod +x install.command
   ./install.command
   ```

3. Wait for the build and the 14 keyboard routing checks.
4. Approve installation in Applications when macOS asks.
5. Click the display icon in the menu bar to open the controls. Click the same
   icon again to close the panel.

Closing the panel keeps the application running. Use **Quit** to exit.
Clicking outside, pressing Escape, or activating another application also
closes the panel. **Options…** closes it and opens the settings window.

The installer replaces `/Applications/Evnia Control.app` after preparing the
new version. Both editions share the same identifier and preferences:
installing the other edition changes the language while retaining saved
brightness, volume, mute and attenuation. Only one edition is installed at a time.

Keep the app allowed in System Settings > Privacy & Security > Accessibility
for brightness and volume keys. Audio attenuation may require System Audio
Recording permission. Messages emitted directly by macOS or dependencies
follow their own language settings.

`verify.command` runs source checks, a native build, and the 14 keyboard routing
checks. See `MANUAL_TESTS_EN.md` for menu-bar and hardware checks. This update
was prepared on Linux; compilation and AppKit interactions still need to be
validated on the target Mac.
