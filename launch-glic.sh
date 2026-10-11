#!/bin/bash

# Launch Chrome with the Gemini (Glic) sidebar enabled for non-US users.
# Complements install.sh: install.sh patches Local State once; this script
# relaunches Chrome with the country override that keeps Glic studies active.
# Usage: bash launch-glic.sh   (macOS)

set -e

STATE="$HOME/Library/Application Support/Google/Chrome/Local State"

if pgrep -x "Google Chrome" > /dev/null 2>&1; then
    echo "⚠️  Chrome is running. Quit it first (Cmd+Q), then run this script again."
    exit 1
fi

if [ ! -f "$STATE" ]; then
    echo "❌ Chrome config not found: $STATE"
    exit 1
fi

# Chrome recomputes these on every run, so re-assert them before each launch.
sed -i '' -e 's/"is_glic_eligible":false/"is_glic_eligible":true/g' \
           -e 's/"variations_country":"[^"]*"/"variations_country":"us"/' \
           -e 's/\("variations_permanent_consistency_country":\[[^]]*\)"[^"]*"\]/\1"us"]/' \
           "$STATE"

python3 -c "import json; json.load(open('$STATE'))" \
    && echo "✓ Config patched (JSON valid)" \
    || { echo "❌ Local State is not valid JSON after patching — restore from Local State.bak"; exit 1; }

echo "🚀 Launching Chrome with Gemini (Glic) enabled..."
open -a "Google Chrome" --args --variations-override-country=us --enable-features=Glic

echo ""
echo "✓ Done. Wait 1-2 minutes for the seed to load, then look for the Gemini"
echo "  icon in the toolbar. Keep this flag on every launch until your proxy"
echo "  routes clientservices.googleapis.com through the VPN."
