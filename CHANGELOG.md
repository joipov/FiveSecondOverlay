# Changelog

## 1.5.6

The minimap button is on by default, including saves that still had it off.

### Changed

- **Minimap Button** sits under Enable and starts on. Click opens settings.
- The button uses LibDBIcon when that library is loaded, and the same frame name when it is not, so the default minimap, the addon compartment, Ellesmere, and ElvUI can all show it.

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
