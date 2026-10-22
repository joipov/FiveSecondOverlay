# Five Second Overlay audit

Target: World of Warcraft Forever, `## Interface: 16001` (client 1.60.1.70425), Lua 5.1.
Host addons checked at their 2026-10-19 builds: EllesmereUIResourceBars and
EllesmereUIUnitFrames 9.6.1, in both `_classic_beta_` and `_retail_`.

This note is for development. It is not shipped in the addon zip.

## Host check (no breakage)

Every host surface this addon touches still exists with a stable identity
across Ellesmere layout reloads: `ERB_PrimaryBar` and its `_sb` fill,
`RaiseBorderAbove(coverLevel, behind)`, and
`EllesmereUIUnitFrames_Player.Power`. `ResolveHostBar` order stands.
Ellesmere's own mana-regen spark and spell-cost prediction attach at
neighbouring frame levels and do not clash; they were not copied.

## What changed in 1.6.5

- `SpellCostsMana`: the power-cost list is read as one guarded call. A
  secret amount with a readable mana type counts as a spend — the amount
  cannot be told apart from a plain 0, but the resource is proven, so the
  highlight arms in combat instead of never starting there. A secret amount
  with an unreadable type stays unknown. Costs are never compared while
  secret (the type is checked before the comparison).
- `Layout` branches on `GetOrientation()`: on an upright resource bar the
  highlight shrinks along the height. Orientation is read once per layout
  and re-placed only when it changes.
- `FrameUsable` rejects a host bar at zero effective alpha (Ellesmere
  builds its primary bar for specs with no primary power and leaves it at
  zero alpha), so it falls through to the next host.
- The Minimap button row stays active while the addon is off, and its
  settings rows now take defaults from `ns.defaults`.

## Still holds

- The highlight works on the stock player mana bar with no host addon, and
  `OnUpdate` runs only while the highlight is active.
- Build 70425 reorganised the player frame (Warcraft Wiki, Patch 1.60.1
  notes); the `PlayerFrameManaBar` / `player.manabar` / `player.ManaBar`
  fallback chain is the surface to re-check first if the stock bar moves.

## Checked in the client (manual pass, 1.6.5)

- [ ] Cast a mana spell in combat — the highlight starts and shrinks.
- [ ] With an upright Ellesmere resource bar, the highlight shrinks
      vertically. With a spec that has no primary power, it does not
      attach to the invisible Ellesmere bar.
- [ ] Without Ellesmere: the stock mana bar still carries the highlight.
