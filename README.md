# Evnia Control 1.0.37

Menu-bar brightness, volume and audio attenuation controls for Philips Evnia
displays on Apple Silicon Macs.

## Display fix

- The slider **thumbs are fully opaque**, including when Liquid Glass is enabled:
  solid white in both light and dark modes.
- Brightness and volume **percentages** use the primary label color and medium
  weight in the main panel and feedback popups instead of secondary faded text.
- The audio attenuation slider also benefits from the opaque thumb.
- Window Liquid Glass and all control behavior are preserved.

## Installation

Extract into a fresh folder and double-click `install.command`. Requirements:
Apple Silicon, macOS 27+, macOS 27+ SDK, developer tools and Internet access.
See `INSTALLATION_EN.md`.

This archive includes sources and an installer, **not a prebuilt Mac app**.
On a compatible Mac, run `verify.command` for native compilation and checks;
see `MANUAL_TESTS_EN.md` for hardware/UI validation.
