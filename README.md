# Evnia Control

**Evnia Control 1.0.21** is a lightweight macOS menu bar application for controlling a Philips Evnia display from a Mac.

It provides direct control of display brightness and hardware volume through DDC/CI, supports Magic Keyboard media keys, and adds optional software audio attenuation for monitors whose minimum volume is still too loud.

---

## Features

- Philips Evnia display auto-detection
- Brightness control through DDC/CI
- Hardware volume control through DDC/CI
- Mute control
- Magic Keyboard brightness keys
- Magic Keyboard volume keys
- Magic Keyboard mute key
- 5% normal adjustment steps
- `Option + Shift` for 1% fine adjustments
- Software audio attenuation from `−60 dB` to `0 dB`
- 3 dB attenuation steps
- Persistent brightness, volume and attenuation settings
- Automatic refresh after launch, display changes and wake
- Launch at login
- Native macOS menu bar interface
- Native application icon

---

## Requirements

- Apple Silicon Mac
- macOS 14.2 or later
- Philips Evnia monitor with DDC/CI enabled
- Apple Command Line Tools
- Internet connection during installation

The installer downloads and builds the required open-source components:

- `m1ddc` for DDC/CI control
- `CoreAudioTapKit` for software audio attenuation

---

## Installation

### 1. Extract the archive

Unzip the downloaded archive.

Open the extracted folder:

```text
Evnia-Control-1.0.20-English
```

### 2. Run the installer

Double-click:

```text
install.command
```

The installer will:

1. stop any existing Evnia Control process;
2. build Evnia Control;
3. build the Core Audio attenuation component;
4. download and build `m1ddc`;
5. generate the application icon;
6. locally sign the application;
7. install it to:

```text
~/Applications/Evnia Control.app
```

8. launch Evnia Control.

### 3. If macOS blocks the installer

Open:

**System Settings → Privacy & Security**

Scroll to the security section and allow `install.command` to run.

You can also run it from Terminal:

```bash
chmod +x install.command
./install.command
```

If Apple Command Line Tools are missing, macOS will prompt you to install them. After installation, run `install.command` again.

---

## First Launch

Evnia Control appears in the macOS menu bar.

The main panel provides:

- Brightness
- Volume
- Mute
- Options
- Quit

There is no manual Refresh button. Display state is refreshed automatically.

---

## Magic Keyboard Permission

Magic Keyboard media keys require macOS Accessibility permission.

Open:

**System Settings → Privacy & Security → Accessibility**

Enable:

**Evnia Control**

This permission is required for:

- brightness up / down;
- volume up / down;
- mute.

Normal adjustments use 5% steps.

For fine adjustments, hold:

```text
Option + Shift
```

The adjustment step becomes 1%.

If media keys do not respond immediately after granting permission, quit and reopen Evnia Control.

---

## Audio Attenuation

Some monitors remain too loud even at very low hardware volume.

Evnia Control can apply additional software attenuation through Core Audio.

Available range:

```text
−60 dB → 0 dB
```

Step:

```text
3 dB
```

Meaning:

- `0 dB` — no additional attenuation
- `−3 dB` — slightly quieter
- `−30 dB` — strong attenuation
- `−60 dB` — maximum attenuation

The attenuation control is available in:

**Evnia Control → Options…**

The first time attenuation is enabled, macOS may request permission to capture system audio. This permission is required for the Core Audio attenuation engine.

---

## Options

Open:

**Evnia Control → Options…**

Available settings:

### Launch at Login

Automatically starts Evnia Control when you sign in to macOS.

### Audio Attenuation

Adjusts software attenuation from `−60 dB` to `0 dB`.

---

## Saved Settings

Evnia Control remembers:

- brightness;
- volume;
- audio attenuation.

These values are restored after the application is restarted.

Saved brightness and volume remain authoritative during startup, preventing temporary DDC readings from replacing the user's stored settings.

---

## Automatic Refresh

Evnia Control refreshes display state automatically:

- when the application starts;
- every 30 seconds;
- after the display configuration changes;
- after the Mac wakes from sleep.

---

## DDC/CI

Brightness and hardware volume require DDC/CI.

Make sure DDC/CI is enabled in the Philips Evnia monitor settings.

If brightness or volume does not respond:

1. verify that DDC/CI is enabled;
2. disconnect and reconnect the monitor;
3. quit Evnia Control;
4. reopen Evnia Control.

---

## Updating

To install a newer version:

1. quit Evnia Control;
2. extract the new archive;
3. run the new `install.command`.

The installer automatically replaces the existing application.

User settings are stored separately by macOS and are preserved between versions.

---

## Uninstalling

Quit Evnia Control and delete:

```text
~/Applications/Evnia Control.app
```

You can also remove it from:

**System Settings → General → Login Items**

Optional permissions can be removed from:

**System Settings → Privacy & Security**

including:

- Accessibility
- System Audio Recording

---

## Installation Location

Evnia Control is installed for the current user only:

```text
~/Applications/Evnia Control.app
```

No Homebrew installation is required for normal use.


---

## Screen Sleep and Audio Recovery

When the Evnia display goes to sleep, its audio device can temporarily
disappear from Core Audio.

Evnia Control now handles this automatically:

1. the software attenuation engine is released when the screen sleeps;
2. the previously used audio-output UID is remembered;
3. when the screen wakes, Evnia Control waits for that output to return;
4. the attenuation engine is rebuilt on the same output;
5. if the previous output does not return after bounded retries, Evnia Control
   falls back to the currently available macOS output instead of leaving the
   system silent.

This recovery runs only after screen/system wake. It does not add permanent
high-frequency polling.

---

## Version

```text
Evnia Control 1.0.21
English
```
