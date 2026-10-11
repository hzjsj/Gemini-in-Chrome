# Gemini in Chrome

One-click script to enable Chrome's built-in Gemini AI features for non-US users.

## Quick Start

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/appsail/Gemini-in-Chrome/main/install.sh | bash
```

### Windows

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/appsail/Gemini-in-Chrome/main/install.ps1 | iex
```

## What It Does

1. ✅ Checks if Chrome is running (prompts you to close it)
2. 💾 Backs up your config (`Local State.bak`)
3. 🔧 Patches these settings:
   - `is_glic_eligible`: `false` → `true`
   - `variations_country`: → `us`
   - `variations_permanent_consistency_country`: → `us`
4. ✓ Verifies changes were applied

## macOS Daily Use

The patch is not sticky: Chrome recomputes Glic eligibility at every startup, and the country override is per-launch. Quit Chrome (Cmd+Q), then start it with:

```bash
bash launch-glic.sh
```

If the sidebar says the feature is not available in your region, check your proxy node first:

```bash
bash check-region.sh   # switch node and re-run until it looks good
```

## Scripts

| Script | What it does |
|--------|--------------|
| `install.sh` / `install.ps1` | One-time patch of the 3 fields in `Local State` |
| `launch-glic.sh` | macOS daily launcher: re-asserts the patch and relaunches Chrome with `--variations-override-country=us --enable-features=Glic` |
| `check-region.sh` | Probes which region Google's geo services see for your proxy exit (rough pre-filter) |

## Troubleshooting

Gemini in Chrome (Glic) sits behind several gates — all must pass:

1. **Client eligibility** — `is_glic_eligible` (one entry per profile), `variations_country` and `variations_permanent_consistency_country` in `Local State`. `install.sh` patches them; Chrome recomputes them at every startup, so patching alone does not stick.
2. **Finch study filtering** — the seed itself is country-agnostic; Chrome filters studies client-side by country. `launch-glic.sh` forces `us` via `--variations-override-country=us`.
3. **Server-side region check** — the Gemini backend geo-checks your exit IP using Google's own geo database, which often disagrees with ipinfo/MaxMind: exits on China-carrier international ranges (CTG/CMI/CN2 — typical of 中转/IEPL nodes) look like "US" on ipinfo but behave as CN for Google. Symptom: the sidebar opens but shows "not launched in your region". Fix: switch to a native-IP node, relaunch via `launch-glic.sh`, and give it a minute or two.
4. **Sign-in** — a signed-in Google account is required. (Chinese UI is fine on recent Chrome.)

## Restore Original Config

**macOS:**
```bash
mv ~/Library/Application\ Support/Google/Chrome/Local\ State.bak \
   ~/Library/Application\ Support/Google/Chrome/Local\ State
```

**Linux:**
```bash
mv ~/.config/google-chrome/Local\ State.bak \
   ~/.config/google-chrome/Local\ State
```

**Windows PowerShell:**
```powershell
Move-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State.bak" `
          -Destination "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State" -Force
```

## Safety

- Original config is backed up before any changes
- Only modifies local Chrome settings
- No data uploaded, no network access (except downloading the script)
- Easily reversible
- Unofficial, open source, use at your own risk

## Config Paths

| OS | Path |
|----|------|
| macOS | `~/Library/Application Support/Google/Chrome/Local State` |
| Linux | `~/.config/google-chrome/Local State` |
| Windows | `%LOCALAPPDATA%\Google\Chrome\User Data\Local State` |

## Issues

Found a bug? [Open an issue](https://github.com/appsail/Gemini-in-Chrome/issues).

## License

MIT
