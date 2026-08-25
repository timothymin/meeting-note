#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
DIST_DIR="${PROJECT_ROOT}/dist"
APP_PATH="${DIST_DIR}/MeetingNote.app"
CACHE_DIR="${PROJECT_ROOT}/.cache"
SCRATCH_DIR="${PROJECT_ROOT}/.build"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/meeting-note-package.XXXXXX")"
MLX_SWIFT_VERSION="0.31.6"
MLX_CMLX_ARCHIVE="${CACHE_DIR}/Cmlx-${MLX_SWIFT_VERSION}.xcframework.zip"
MLX_CMLX_SHA256="a202bf1dcfe1e64404adabfeb5eb363332e3a6221d18e4289ca0663fa3ab86c9"
MLX_CMLX_URL="https://github.com/ml-explore/mlx-swift/releases/download/${MLX_SWIFT_VERSION}/Cmlx.xcframework.zip"
MLX_METALLIB="${CACHE_DIR}/mlx-${MLX_SWIFT_VERSION}.metallib"
trap 'rm -rf "${TEMP_DIR}"' EXIT

if [[ "$(uname -m)" != "arm64" ]]; then
  print -u2 "Meeting Note requires an Apple silicon Mac."
  exit 1
fi

cd "${PROJECT_ROOT}"
mkdir -p "${DIST_DIR}" "${CACHE_DIR}/clang" "${CACHE_DIR}/swiftpm" "${CACHE_DIR}/swiftpm-module"

export CLANG_MODULE_CACHE_PATH="${CACHE_DIR}/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="${CACHE_DIR}/swiftpm-module"

SWIFT_FLAGS=(--disable-sandbox --cache-path "${CACHE_DIR}/swiftpm" --scratch-path "${SCRATCH_DIR}")
swift build "${SWIFT_FLAGS[@]}" -c release --product MeetingNote
BIN_PATH="$(swift build "${SWIFT_FLAGS[@]}" -c release --show-bin-path)"

# `swift build` does not emit MLX's Metal shader library. Use the official,
# version-matched Cmlx release asset and verify it before extracting the macOS
# library. MLX looks for mlx.metallib next to the executable first.
if [[ ! -f "${MLX_METALLIB}" ]]; then
  if [[ ! -f "${MLX_CMLX_ARCHIVE}" ]]; then
    print "Downloading MLX ${MLX_SWIFT_VERSION} Metal runtime…"
    curl -fL "${MLX_CMLX_URL}" -o "${MLX_CMLX_ARCHIVE}"
  fi

  ACTUAL_CMLX_SHA256="$(shasum -a 256 "${MLX_CMLX_ARCHIVE}" | awk '{print $1}')"
  if [[ "${ACTUAL_CMLX_SHA256}" != "${MLX_CMLX_SHA256}" ]]; then
    print -u2 "MLX Cmlx archive checksum mismatch. Delete ${MLX_CMLX_ARCHIVE} and rebuild."
    exit 1
  fi

  unzip -p "${MLX_CMLX_ARCHIVE}" \
    "Cmlx.xcframework/macos-arm64_x86_64/Cmlx.framework/Versions/A/Resources/default.metallib" \
    > "${MLX_METALLIB}"
fi

if [[ ! -s "${MLX_METALLIB}" ]]; then
  print -u2 "MLX Metal runtime is missing or empty: ${MLX_METALLIB}"
  exit 1
fi

if [[ -e "${APP_PATH}" ]]; then
  mv "${APP_PATH}" "${DIST_DIR}/MeetingNote.previous.$(date +%Y%m%d-%H%M%S).app"
fi

mkdir -p "${APP_PATH}/Contents/MacOS" "${APP_PATH}/Contents/Resources"
ditto "${PROJECT_ROOT}/MeetingNote/Info.plist" "${APP_PATH}/Contents/Info.plist"
ditto "${BIN_PATH}/MeetingNote" "${APP_PATH}/Contents/MacOS/MeetingNote"
ditto "${MLX_METALLIB}" "${APP_PATH}/Contents/MacOS/mlx.metallib"

swift "${SCRIPT_DIR}/generate-icon.swift" "${APP_PATH}/Contents/Resources/MeetingNote.icns"

for resource_bundle in "${BIN_PATH}"/*.bundle(N); do
  ditto "${resource_bundle}" "${APP_PATH}/Contents/Resources/${resource_bundle:t}"
done

codesign --force --deep --sign - "${APP_PATH}"
ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${DIST_DIR}/MeetingNote-macOS-arm64.zip"

DMG_STAGE="${TEMP_DIR}/dmg"
mkdir -p "${DMG_STAGE}"
ditto "${APP_PATH}" "${DMG_STAGE}/MeetingNote.app"
ln -s /Applications "${DMG_STAGE}/Applications"
hdiutil create -volname "Meeting Note" -srcfolder "${DMG_STAGE}" -ov -format UDZO "${DIST_DIR}/MeetingNote-macOS-arm64.dmg" >/dev/null

print "Built ${APP_PATH}"
print "Packaged ${DIST_DIR}/MeetingNote-macOS-arm64.zip"
print "Packaged ${DIST_DIR}/MeetingNote-macOS-arm64.dmg"
