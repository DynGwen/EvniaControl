#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
MENU="${ROOT_DIR}/Sources/UI/MenuContentView.swift"
SLIDER="${ROOT_DIR}/Sources/UI/TahoePillSlider.swift"
ATTEN="${ROOT_DIR}/Sources/UI/AttenuationControlView.swift"
WINDOW="${ROOT_DIR}/Sources/UI/TahoeWindowSurface.swift"
MODEL="${ROOT_DIR}/Sources/Core/AppModel.swift"

plutil -lint "${ROOT_DIR}/Resources/Info.plist"

grep -q 'thumbWidth: CGFloat = 20' "${SLIDER}"
grep -q 'thumbHeight: CGFloat = 16' "${SLIDER}"
grep -q 'Color.accentColor' "${SLIDER}"
grep -Fq '@Environment(\.colorScheme)' "${SLIDER}"
grep -q 'Color.white' "${SLIDER}"
# Thumb must be solid, including when the system allows transparency.
# Guard against the old dark-mode charcoal thumb regressing.
grep -Fq '.fill(Color.white)' "${SLIDER}"
if grep -Fq 'Color(red: 0.25, green: 0.27, blue: 0.30)' "${SLIDER}"; then
    echo "FAIL: Slider thumb still switches to charcoal in dark mode"
    exit 1
fi
if grep -q '\.glassEffect(' "${SLIDER}"; then
    echo "FAIL: Slider thumb still uses translucent Liquid Glass"
    exit 1
fi

# Full-strength, system-adaptive percentage text in both control panels.
grep -Fq '.foregroundStyle(Color(nsColor: .labelColor))' "${MENU}"
grep -Fq '.foregroundStyle(Color(nsColor: .labelColor))' "${ROOT_DIR}/Sources/UI/ControlPopupView.swift"

grep -q 'TahoePillSlider(' "${MENU}"
grep -q 'graduationCount: 21' "${ATTEN}"

grep -q 'cornerRadius: CGFloat = 16' "${WINDOW}"
grep -q 'cornerCurve = .continuous' "${WINDOW}"
grep -q 'NSGlassEffectView' "${WINDOW}"
grep -q 'glassView.style = .regular' "${WINDOW}"
grep -q '.glassEffect(' "${WINDOW}"

grep -q 'volume = restoredMuted' "${MODEL}"
grep -q 'volume = 0' "${MODEL}"
grep -q 'lastAudibleVolume' "${MODEL}"
grep -q 'persistMuteState' "${MODEL}"

grep -q 'from: "0.1.0"' "${ROOT_DIR}/Package.swift"
grep -q 'INSTALL_DIR="/Applications"' "${ROOT_DIR}/install.command"

if grep -Rqi 'ambiglow' "${ROOT_DIR}/Sources"; then
    echo "FAIL: Ambiglow code detected"
    exit 1
fi

grep -q '<string>1.0.37</string>' "${ROOT_DIR}/Resources/Info.plist"
grep -q '<string>en</string>' "${ROOT_DIR}/Resources/Info.plist"
grep -q 'title: L10n.brightness' "${MENU}"
grep -q 'static let languageCode = "en"' "${ROOT_DIR}/Sources/Core/L10n.swift"

echo "Tahoe sliders: OK"
echo "20 × 16 thumbs: OK"
echo "White opaque slider thumbs in both modes: OK"
echo "Opaque percentage labels: OK"
echo "21 attenuation graduations: OK"
echo "16 pt corners: OK"
echo "Tahoe background: OK"
echo "Mute at 0%: OK"
echo "Existing control layout preserved: OK"
echo "Version 1.0.37: OK"
echo "English language: OK"

# Real compiler validation in addition to the original visual invariants.
# This project targets macOS 27 and requires its SDK.
swift build --package-path "${ROOT_DIR}" -c release --product EvniaControl
/bin/zsh "${ROOT_DIR}/check-keyboard.command"
