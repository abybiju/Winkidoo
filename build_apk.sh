#!/usr/bin/env bash
# Build a signed release Android APK for smoke-testing (Firebase App Distribution
# or direct sideload). Unlike build_release.sh (which builds an .aab for the Play
# Store), this produces a single universal .apk testers can install directly.
#
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

echo "==> Building signed release APK"
flutter build apk --release --dart-define-from-file=dart_defines.json

APK="build/app/outputs/flutter-apk/app-release.apk"
echo
echo "==> Build complete:"
ls -lh "$APK"
echo
echo "Verify it is signed with the upload key (NOT debug):"
echo "  jarsigner -verify -verbose -certs $APK | head"
echo
echo "Distribute via Firebase App Distribution:"
echo "  firebase appdistribution:distribute $APK \\"
echo "    --app 1:356170729561:android:5cecd367b13b50faac4948 \\"
echo "    --release-notes \"Winkidoo 0.2.0 smoke test\" \\"
echo "    --testers \"tester1@example.com,tester2@example.com\""
