#!/usr/bin/env bash
# One-time helper: read TAVILY_API_KEY from the local (gitignored) dart_defines.json
# and store it as a Supabase secret for the tavily-proxy Edge Function.
# The key is never printed. Safe to re-run (e.g. after rotating the key).
set -euo pipefail
cd "$(dirname "$0")"

KEY=$(python3 -c "import json; print(json.load(open('dart_defines.json')).get('TAVILY_API_KEY',''))")

if [[ -z "$KEY" || "$KEY" == YOUR_* ]]; then
  echo "ERROR: TAVILY_API_KEY is missing or a placeholder in dart_defines.json"
  exit 1
fi

echo "Setting TAVILY_API_KEY (${#KEY} chars) as a Supabase secret..."
supabase secrets set TAVILY_API_KEY="$KEY"

echo
echo "Verifying it landed:"
supabase secrets list | grep -i TAVILY && echo "✓ TAVILY_API_KEY is set." \
  || echo "✗ Not found — something went wrong above."
