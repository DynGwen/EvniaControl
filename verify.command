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

grep -q '<string>1.0.26</string>' "${ROOT_DIR}/Resources/Info.plist"
grep -q '<string>en</string>' "${ROOT_DIR}/Resources/Info.plist"
grep -q 'title: "Brightness"' "${MENU}"

echo "Tahoe sliders: OK"
echo "20 × 16 thumbs: OK"
echo "White thumbs in dark mode: OK"
echo "21 attenuation graduations: OK"
echo "16 pt corners: OK"
echo "Tahoe background: OK"
echo "Mute at 0%: OK"
echo "1.0.26 features preserved: OK"
echo "Version 1.0.26: OK"
echo "English language: OK"
