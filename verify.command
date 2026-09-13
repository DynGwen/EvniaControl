#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SLIDER="${ROOT_DIR}/Sources/UI/TahoePillSlider.swift"
ATTEN="${ROOT_DIR}/Sources/UI/AttenuationControlView.swift"
MODEL="${ROOT_DIR}/Sources/Core/AppModel.swift"

plutil -lint "${ROOT_DIR}/Resources/Info.plist"

grep -q 'thumbWidth: CGFloat = 20' "${SLIDER}"
grep -q 'thumbHeight: CGFloat = 16' "${SLIDER}"
grep -q 'cornerRadius: 8' "${SLIDER}"
grep -q 'trackHeight: CGFloat = 6' "${SLIDER}"

grep -q 'graduationCount: 21' "${ATTEN}"
grep -q 'step: 3' "${ATTEN}"

grep -q 'volume = 0' "${MODEL}"
grep -q 'recoverAfterScreenWake' "${MODEL}"

if grep -Rqi 'ambiglow' "${ROOT_DIR}/Sources"; then
    echo "FAIL: Ambiglow code found"
    exit 1
fi

grep -q '1.0.36' "${ROOT_DIR}/Resources/Info.plist"

echo "Smaller Tahoe thumb: OK"
echo "Attenuation 21 graduations: OK"
echo "Functional state preserved: OK"
echo "No Ambiglow management: OK"
echo "Version 1.0.36: OK"
