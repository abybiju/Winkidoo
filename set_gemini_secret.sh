#!/usr/bin/env bash
# One-time helper: read GEMINI_API_KEY from the local (gitignored) dart_defines.json
# and store it as a Supabase secret for the gemini-proxy Edge Function.
# The key is never printed. Safe to re-run (e.g. after rotating the key).
set -euo pipefail
cd "$(dirname "$0")"

KEY=$(python3 -c "import json; print(json.load(open('dart_defines.json')).get('GEMINI_API_KEY',''))")

if [[ -z "$KEY" || "$KEY" == YOUR_* ]]; then
  echo "ERROR: GEMINI_API_KEY is missing or a placeholder in dart_defines.json"
  exit 1
fi

echo "Setting GEMINI_API_KEY (${#KEY} chars) as a Supabase secret..."
supabase secrets set GEMINI_API_KEY="$KEY"

echo
echo "Verifying it landed:"
supabase secrets list | grep -i GEMINI && echo "✓ GEMINI_API_KEY is set." \
  || echo "✗ Not found — something went wrong above."
