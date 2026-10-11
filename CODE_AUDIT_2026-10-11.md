# Five Second Overlay audit — 2026-10-11

Target: World of Warcraft Forever, game type `forever` (was `camelot`), `## Interface: 16001`, Lua 5.1.
References: the Atraeau Forever API dump (build 70170), Warcraft Wiki (Patch 1.60.1 API changes, Patch 12.0.0 secret values), Ketho's vscode-wow-api annotations, and the sibling Joipov addons.

Scope: every `.lua`, the `.toc`, `tests/run.lua`, and the docs. `assets/`, `.release/`, and `.annotations/` are not addon code.

## Findings and what was done

### CQ-001 — Defaults table shared with SavedVariables
`minimapIcon` was always rebuilt fresh, so no shared reference. **Kept and made explicit** in `EnsureTables`.

### CQ-002 — Secret mana cost skips the highlight
A cast whose cost cannot be read (`nil`) is not treated as a spend. **Kept** — do not treat `nil` as a spend (wand safety). Verified against the secret-value rules.

### CQ-003 — Old global `IsAutoRepeatSpell` is gone on Forever
`Core.lua` used `IsAutoRepeatSpell` (removed) and a localized list of the name "Shoot". **Fixed** — `C_Spell.IsAutoRepeatSpell` exists and is used instead; the name list is gone.

### CQ-004 — Wand safety relied on localized spell names
Removed with CQ-003. No locale strings are needed.

### CQ-005 — Minimap position in two places
`db.minimapAngle` (our key) and `db.minimapIcon.minimapPos` (LibDBIcon's) could disagree, and a LibDBIcon drag was lost. **Fixed** — one key, `minimapIcon.minimapPos`, with a migration. No default-angle duplication.

### ARCH-001 — Unused `ns` exports
`ns.TryAttach`, `ns.StartOrReset`, `ns.StopOverlay`, `ns.IsActive`, `ns.ApplyAppearance` are used by no other file. **Fixed** — removed; the functions are file-local.

### ARCH-002 — Redundant nil checks
`FrameUsable` returned `width and width > 1`; `ApplyAppearance` read `db and db.r or 1` when `db` is always present. **Fixed** — trimmed.

### TOOL-001 — luacheck / LuaLS
`.luacheckrc` listed a removed global and unused reads. **Fixed** — both configs match the code; luacheck, LuaLS, and `tests/run.lua` pass clean.

### TOC-001 — Game type
`## AllowLoadGameType: camelot` predates the `forever` game type. **Updated** to `forever` plus `## ExcludeLoadGameType: standard, classic`. If the current beta build predates 70291, revert to `camelot`; the in-game checklist covers this.

## Verification

- `luacheck .` — clean.
- `luajit tests/run.lua` — 9 passed.
- LuaLS with Ketho's annotations — clean.

## In-game checklist

- Mana cast **finish** starts the highlight; **interrupt** does not.
- Instant mana spend starts the highlight; wand Shoot does not.
- Channel start starts the highlight.
- The highlight is gone after 5 seconds.
- The addon loads (`/dump C_AddOns.IsAddOnLoaded("FiveSecondOverlay")`).
- Minimap button on by default; the settings toggle hides it; dragging keeps its place after `/reload`.
- `/fso` and the addon compartment open the settings category.
- Disabling the addon hides the highlight.
