# Evnia Control 1.0.26 — English

Evnia Control is a small native macOS application for controlling a Philips
Evnia display from the menu bar.

## Frozen 1.0.26 state

This 1.0.26 release preserves the validated visual and functional state:

- DDC brightness and volume control;
- Magic Keyboard media keys;
- 5% volume steps, or 1% with Option+Shift;
- explicit mute with the displayed volume changing immediately to 0%;
- restores the last audible volume when unmuting;
- audio attenuation from −60 dB to 0 dB in 3 dB steps;
- 21 attenuation graduations;
- sliders using the macOS accent color;
- flat rounded 20 × 16 pt thumbs;
- white slider thumbs in dark mode;
- continuous 16 pt corners;
- validated Tahoe window background;
- audio recovery after the display wakes;
- installation in `/Applications/Evnia Control.app`;
- no Ambiglow management.

## Installation

Double-click `install.command`.

The installer builds Evnia Control and `m1ddc`, creates the application, signs
it locally, and installs it in `/Applications`. Administrator authorization is
requested for installation.

When audio attenuation is first enabled, macOS may request System Audio
Recording permission.

## Audio dependency

CoreAudioTapKit is resolved from version `0.1.0`.
