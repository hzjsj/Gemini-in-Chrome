# AGENTS.md

## What this repo is

One-click enabler scripts for Chrome's built-in Gemini sidebar (Glic) for non-US users. No app code — just two shell scripts plus a README. There is nothing to build, typecheck, lint, or test; verify changes by running the script against a real Chrome profile (with Chrome fully quit) or by dry-reading the regexes.

## Files

- `install.sh` — macOS/Linux enabler (bash, `set -e`, interactive)
- `install.ps1` — Windows enabler (PowerShell, must stay Windows PowerShell 5 compatible)
- `README.md` — user-facing docs **in Chinese**: install commands (incl. jsDelivr mirrors), daily use, restore commands, troubleshooting, per-OS config paths. Keep it Chinese when editing.

## How the patch works

The target is Chrome's `Local State` JSON file (paths per OS are in the README). Three fields are patched in place via text substitution:

- `"is_glic_eligible": false` → `true`
- `"variations_country": "<any>"` → `"us"`
- last string element of the `"variations_permanent_consistency_country": [...]` array → `"us"`

## Rules that matter when editing

- **Never patch while Chrome is running** — Chrome overwrites `Local State` on exit, silently undoing the change. Both scripts check first (`pgrep -x`, `Get-Process`) and must keep doing so.
- **Always back up** `Local State` → `Local State.bak` before writing (`*.bak` is gitignored).
- **sed portability**: macOS uses BSD sed (`sed -i '' -e ...`), Linux needs GNU sed (`sed -i -e ...`). The script branches on `uname -s`; preserve both arms.
- **PowerShell must write UTF-8 without BOM** (`System.Text.UTF8Encoding $false`) — Chrome rejects a file with a BOM.
- Substitutions assume Chrome may serialize JSON compactly (no space after `:`) — keep regexes tolerant of optional whitespace, as the current ones are.
- The verification step greps the patched file and counts failures; keep it in sync with any field changes.

## Gotchas (learned from a real enable attempt, 2026-10)

- `is_glic_eligible` appears **once per profile**, inside `profile.info_cache` in Local State — patch all occurrences, not just the first.
- Chrome **recomputes `is_glic_eligible` at startup** from the finch seed's country and writes it back. The field does not stick until Chrome has fetched a **US finch seed** — patching alone is not enough; the user must relaunch with Google reachable and the seed refetched.
- Finch seed payloads live in separate files next to `Local State`: `VariationsSeedV2` and `VariationsSafeSeedV2`. To force a refetch under the patched country, move those files aside and zero `variations_last_fetch_time` / `variations_seed_date` in Local State.
- The top-level `Variations` file in the Chrome data dir is a clean-exit metrics marker, not seed data.
- Chrome may write the timestamp prefs (`variations_last_fetch_time`, `variations_seed_date`) as **quoted strings, not integers** (observed alternating between runs). A bare `[0-9]*` zeroing regex then leaves the closing quote and corrupts Local State — include the quotes in the pattern (`":0"[0-9]*"` → `":0"`) and always re-validate the JSON after editing.
- Glic also gates on being signed into a Google account and possibly on the Chrome UI language (user's UI was zh-CN — switch to English in chrome://settings/languages if it still won't show).
- **The finch seed is country-agnostic; Chrome filters studies client-side by the stored variations country.** So the clean fix for a CN-proxied machine is launching Chrome with `--variations-override-country=us --enable-features=Glic` (switch confirmed present in Chrome 154 stable). The flag is per-launch.
- **Proxy rule sets typically route `clientservices.googleapis.com` DIRECT** (verified: response header `x-country: cn` even with the VPN exit in the US — ipinfo showed US but the seed server geo-saw the real CN IP). Each successful direct fetch overwrites `variations_country` back to `cn`, which is why the override flag is needed on every launch unless the user adds a proxy rule for that domain.
- `launch-glic.sh` re-asserts the Local State fields (JSON-validated) and relaunches Chrome with the override flags — the user's daily launcher.
- **Deepest gate (found last): the Gemini backend's own geo verdict.** The user's first "US" node exited via CTG Server (China Telecom Global) — ipinfo says US, but Google geo systems treated it as CN: `https://www.google.com/` 302-redirects to `google.com.hk`, seed server returned `x-country: cn`, and the panel showed the server-driven "not launched in your region" string (which is NOT in Chrome's locale paks). Switching to a native-IP exit (ByteVirt SG) fixed it even though the seed server *still* reports `x-country: cn` for it — **the variations geo, google.com redirect geo, and the Gemini backend geo are different systems that disagree**. `check-region.sh` (google.com redirect + x-country probes) is a correlated pre-filter, not an authoritative verdict: ✅ basically means usable, ❌ does not necessarily block. Working combo as of 2026-10-11: `launch-glic.sh` + ByteVirt SG native-IP node + signed-in account + zh-CN UI (no language gate on Chrome 154).

## Scripting gotchas

- `install.sh` uses `set -e` plus a `read -p` prompt: it is interactive. When piped (README suggests `curl | bash`), `read` consumes the *remaining script lines* as its input, skipping the Chrome-running check and any code after it.
- `((errors++))` is guarded with `|| true` because with `set -e` a post-increment from 0 returns exit status 1 and would abort the script.
- Install URLs point at `hzjsj/Gemini-in-Chrome` everywhere (README + install.sh, fixed 2026-10-11). `install.sh` prompts read from `/dev/tty` so `curl | bash` no longer swallows the rest of the script.
- Verification only checks 2 of the 3 patched fields (`variations_permanent_consistency_country` is not re-grepped).

## Local user environment (for testing)

- macOS; Chrome 154.0.8037.98; config at `~/Library/Application Support/Google/Chrome/Local State`; unpatched fields are `is_glic_eligible: false` and `variations_country: "cn"`.
- After patching, the user must fully restart Chrome; the Gemini icon then appears in the toolbar. Using Gemini still requires access to Google services.
