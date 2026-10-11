#!/bin/bash

# Check which region Google thinks your proxy exit IP is in.
# Gemini in Chrome's server-side region check uses Google's own geo database,
# which differs from ipinfo/MaxMind — CN-carrier international exits (CTG, CMI,
# CN2) often register as "US" on ipinfo but "cn" on Google.
#
# Usage: bash check-region.sh [proxy]     (default proxy: http://127.0.0.1:7890)
# Switch nodes in your proxy app, re-run this, and only proceed when it prints GOOD.

PROXY="${1:-http://127.0.0.1:7890}"

echo "== Test 1: google.com region redirect =="
R=$(curl -s --max-time 15 --proxy "$PROXY" -o /dev/null -w "%{redirect_url}" "https://www.google.com/")
if [ -z "$R" ]; then
    echo "  no redirect ✓ (Google does not think you are in CN)"
elif echo "$R" | grep -qE 'google\.com\.hk|hl=zh-CN|pref=hkredirect'; then
    echo "  ✗ Google thinks you are in CN (redirects to google.com.hk)"
else
    echo "  redirected to: $R"
fi

echo "== Test 2: variations seed server x-country =="
C=$(curl -s --max-time 15 --proxy "$PROXY" -D - -o /dev/null \
    "https://clientservices.googleapis.com/chrome-variations/seed?os=mac&channel=stable&milestone=154" \
    | grep -i '^x-country' | tr -d '\r' | awk '{print $2}')
echo "  x-country: ${C:-<no response>}"

echo ""
if [ -n "$C" ] && [ "$C" != "cn" ] && [ "$C" != "hk" ]; then
    echo "✅ GOOD — Google sees you in a supported region ($C)."
    echo "   Quit Chrome (Cmd+Q), then run: bash launch-glic.sh"
else
    echo "❌ Still seen as CN/HK — switch to another node and re-run this script."
    echo "   Pick a 'native IP' node; avoid 中转/IEPL/CN2 exits (CTG/CMI ranges)."
fi
