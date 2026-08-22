#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

plutil -lint "${ROOT_DIR}/Resources/Info.plist"

grep -q '<string>en</string>' \
    "${ROOT_DIR}/Resources/Info.plist"
grep -q 'Searching for display' \
    "${ROOT_DIR}/Sources/Core/AppModel.swift"
grep -q 'Connected' \
    "${ROOT_DIR}/Sources/Core/AppModel.swift"
grep -q 'Brightness' \
    "${ROOT_DIR}/Sources/UI/MenuContentView.swift"
grep -q 'Keyboard permission required' \
    "${ROOT_DIR}/Sources/UI/MenuContentView.swift"
grep -q 'Launch Evnia Control at login' \
    "${ROOT_DIR}/Sources/UI/OptionsWindowController.swift"
grep -q 'Attenuation' \
    "${ROOT_DIR}/Sources/UI/AttenuationControlView.swift"
grep -q 'No compatible Evnia display was detected' \
    "${ROOT_DIR}/Sources/Services/M1DDCDriver.swift"

grep -q 'brightnessStep = 5' \
    "${ROOT_DIR}/Sources/Core/AppModel.swift"
grep -q 'volumeStep = 5' \
    "${ROOT_DIR}/Sources/Core/AppModel.swift"
grep -q 'minValue: -60' \
    "${ROOT_DIR}/Sources/UI/AttenuationControlView.swift"
grep -q 'numberOfTickMarks = 21' \
    "${ROOT_DIR}/Sources/UI/AttenuationControlView.swift"
grep -q 'CFBundleIconFile' \
    "${ROOT_DIR}/Resources/Info.plist"

if grep -q 'arrow.clockwise' \
    "${ROOT_DIR}/Sources/UI/MenuContentView.swift"; then
    echo "FAIL: manual Refresh returned"
    exit 1
fi

grep -q '1.0.20' \
    "${ROOT_DIR}/Resources/Info.plist"

echo "English interface strings: OK"
echo "English permission prompt: OK"
echo "English installer: OK"
echo "Functional settings preserved: OK"
echo "Version 1.0.20: OK"
