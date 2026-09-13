# Evnia Control 1.0.26 — English

Evnia Control is a small native macOS menu-bar utility for controlling a
Philips Evnia display.

## Frozen 1.0.26 state

This 1.0.26 is the validated visual and functional state:

- DDC brightness and volume;
- Magic Keyboard media keys;
- 5% normal steps, 1% with Option+Shift;
- explicit mute with the displayed volume immediately set to 0%;
- last audible volume restored on unmute;
- software audio attenuation from −60 dB to 0 dB in 3 dB steps;
- 21 attenuation tick marks;
- macOS accent-colored slider tracks;
- 20 × 16 pt rounded flat thumbs;
- 16 pt continuous window corners;
- validated Tahoe window background;
- audio recovery after display sleep;
- installation in `/Applications/Evnia Control.app`;
- no Ambiglow management.

## Installation

Double-click `install.command`.

The installer builds Evnia Control and `m1ddc`, creates the app bundle,
applies a local code signature, and installs it in `/Applications`.
Administrator authorization is requested for installation.

When audio attenuation is enabled for the first time, macOS may request
system audio recording permission.

## Audio dependency

CoreAudioTapKit resolves from version `0.1.0`.
