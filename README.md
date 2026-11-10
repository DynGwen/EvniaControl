# Evnia Control

**Brightness, volume, and audio controls for Philips Evnia monitors on Mac.**

Evnia Control is a lightweight macOS menu-bar utility for managing a compatible Philips Evnia display without navigating its physical on-screen menu. It uses DDC/CI to adjust monitor settings and provides an optional system-audio attenuation control.

## Features

- **Monitor brightness:** Adjust brightness from 0% to 100% using a slider or the brightness keys.
- **Monitor volume:** Adjust the monitor's DDC/CI volume from 0% to 100%, using a slider or the volume keys.
- **Mute and unmute:** Toggle the monitor's sound directly from the menu-bar panel or the mute key.
- **Audio attenuation:** Reduce system-audio output by **0 to −60 dB**, in 3 dB increments, from the Options window. At 0 dB, attenuation is disabled.
- **Keyboard integration:** Use brightness keys (including F1/F2 where supported) and volume/mute media keys. Hold **Shift + Option** while adjusting volume for 1% steps instead of the normal 5% steps.
- **Quick feedback:** See an on-screen control with the current percentage when brightness or volume changes. The controls use opaque white slider thumbs and easy-to-read values.
- **Menu-bar access:** Open or dismiss the control panel from the display icon in the macOS menu bar.
- **Launch at login:** Optionally start Evnia Control automatically when you sign in.
- **Display recovery:** Refreshes its connection and handles display sleep/wake events; availability of individual controls depends on DDC/CI support.

## Requirements

- An **Apple Silicon Mac** (M-series processor).
- **macOS 27 or later**.
- **Xcode or Apple Command Line Tools**, with the **macOS 27 SDK or later**.
- A compatible **Philips Evnia monitor** connected through a connection that supports **DDC/CI**. Enable DDC/CI in the monitor's own settings if that option is available.
- An **internet connection during installation**, to obtain the required open-source dependencies.

> **Important:** This distribution contains the application's **source code and build installer**, not a precompiled `.app` file. Installation compiles the application locally on your Mac.

## Installation

1. **Extract** the Evnia Control archive into a new folder where you have write access.
2. Open the extracted folder and **double-click `install.command`**.
3. Follow any macOS prompts and allow the installer to download dependencies, compile the application, and run its keyboard-routing checks.
4. Enter an administrator password if requested to install the app in `/Applications`.
5. When installation finishes, Evnia Control launches automatically. Look for the **display icon** in the menu bar.

Alternatively, install from **Terminal** in the extracted folder:

```bash
chmod +x install.command
./install.command
```

If the installer prompts you to install Apple Command Line Tools, complete that step and run `install.command` again. If the installed developer tools do not include the required macOS SDK, update Xcode or Command Line Tools first.

## How to use

1. Click the **display icon** in the menu bar to open Evnia Control.
2. Drag **Brightness** or **Volume** to adjust the monitor. The value is shown as a percentage.
3. Click **Mute** or **Unmute** to change the sound state.
4. Choose **Options…** to configure audio attenuation or **Launch Evnia Control at login**.
5. Click the menu-bar icon again, click outside the panel, or press **Esc** to close it. The application continues running in the background.
6. Choose **Quit** in the panel to exit the application.

### Audio attenuation

In **Options…**, move the **Attenuation** slider between **0 dB** (off) and **−60 dB** (maximum attenuation), in steps of 3 dB. This feature processes system audio through Core Audio; it is separate from the monitor's DDC/CI volume control. macOS may request **System Audio Recording** permission the first time attenuation is enabled.

## macOS permissions

**Accessibility** — Required for Evnia Control to intercept and handle brightness and volume media keys. If a permission message appears, use **Request Access** or open **System Settings → Privacy & Security → Accessibility**, then allow Evnia Control.

**System Audio Recording** — May be required to enable audio attenuation. Approve the macOS prompt if you want to use this feature.

The basic menu-bar sliders can still be used when keyboard access has not been granted, provided that the display supports the relevant DDC/CI commands.

## Troubleshooting

| Problem | What to check |
| --- | --- |
| No compatible display found | Confirm the monitor is connected and powered on. Check that your connection and monitor support DDC/CI, and enable it in the monitor's settings if available. |
| Brightness or volume is unavailable | Some monitors or connections do not expose every DDC/CI control. Try reconnecting the display and opening the panel again. |
| DDC/CI command fails or times out | Disconnect and reconnect the display, then try again. Check the cable, adapter, or dock for DDC/CI compatibility. |
| Keyboard controls do not respond | Enable Evnia Control in **System Settings → Privacy & Security → Accessibility**. |
| Audio attenuation does not work | Check **System Audio Recording** permission and ensure macOS has an available audio output. |
| Installation fails | Confirm that you are using Apple Silicon, macOS 27+, the macOS 27+ SDK, and a working internet connection. |

## Build verification

The source package also includes `verify.command`, which performs build and keyboard-routing checks on a compatible Mac. Hardware-dependent functions, permissions, and visual rendering should be checked on the target Mac with a supported display.

## Open-source components

Evnia Control uses [m1ddc](https://github.com/waydabber/m1ddc) for external-display DDC/CI commands and [CoreAudioTapKit](https://github.com/CJStanfield/CoreAudioTapKit) for audio attenuation. The installer downloads/builds the required components and bundles the DDC helper with the application.
