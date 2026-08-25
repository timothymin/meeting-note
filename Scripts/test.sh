#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
CACHE_DIR="${PROJECT_ROOT}/.cache"

mkdir -p "${CACHE_DIR}/clang" "${CACHE_DIR}/swiftpm" "${CACHE_DIR}/swiftpm-module"
export CLANG_MODULE_CACHE_PATH="${CACHE_DIR}/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="${CACHE_DIR}/swiftpm-module"

cd "${PROJECT_ROOT}"
swift test \
  --disable-sandbox \
  --cache-path "${CACHE_DIR}/swiftpm" \
  --scratch-path "${PROJECT_ROOT}/.build"
