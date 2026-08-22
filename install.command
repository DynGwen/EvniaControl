#!/bin/zsh
set -euo pipefail

APP_NAME="Evnia Control"
PRODUCT_NAME="EvniaControl"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="${ROOT_DIR}/.installer-build"
VENDOR_DIR="${WORK_DIR}/vendor"
APP_BUNDLE="${WORK_DIR}/${APP_NAME}.app"
INSTALL_DIR="${HOME}/Applications"
INSTALL_APP="${INSTALL_DIR}/${APP_NAME}.app"
M1DDC_DIR="${VENDOR_DIR}/m1ddc"

log() {
    printf "\033[1;36m[Evnia Control]\033[0m %s\n" "$1"
}

fail() {
    printf "\033[1;31m[Error]\033[0m %s\n" "$1" >&2
    exit 1
}

if [[ "$(uname -m)" != "arm64" ]]; then
    fail "Evnia Control 1.0.24 requires an Apple Silicon Mac."
fi

if ! xcode-select -p >/dev/null 2>&1; then
    log "Apple Command Line Tools are required."
    xcode-select --install || true
    printf "\nRun install.command again after they are installed.\n"
    exit 0
fi

log "Stopping the previous version..."
pkill -x "${APP_NAME}" >/dev/null 2>&1 || true
sleep 1

rm -rf "${WORK_DIR}"
mkdir -p "${VENDOR_DIR}"

log "Building Evnia Control and the audio engine..."
cd "${ROOT_DIR}"
swift build \
    -c release \
    --product "${PRODUCT_NAME}"

EXECUTABLE_PATH="$(
    swift build \
        -c release \
        --show-bin-path
)/${PRODUCT_NAME}"

if [[ ! -x "${EXECUTABLE_PATH}" ]]; then
    fail "Evnia Control failed to build."
fi

log "Downloading the DDC engine..."
git clone --depth 1 \
    https://github.com/waydabber/m1ddc.git \
    "${M1DDC_DIR}" >/dev/null 2>&1

log "Building the DDC engine..."
make -C "${M1DDC_DIR}" >/dev/null

M1DDC_BINARY="${M1DDC_DIR}/m1ddc"
if [[ ! -x "${M1DDC_BINARY}" ]]; then
    fail "m1ddc failed to build."
fi

log "Creating the application..."
mkdir -p \
    "${APP_BUNDLE}/Contents/MacOS" \
    "${APP_BUNDLE}/Contents/Resources/Licenses"

cp "${ROOT_DIR}/Resources/Info.plist" \
    "${APP_BUNDLE}/Contents/Info.plist"

log "Creating the application icon..."
iconutil -c icns \
    "${ROOT_DIR}/Resources/AppIcon.iconset" \
    -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

cp "${EXECUTABLE_PATH}" \
    "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x \
    "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

cp "${M1DDC_BINARY}" \
    "${APP_BUNDLE}/Contents/Resources/m1ddc"
chmod +x \
    "${APP_BUNDLE}/Contents/Resources/m1ddc"

cp "${M1DDC_DIR}/LICENSE" \
    "${APP_BUNDLE}/Contents/Resources/Licenses/m1ddc-LICENSE.txt"

log "Applying local signature..."
codesign \
    --force \
    --deep \
    --sign - \
    "${APP_BUNDLE}" >/dev/null

mkdir -p "${INSTALL_DIR}"
rm -rf "${INSTALL_APP}"
ditto "${APP_BUNDLE}" "${INSTALL_APP}"

log "Installation complete: ${INSTALL_APP}"
log "Launching..."
open "${INSTALL_APP}"

printf "\n"
printf "Audio attenuation may require permission for "
printf "System Audio Recording the first time it is enabled.\n"
