<!-- 1.4.0 audit remediation, 2026-09-26. Forever / camelot, Interface 16001. -->

# FiveSecondOverlay audit (1.4.0 → remediation)

Target: World of Warcraft Forever, game type `camelot`, `## Interface: 16001`. Lua 5.1.

This document is the audit report plus the remediation record. Production fixes for Phases 1–3 are implemented in the same change set that added this file. Phase 4 is an in-game checklist (no client session was available here).

## Coverage

Read in full at audit time: `FiveSecondOverlay.toc`, `Core.lua`, `Options.lua`, `MinimapButton.lua`.

External references: GatherSkillTooltip / HealPerMana patterns on this client; Warcraft Wiki spellcast events.

## Part 1 — Executive summary

Small, appropriately scoped addon. Main gaps found: SavedVariables table sharing with defaults (CQ-001), per-frame host resolve / text work (PERF-001/002), missing DB versioning and lint tooling, dead RGB SV keys and a no-op combat event.

## Part 2 — Findings register

### CQ-001 — Defaults `minimapIcon` table shared with SavedVariables

- Severity: High
- Status: **Fixed** — `Database.lua` deep-copies tables; `minimapIcon` is always a fresh `{}`
- Location: was `Core.lua` defaults copy loop

### CQ-002 — Secret spell costs silently skip FSR

- Severity: Medium (Forever)
- Status: **Documented, unchanged** — keep `SpellCostsMana == true` only (wand safety). Do not treat `nil` as spend.
- Verification: in-combat mana cast must arm highlight; if not, enable a one-shot debug of cost readability

### CQ-003 — Brittle `a == 0.22` migration

- Severity: Low
- Status: **Fixed** — `db.version` migrations in `Database.lua`

### CQ-004 — RGB in DB with no settings UI

- Severity: Low
- Status: **Fixed** — highlight color hardcoded (`HIGHLIGHT_R/G/B`); `r`/`g`/`b` stripped on migrate

### CQ-005 — Empty `PLAYER_REGEN_DISABLED` handler

- Severity: Low
- Status: **Fixed** — event removed

### PERF-001 — Host resolve every OnUpdate

- Severity: Medium–High while active
- Status: **Fixed** — host rechecked on a 0.5s throttle or when missing/hidden

### PERF-002 — Regen text re-anchored every frame

- Severity: Medium
- Status: **Fixed** — points set once; `SetText` only when displayed tenth changes

### PERF-003 / PERF-004 — Broad ADDON_LOADED / PEW attach spam

- Severity: Low–Medium
- Status: **Fixed** — foreign ADDON_LOADED ignored after successful attach; PEW skips retries when host already usable

### ARCH-001 — No SV schema validation

- Status: **Fixed** — `Database.lua`

### ARCH-002 — `ns._OnUpdate`

- Status: **Fixed** — local `OnUpdate` closed over by `UpdateDriverScript`

### TOOL-001 — No luacheck / luarc

- Status: **Fixed** — `.luacheckrc`, `.luarc.json` added

### SEC-001 — Namespace / taint

- Status: OK — no change required

## Part 3 — Remediation roadmap (executed)

| Phase | Work | Result |
|-------|------|--------|
| 0 | Write this file | Done |
| 1 | SV deep-copy, version, RGB hardcode, drop dead event | Done |
| 2 | OnUpdate host/text perf | Done |
| 3 | Database.lua + luacheck/luarc | Done |
| 4 | In-game checklist | Below (manual) |

## Part 4 — Performance notes

No live profiling numbers. Expected wins: fewer `_G` probes and layout calls while FSR/regen run. Confirm with script profiling in-client if needed.

## Part 5 — Coding standards (this repo)

- Lua 5.1; `local` by default; one `ns` from `...`
- Deep-copy tables into SavedVariables; versioned migrations only
- OnUpdate only while FSR or regen active
- Forever: never compare secret values; mana cost must be confirmed `true`
- `/fso` opens settings only

## Part 6 — In-game verification checklist (Phase 4)

Run after `/reload` with EllesmereUI Resource Bars enabled:

- [ ] Mana cast **finish** starts the highlight; **interrupt** does not
- [ ] Instant mana spend starts highlight; wand Shoot does not
- [ ] Channel start (if applicable) starts highlight
- [ ] After 5s in combat, regen timer appears and counts up
- [ ] Next mana spend freezes timer; leave combat freezes timer
- [ ] Timer value remains until next regen window
- [ ] Highlight attaches to `ERB_PrimaryBar`
- [ ] Minimap button on by default; turning it off in settings hides it; click opens settings; drag repositions
- [ ] `/fso` opens Settings category
- [ ] Disable overlay in settings hides highlight and stops regen updates
- [ ] Optional: `assert(FiveSecondOverlayDB.minimapIcon ~= nil)` and that it is not the defaults table after drag

## CQ-002 follow-up (only if highlight never arms in combat)

If Forever secrets all power costs in combat, add a guarded debug print of `SpellCostsMana` results — do not blindly treat `nil` as a spend.

## 1.5.4 alignment

SavedVariables are assigned on `_G.FiveSecondOverlayDB`. The addon compartment opens settings. The highlight is unchanged.

Checked with luacheck (Lua 5.1, explicit globals). SavedVariables, slash commands, the compartment callback, and the named highlight and minimap frames are the globals this addon writes.

`assets/` is release media for CurseForge and Wago. It is not loaded by the TOC, not shipped in the zip, and not part of this audit.
