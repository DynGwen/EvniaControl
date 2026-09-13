#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODEL="${ROOT_DIR}/Sources/Core/AppModel.swift"
INSTALLER="${ROOT_DIR}/install.command"

plutil -lint "${ROOT_DIR}/Resources/Info.plist"

grep -q 'volume = restoredMuted ? 0 : restoredVolume' "${MODEL}"
grep -q 'volume = 0' "${MODEL}"
grep -q 'lastAudibleVolume' "${MODEL}"
grep -q 'persistMuteState' "${MODEL}"
grep -q 'INSTALL_DIR="/Applications"' "${INSTALLER}"
grep -q 'with administrator privileges' "${INSTALLER}"
grep -q 'recoverAfterScreenWake' "${MODEL}"
grep -q 'prepareForWakeRestart' "${MODEL}"
grep -q 'brightnessStep = 5' "${MODEL}"
grep -q 'volumeStep = 5' "${MODEL}"
grep -q 'minValue: -60' "${ROOT_DIR}/Sources/UI/AttenuationControlView.swift"

if grep -Rqi 'ambiglow' "${ROOT_DIR}/Sources"; then
    echo "FAIL: Ambiglow code found"
    exit 1
fi

if grep -q 'arrow.clockwise' "${ROOT_DIR}/Sources/UI/MenuContentView.swift"; then
    echo "FAIL: manual Refresh returned"
    exit 1
fi

echo "Mute display 0%: OK"
echo "Restore previous audible volume: OK"
echo "No Ambiglow management: OK"
echo "/Applications installer: OK"
echo "Audio wake recovery preserved: OK"
