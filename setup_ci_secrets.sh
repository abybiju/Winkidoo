#!/usr/bin/env bash
# One-time helper: push the secrets the cloud APK build needs into GitHub Actions.
#
# Reads values from your LOCAL gitignored files (dart_defines.json, key.properties,
# the keystore, google-services.json) and uploads them as encrypted repo secrets via
# the GitHub CLI. Nothing secret is printed or committed. Safe to re-run (overwrites).
#
# Prereqs: `gh auth status` must show you logged in, and you must run this from the
# repo root with dart_defines.json + android/key.properties filled in.
set -euo pipefail
cd "$(dirname "$0")"

command -v gh >/dev/null || { echo "ERROR: gh CLI not installed"; exit 1; }
[[ -f dart_defines.json ]] || { echo "ERROR: dart_defines.json missing"; exit 1; }
[[ -f android/key.properties ]] || { echo "ERROR: android/key.properties missing"; exit 1; }
[[ -f android/upload-keystore.jks ]] || { echo "ERROR: android/upload-keystore.jks missing"; exit 1; }
[[ -f android/app/google-services.json ]] || { echo "ERROR: android/app/google-services.json missing"; exit 1; }

# --- dart-define values (parsed from dart_defines.json) ---
# Note: GEMINI_API_KEY and TAVILY_API_KEY are deliberately excluded — both are
# proxied server-side (gemini-proxy / tavily-proxy Edge Functions), so they are
# Supabase secrets, not client/CI secrets. Set them with:
#   supabase secrets set GEMINI_API_KEY=<key>
#   supabase secrets set TAVILY_API_KEY=<key>
for KEY in SUPABASE_URL SUPABASE_ANON_KEY REVENUECAT_API_KEY; do
  VALUE=$(python3 -c "import json,sys; print(json.load(open('dart_defines.json')).get('$KEY',''))")
  if [[ -z "$VALUE" || "$VALUE" == YOUR_* ]]; then
    echo "  ! skipping $KEY (empty or still a placeholder in dart_defines.json)"
    continue
  fi
  printf '%s' "$VALUE" | gh secret set "$KEY"
  echo "  ✓ $KEY"
done

# --- signing: keystore (base64) + the two passwords from key.properties ---
base64 -i android/upload-keystore.jks | gh secret set ANDROID_KEYSTORE_BASE64
echo "  ✓ ANDROID_KEYSTORE_BASE64"

STORE_PW=$(grep '^storePassword=' android/key.properties | cut -d= -f2-)
KEY_PW=$(grep '^keyPassword=' android/key.properties | cut -d= -f2-)
printf '%s' "$STORE_PW" | gh secret set ANDROID_STORE_PASSWORD
echo "  ✓ ANDROID_STORE_PASSWORD"
printf '%s' "$KEY_PW" | gh secret set ANDROID_KEY_PASSWORD
echo "  ✓ ANDROID_KEY_PASSWORD"

# --- Firebase config needed at build time (google-services plugin) ---
base64 -i android/app/google-services.json | gh secret set GOOGLE_SERVICES_JSON_BASE64
echo "  ✓ GOOGLE_SERVICES_JSON_BASE64"

echo
echo "Done. Verify with:  gh secret list"
