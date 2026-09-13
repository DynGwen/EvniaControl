# Evnia Control

**Evnia Control 1.0.39** is a lightweight macOS menu bar application for controlling a Philips Evnia display.

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
2. Open `Evnia-Control-1.0.39-English`.
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


## Audio Dependency

CoreAudioTapKit is resolved with Swift Package Manager starting from:

```text
0.1.0
```

Evnia Control no longer references the removed `91538c3f...` commit.

## Interface

The design has been restored exactly to the **1.0.24** layout: same sizes, same positions, same buttons, same sliders, and the same Options window.

Current functionality is preserved: mute displays 0%, previous volume is restored on unmute, installation in `/Applications`, audio wake recovery, corrected CoreAudioTapKit dependency, 5% / 1% keyboard steps, audio attenuation, and no Ambiglow management.

## Sliders

Brightness and Volume use the same native SwiftUI `Slider` controls as
1.0.24/1.0.30.

The attenuation slider is restored to the original AppKit control with its
**21 visible tick marks**, matching the 3 dB steps from `−60 dB` to `0 dB`.

No custom AppKit tinting is used.

The layout, buttons, Options window and all current functionality remain
unchanged. Ambiglow is not managed.

## Sliders

The layout remains strictly the **1.0.24** layout.

- **Brightness** and **Volume** use the native SwiftUI `Slider` in continuous mode, with no `step` parameter. On Tahoe this avoids the discrete control appearance with a tick at every percentage point.
- Values are still rounded to **1%** in code.
- **Attenuation** keeps its original AppKit `NSSlider` with **21 visible tick marks**, from `−60 dB` to `0 dB` in 3 dB steps.

No button, position, window dimension, or audio/DDC logic was changed. Ambiglow remains absent.

## Attenuation — same design as the other sliders

The attenuation control now uses the **same continuous native SwiftUI
`Slider`** as Brightness and Volume.

It still displays **21 graduation marks** corresponding to:

`−60, −57, −54, …, −3, 0 dB`

The marks are drawn separately below the track, so they do not alter the
native Tahoe track or thumb appearance.

The value remains quantized in **3 dB** steps.

The 1.0.24 layout, buttons, Options window, and all current functionality
remain unchanged. Ambiglow is not managed.

## Tahoe Slider Thumbs

All three sliders now use the same visual control:

- thin gray track;
- blue active fill on the left;
- a **flat, horizontal, rounded white lozenge thumb**;
- identical geometry for Brightness, Volume, and Attenuation.

Brightness and Volume have no visible graduation marks.

Attenuation keeps its **21 graduation marks** and 3 dB steps.

The layout, buttons, Options window, and functional logic are unchanged.
Ambiglow remains absent.

## Slider Thumb Size

The thumb used by all three sliders has been reduced to better match the
provided macOS Tahoe reference:

- width: `20 pt` instead of `30 pt`;
- height: `16 pt` instead of `22 pt`;
- lighter shadow;
- track, blue fill, positions, and interaction remain unchanged;
- 21 graduation marks remain only on Attenuation.

No other UI element or functionality was changed.

## Frozen Visual Reference

1.0.39 keeps the validated 1.0.36 sliders and thumbs exactly as-is.

Only the outer window corners use a continuous 16 pt radius.

No transparency, background, shadow, material, button, size, position, or
functional logic changes.

## Version

```text
Evnia Control 1.0.39
English
```
