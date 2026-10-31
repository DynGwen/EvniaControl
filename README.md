# Evnia Control 1.0.34 — macOS 27

Menu-bar brightness, volume and audio attenuation for Philips Evnia displays
on Apple Silicon. The existing control layout uses native Liquid Glass.

## Keyboard controls

The small and large sun keys decrease/increase brightness by 5 percentage
points. Magic Keyboard native sun key codes 145 (down) and 144 (up) are now
handled as keyDown/keyUp events. They are distinct from ordinary F1/F2 and
from NX brightness media events. Both native sun formats use the same DDC
writer as the brightness slider. Bare F1/F2 remain registered with macOS.
No global keyboard setting is changed and no additional brightness shortcut
combinations are installed.

The existing HID volume/F1/F2 listener stays in place. A brightness-only
session listener also accepts native sun events generated later in the event
stream. It ignores volume, mute, ordinary F1/F2 and unrelated keys. Events
consumed by the primary HID tap do not propagate to the session tap.

The Carbon receiver uses the application event target; registrations use the
dispatcher target. Only successful registrations own a key, so the event tap
can handle unregistered F1/F2 without blocking registered keys or doubling a
step. Registrations recover after wake and while the display is available.
Keyboard controls are always enabled. Media events require Accessibility access.

Volume keeps its existing 5% step, Option+Shift 1% adjustment and mute behavior.

## Popups and options

When the main menu is closed, changes show a compact Brightness or Volume
slider below the status icon. It stays for two seconds after the last change,
pauses on hover/drag and keeps the current application's keyboard focus.
Options contains launch at login and audio attenuation controls.

## Cleanup and installation

Keyboard diagnostics, arrow shortcuts, an unused corner helper and old-OS
compatibility branches have been removed. The installer deletes exact retired
source filenames if an archive was extracted over older sources, clears old
build caches and replaces the installed app. It also removes the known older
per-user app copy. Saved brightness, volume and attenuation remain available.

Requires Apple Silicon, macOS 27+, a macOS 27+ SDK from Xcode/Command Line Tools,
and Internet for CoreAudioTapKit/m1ddc. Run install.command. It builds the app,
runs fourteen standalone Swift routing checks without XCTest and installs in
/Applications/Evnia Control.app. Temporary installer staging is removed after
launch. verify.command performs the full build and routing checks separately.

Native key-code reference: [Magic Keyboard brightness event report by the
MonitorControl/BetterDisplay maintainer](https://github.com/Hammerspoon/hammerspoon/issues/706).

This release was prepared on Linux without Swift or a macOS SDK. Shell,
cleanup and archive checks are distinct from native compilation. Direct sun-key
operation without Fn on the Magic Keyboard Lightning, Carbon registration and hardware behavior require testing
on the target Mac. The user previously confirmed native brightness with Fn,
volume keys and the brightness slider.

See INSTALLATION_FR.md and TESTS_MANUELS_FR.md.
