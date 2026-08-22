#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODEL="${ROOT_DIR}/Sources/Core/AppModel.swift"
INSTALLER="${ROOT_DIR}/install.command"

plutil -lint "${ROOT_DIR}/Resources/Info.plist"

grep -q 'monitorState.muted' "${MODEL}"
grep -q 'persistMuteState' "${MODEL}"

# No automatic or volume-control implicit unmute.
if sed -n '/func refresh()/,/func userSetBrightness/p' "${MODEL}" \
    | grep -q 'isMuted = false'; then
    echo "FAIL: refresh can still clear mute"
    exit 1
fi

if sed -n '/func userSetVolume/,/func changeBrightness/p' "${MODEL}" \
    | grep -q 'isMuted = false'; then
    echo "FAIL: mouse volume can still clear mute"
    exit 1
fi

if sed -n '/func changeVolume/,/func toggleMute/p' "${MODEL}" \
    | grep -q 'isMuted = false'; then
    echo "FAIL: keyboard volume can still clear mute"
    exit 1
fi

grep -q 'volumeWriteTask?.cancel()' "${MODEL}"
grep -q 'try? await driver.setVolume(0)' "${MODEL}"

# Installer destination.
grep -q 'INSTALL_DIR="/Applications"' "${INSTALLER}"
grep -q 'with administrator privileges' "${INSTALLER}"
grep -q 'LEGACY_INSTALL_APP=' "${INSTALLER}"

if grep -q 'INSTALL_DIR="${HOME}/Applications"' "${INSTALLER}"; then
    echo "FAIL: installer still targets user Applications"
    exit 1
fi

# Existing behavior.
grep -q 'screensDidWakeNotification' \
    "${ROOT_DIR}/Sources/App/AppDelegate.swift"
grep -q 'prepareForWakeRestart' "${MODEL}"
grep -q 'brightnessStep = 5' "${MODEL}"
grep -q 'volumeStep = 5' "${MODEL}"
grep -q 'minValue: -60' \
    "${ROOT_DIR}/Sources/UI/AttenuationControlView.swift"

if grep -q 'arrow.clockwise' \
    "${ROOT_DIR}/Sources/UI/MenuContentView.swift"; then
    echo "FAIL: manual Refresh returned"
    exit 1
fi

grep -q '1.0.25' "${ROOT_DIR}/Resources/Info.plist"

echo "Sticky mute state: OK"
echo "No refresh/mouse/keyboard implicit unmute: OK"
echo "Pending volume-write race removed: OK"
echo "/Applications installer: OK"
echo "Administrator authorization: OK"
echo "Legacy user app cleanup: OK"
echo "Existing 1.0.24 behavior preserved: OK"
echo "Version 1.0.25: OK"
