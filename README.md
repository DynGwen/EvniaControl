# Evnia Control

**Evnia Control 1.0.27** is a lightweight macOS menu bar application for controlling a Philips Evnia display.

> **Ambiglow is not managed by this version.**

## Features

- DDC/CI brightness and hardware volume
- Persistent mute
- Displayed volume immediately changes to **0%** when Mute is enabled
- Previous audible volume is restored on Unmute
- Magic Keyboard brightness, volume and mute keys
- 5% normal step
- `Option + Shift`: 1% fine step
- Audio attenuation from `−60 dB` to `0 dB` in 3 dB steps
- Audio recovery after display sleep
- Installation in `/Applications`

## Installation

1. Extract the archive.
2. Open `Evnia-Control-1.0.27-English`.
3. Double-click `install.command`.
4. Approve the macOS administrator prompt.

Installation location:

```text
/Applications/Evnia Control.app
```

Any legacy copy in `~/Applications/Evnia Control.app` is removed after a successful installation.

If macOS blocks the script:

**System Settings → Privacy & Security**

Or from Terminal:

```bash
chmod +x install.command
./install.command
```

## Magic Keyboard

Allow Evnia Control in:

**System Settings → Privacy & Security → Accessibility**

- Brightness + / −: 5%
- Volume + / −: 5%
- Mute: mute / unmute
- `Option + Shift`: 1%

While Mute is active, Volume keys do not unmute and the displayed value remains at `0%`.

## Mute

When Mute is enabled:

1. the previous audible volume is remembered;
2. the slider immediately changes to `0%`;
3. hardware volume is forced to `0`;
4. refresh, mouse and Volume-key actions cannot unmute.

On Unmute, the previous audible volume is restored.

## Audio Attenuation

Range `−60 dB → 0 dB`, in `3 dB` steps.

## Audio After Display Sleep

Evnia Control rebuilds the Core Audio engine after wake, with bounded retries if the Evnia output has not returned yet.

## Ambiglow

No Ambiglow detection, command or option is included.

## Version

```text
Evnia Control 1.0.27
English
```
