#!/usr/bin/env bash
set -euo pipefail
CFWU_PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${CFWU_SWIFT_BIN:-}" ]]; then
    CFWU_SWIFT="$CFWU_SWIFT_BIN"
elif command -v swift >/dev/null 2>&1; then
    CFWU_SWIFT="$(command -v swift)"
else
    CFWU_SWIFT=/workspace/toolchains/swift-6.0.3-RELEASE-ubuntu22.04/usr/bin/swift
fi
CFWU_CACHE_ROOT="${TMPDIR:-/tmp}/cfwu-swift-cache"
mkdir -p "$CFWU_CACHE_ROOT/clang" "$CFWU_CACHE_ROOT/config" "$CFWU_CACHE_ROOT/security"
export CLANG_MODULE_CACHE_PATH="$CFWU_CACHE_ROOT/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="$CFWU_CACHE_ROOT/clang"
cd "$CFWU_PROJECT_ROOT"
"$CFWU_SWIFT" test --jobs 4 --cache-path "$CFWU_CACHE_ROOT" --config-path "$CFWU_CACHE_ROOT/config" --security-path "$CFWU_CACHE_ROOT/security"
# Parse all Apple-platform sources, without pretending this resolves their SDKs.
"${CFWU_SWIFT}c" -frontend -parse YourFarmWithUnicorns/*.swift
