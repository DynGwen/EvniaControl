# Evnia Control

**Evnia Control 1.0.25** is a lightweight macOS menu bar application for controlling a Philips Evnia display from a Mac.

It provides direct brightness and hardware-volume control through DDC/CI, supports Magic Keyboard media keys, and adds optional software audio attenuation for monitors whose minimum volume is still too loud.

---

## Features

- Automatic Philips Evnia display detection
- Brightness control through DDC/CI
- Hardware volume control through DDC/CI
- Mute control
- Persistent mute state: only explicit Mute/Unmute changes it
- Magic Keyboard brightness keys
- Magic Keyboard volume keys
- Magic Keyboard mute key
- 5% normal adjustment steps
- `Option + Shift` for 1% fine adjustments
- Software audio attenuation from `−60 dB` to `0 dB`
- 3 dB attenuation steps
- Persistent brightness, volume and attenuation settings
- Automatic refresh after launch, display changes and wake
- Automatic audio recovery after display sleep
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

Unzip the downloaded archive and open:

```text
Evnia-Control-1.0.25-MuteInstallFix
```

### 2. Run the installer

Double-click:

```text
install.command
```

The installer will automatically:

1. stop any running Evnia Control instance;
2. build Evnia Control;
3. build the Core Audio attenuation engine;
4. download and build `m1ddc`;
5. generate the application icon;
6. locally sign the application;
7. install it to:

```text
/Applications/Evnia Control.app
```

8. launch Evnia Control.

Installation in `/Applications` uses the standard macOS administrator
authorization dialog. Older versions installed in
`~/Applications/Evnia Control.app` are removed after a successful install.

### 3. If macOS blocks install.command

Open:

**System Settings → Privacy & Security**

Allow `install.command` to run, then launch it again.

You can also run it from Terminal:

```bash
chmod +x install.command
./install.command
```

If Apple Command Line Tools are missing, macOS will offer to install them. Run `install.command` again afterward.

---

## First Launch

Evnia Control appears in the macOS menu bar.

The main panel provides:

- Brightness
- Volume
- Mute
- Options
- Quit

There is no manual Refresh button. Refresh is automatic.

---

## Magic Keyboard Permission

Magic Keyboard media keys require macOS Accessibility permission.

Open:

**System Settings → Privacy & Security → Accessibility**

Enable:

**Evnia Control**

Normal adjustments use 5% steps.

Hold:

```text
Option + Shift
```

for 1% fine adjustments.

---

## Audio Attenuation

Evnia Control can apply additional software attenuation through Core Audio.

Range:

```text
−60 dB → 0 dB
```

Step:

```text
3 dB
```

- `0 dB` — no attenuation
- `−3 dB` — light attenuation
- `−30 dB` — strong attenuation
- `−60 dB` — maximum attenuation

The control is available in:

**Evnia Control → Options…**

The first activation may require System Audio Recording permission.

---

## Audio Recovery After Display Sleep

When the Evnia display goes to sleep, its audio device can temporarily disappear from Core Audio.

Evnia Control does **not** tear down the audio tap while the display is going to sleep.

After wake:

1. the application waits 750 ms;
2. it completely stops the old Core Audio engine;
3. it rebuilds the tap on the previously used audio output;
4. if the Evnia output has not returned yet, it retries for a bounded period;
5. as a last resort, it rebuilds the engine on the currently available macOS output so the system does not remain silent.

This recovery runs only after wake and does not add permanent polling.

---

## Options

Open:

**Evnia Control → Options…**

Available settings:

### Launch Evnia Control at Login

Starts Evnia Control automatically when you sign in to macOS.

### Audio Attenuation

Adjusts software attenuation from `−60 dB` to `0 dB`.

---

## Saved Settings

Evnia Control remembers:

- brightness;
- volume;
- mute state;
- audio attenuation.

Mute is sticky: automatic refresh, mouse volume changes and Magic Keyboard
volume changes do not unmute the display. Only the explicit Mute/Unmute
command changes the mute state.

These values are restored after the application is restarted.

---

## Automatic Refresh

Evnia Control refreshes display state automatically:

- at launch;
- every 30 seconds;
- after display configuration changes;
- after wake.

---

## DDC/CI

Brightness and hardware volume require DDC/CI.

Make sure DDC/CI is enabled in the Philips Evnia monitor settings.

If brightness or volume stops responding:

1. confirm DDC/CI is enabled;
2. disconnect and reconnect the monitor;
3. quit Evnia Control;
4. reopen Evnia Control.

---

## Updating

To install a newer version:

1. quit Evnia Control;
2. extract the new archive;
3. run the new `install.command`.

The installer replaces the previous version automatically.

User settings are stored separately in macOS preferences and are preserved.

---

## Uninstalling

Quit Evnia Control and delete:

```text
/Applications/Evnia Control.app
```

You can also disable launch at login in:

**System Settings → General → Login Items**

Permissions can be removed in:

**System Settings → Privacy & Security**

including:

- Accessibility
- System Audio Recording

---

## Version

```text
Evnia Control 1.0.25
English
```
