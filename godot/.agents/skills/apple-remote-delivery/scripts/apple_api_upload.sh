#!/usr/bin/env bash
set -euo pipefail

ipa="${1:?usage: apple_api_upload.sh <ipa> <expected-sha256> <build-number>}"
expected_sha="${2:?expected SHA-256 required}"
build="${3:?build number required}"
: "${APPLE_API_KEY_ID:?APPLE_API_KEY_ID is required}"
: "${APPLE_API_ISSUER_ID:?APPLE_API_ISSUER_ID is required}"
: "${APPLE_API_PRIVATE_KEY_PATH:?APPLE_API_PRIVATE_KEY_PATH is required}"
[[ "${APPLE_API_UPLOAD_ACK:-}" == "API_UPLOAD_BUILD_${build}" ]] || { echo "APPLE_API_UPLOAD_STOP authorization required: APPLE_API_UPLOAD_ACK=API_UPLOAD_BUILD_${build}"; exit 2; }
[[ -f "$ipa" && -f "$APPLE_API_PRIVATE_KEY_PATH" ]] || { echo "APPLE_API_UPLOAD_STOP IPA or private key missing"; exit 2; }
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
case "$APPLE_API_PRIVATE_KEY_PATH" in "$project_root"/*) echo "APPLE_API_UPLOAD_STOP private key must be outside the project"; exit 2;; esac

actual_sha="$(shasum -a 256 "$ipa" | awk '{print $1}')"
[[ "$actual_sha" == "$expected_sha" ]] || { echo "APPLE_API_UPLOAD_STOP IPA SHA-256 mismatch"; exit 2; }

key_dir="$HOME/.appstoreconnect/private_keys"
mkdir -p "$key_dir"
key_copy="$key_dir/AuthKey_${APPLE_API_KEY_ID}.p8"
install -m 600 "$APPLE_API_PRIVATE_KEY_PATH" "$key_copy"

echo "APPLE_API_UPLOAD_VALIDATING ipa_sha256=$actual_sha"
xcrun altool --validate-app -f "$ipa" -t ios --apiKey "$APPLE_API_KEY_ID" --apiIssuer "$APPLE_API_ISSUER_ID"
echo "APPLE_API_UPLOAD_START build=$build"
caffeinate -dimsu -- xcrun altool --upload-app -f "$ipa" -t ios --apiKey "$APPLE_API_KEY_ID" --apiIssuer "$APPLE_API_ISSUER_ID"
echo "APPLE_API_UPLOAD_COMMAND_SUCCEEDED build=$build processing=unverified release=not-authorized"
