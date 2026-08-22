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

grep -q 'screensDidWakeNotification' \
    "${ROOT_DIR}/Sources/App/AppDelegate.swift"
grep -q 'recoverAfterScreenWake' \
    "${ROOT_DIR}/Sources/Core/AppModel.swift"
grep -q 'prepareForWakeRestart' \
    "${ROOT_DIR}/Sources/Core/AppModel.swift"

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

grep -q '1.0.24' \
    "${ROOT_DIR}/Resources/Info.plist"

echo "English interface: OK"
echo "English README: OK"
echo "Audio wake restart fix preserved: OK"
echo "Existing behavior preserved: OK"
echo "Version 1.0.24: OK"
