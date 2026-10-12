#!/usr/bin/env bash
set -euo pipefail
# Linux core-test toolchain only. iPad UI builds still require Xcode on a Mac.
CFWU_TOOLCHAIN_ROOT="${CFWU_TOOLCHAIN_ROOT:-/workspace/toolchains}"
CFWU_SWIFT_VERSION=6.0.3
CFWU_SWIFT_DIRECTORY="$CFWU_TOOLCHAIN_ROOT/swift-$CFWU_SWIFT_VERSION-RELEASE-ubuntu22.04"
if [[ -x "$CFWU_SWIFT_DIRECTORY/usr/bin/swift" ]]; then
    "$CFWU_SWIFT_DIRECTORY/usr/bin/swift" --version
    exit 0
fi
mkdir -p "$CFWU_TOOLCHAIN_ROOT"
CFWU_ARCHIVE="$CFWU_TOOLCHAIN_ROOT/swift-$CFWU_SWIFT_VERSION.tar.gz"
CFWU_BASE_URL="https://download.swift.org/swift-$CFWU_SWIFT_VERSION-release/ubuntu2204/swift-$CFWU_SWIFT_VERSION-RELEASE/swift-$CFWU_SWIFT_VERSION-RELEASE-ubuntu22.04.tar.gz"
curl --fail --location --silent --show-error "$CFWU_BASE_URL" -o "$CFWU_ARCHIVE"
curl --fail --location --silent --show-error "$CFWU_BASE_URL.sig" -o "$CFWU_ARCHIVE.sig"
# Official Swift website signing-key bundle, pinned to inspected commit.
curl --fail --location --silent --show-error 'https://raw.githubusercontent.com/swiftlang/swift-org-website/eea8f179ef67b7a1159afae55171fd06c6cb85b7/keys/all-keys.asc' -o "$CFWU_TOOLCHAIN_ROOT/swift-signing-keys.asc"
CFWU_GPG_DIRECTORY="$(mktemp -d /tmp/cfwu-swift-gpg.XXXXXX)"
trap 'rm -rf "$CFWU_GPG_DIRECTORY"' EXIT
chmod 700 "$CFWU_GPG_DIRECTORY"
gpg --homedir "$CFWU_GPG_DIRECTORY" --batch --import "$CFWU_TOOLCHAIN_ROOT/swift-signing-keys.asc"
gpg --homedir "$CFWU_GPG_DIRECTORY" --batch --status-fd 1 --verify "$CFWU_ARCHIVE.sig" "$CFWU_ARCHIVE" > "$CFWU_TOOLCHAIN_ROOT/swift-signature-status.txt"
rg -q '^\[GNUPG:\] VALIDSIG 52BB7E3DE28A71BE22EC05FFEF80A866B47A981F ' "$CFWU_TOOLCHAIN_ROOT/swift-signature-status.txt"
tar -xzf "$CFWU_ARCHIVE" -C "$CFWU_TOOLCHAIN_ROOT"
"$CFWU_SWIFT_DIRECTORY/usr/bin/swift" --version
