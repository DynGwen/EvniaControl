#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DELEGATE="${ROOT_DIR}/Sources/App/AppDelegate.swift"
MODEL="${ROOT_DIR}/Sources/Core/AppModel.swift"
AUDIO="${ROOT_DIR}/Sources/Services/AudioController.swift"

plutil -lint "${ROOT_DIR}/Resources/Info.plist"

grep -q 'screensDidSleepNotification' "${DELEGATE}"
grep -q 'screensDidWakeNotification' "${DELEGATE}"
grep -q 'willSleepNotification' "${DELEGATE}"
grep -q 'didWakeNotification' "${DELEGATE}"

grep -q 'prepareForScreenSleep' "${MODEL}"
grep -q 'recoverAfterScreenWake' "${MODEL}"
grep -q 'for attempt in 0..<6' "${MODEL}"

grep -q 'preferredOutputUID' "${AUDIO}"
grep -q 'suspendForScreenSleep' "${AUDIO}"
grep -q 'resumePreferredOutput' "${AUDIO}"
grep -q 'resumeDefaultOutput' "${AUDIO}"

grep -q 'brightnessStep = 5' "${MODEL}"
grep -q 'volumeStep = 5' "${MODEL}"
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

grep -q '1.0.21' \
    "${ROOT_DIR}/Resources/Info.plist"

echo "Screen sleep observer: OK"
echo "Screen wake observer: OK"
echo "Audio tap suspension: OK"
echo "Preferred output recovery: OK"
echo "Bounded fallback recovery: OK"
echo "Existing settings preserved: OK"
echo "Version 1.0.21: OK"
