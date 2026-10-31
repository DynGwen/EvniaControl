#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/EvniaControl-keyboard.XXXXXX")"
trap 'rm -rf "${CHECK_DIR}"' EXIT

# Compile the production router directly with a standard-library-only runner.
# No XCTest, Swift Testing, app launch, DDC writes or full Xcode is needed.
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
xcrun --sdk macosx swiftc \
    -sdk "${SDK_PATH}" \
    -swift-version 6 \
    -parse-as-library \
    -O \
    "${ROOT_DIR}/Sources/Core/KeyboardEventRouter.swift" \
    "${ROOT_DIR}/Sources/Core/BrightnessKey.swift" \
    "${ROOT_DIR}/Validation/KeyboardChecks.swift" \
    -o "${CHECK_DIR}/KeyboardChecks"

"${CHECK_DIR}/KeyboardChecks"
