#!/usr/bin/env bash
# Build a signed release Android App Bundle (.aab) for Play Store upload.
# Keys are read from dart_defines.json (gitignored). Copy dart_defines.example.json
# to dart_defines.json and fill in real values before running.
set -euo pipefail

cd "$(dirname "$0")"

if [[ ! -f dart_defines.json ]]; then
  echo "ERROR: dart_defines.json not found."
  echo "  cp dart_defines.example.json dart_defines.json   # then fill in real keys"
  exit 1
fi

if [[ ! -f android/upload-keystore.jks ]]; then
  echo "ERROR: android/upload-keystore.jks missing — release build would fall back to debug signing."
  exit 1
fi

echo "==> flutter pub get"
flutter pub get

echo "==> Building signed release appbundle"
flutter build appbundle --release --dart-define-from-file=dart_defines.json

AAB="build/app/outputs/bundle/release/app-release.aab"
echo
echo "==> Build complete:"
ls -lh "$AAB"
echo
echo "Verify signing with:"
echo "  jarsigner -verify -verbose -certs $AAB | head"
