# Changelog

## 1.6.4

A spell with no power cost no longer stops the mana highlight.

### Fixed

- A spell whose power cost is missing is ignored, so the highlight does not error.

## 1.6.3

The description names the player mana bar.

### Changed

- The highlight is described as drawing on the player mana bar, including a custom resource bar when one is present.
- The minimap button tooltip says the button opens settings.

## 1.6.2

The highlight checks your power type when it changes, and only the width moves while the five seconds run down.

### Changed

- Mana versus another power type is read on `UNIT_DISPLAYPOWER` and when you enter the world.
- The highlight keeps its anchors and updates its width each frame.

## 1.6.1

The login line shows the addon name and version. The Joipov name color is a brighter violet.

### Changed

- The login line reads Joipov <name> (v<version>). The name and version come from the TOC, so they never drift. The version is a different color.
- Joipov is now a saturated violet.

## 1.6.0

House-style pass. Same highlight, cleaner internals.

### Changed

- Wand shots and auto-repeat are detected through `C_Spell.IsAutoRepeatSpell` instead of spell names, so the check works on every locale.
- The minimap position is stored in LibDBIcon's own table, so dragging the button with LibDBIcon keeps its place, and the built-in button uses the same value.
- The addon loads only on the `forever` game type.
- Modules export only what another file reads.

### Removed

- The unused `ns.TryAttach`, `ns.StartOrReset`, `ns.StopOverlay`, `ns.IsActive`, and `ns.ApplyAppearance` exports.

## 1.5.7

Settings use the same wording as the other Joipov addons.

### Changed

- **Enable Five Second Overlay**, **Minimap button**, **Highlight opacity**, **Edge gap**, and **Highlight color** use the shared labels.
- The other rows grey out while the addon is off.

## 1.5.6

The minimap button is on by default, including saves that still had it off.

### Changed

- **Minimap Button** sits under Enable and starts on. Click opens settings.
- The button uses LibDBIcon when that library is loaded, and the same frame name when it is not, so the default minimap and the addon compartment can show it.

## 1.5.5

Five Second Overlay loads on its own. Chat lines no longer go through another addon. The highlight is unchanged.

### Changed

- Chat lines are printed by this addon. One login line tells you `/fso`.
- The addon list groups this under Joipov Tools. The list name has no Joipov prefix.

## 1.5.4

Subtle 5-second rule highlight on the player mana bar. Saved settings are stored the same way as the other Joipov addons, and the addon compartment opens settings. The highlight is unchanged.

### Changed

- SavedVariables are assigned on `_G.FiveSecondOverlayDB`.
- The addon compartment button opens settings.
