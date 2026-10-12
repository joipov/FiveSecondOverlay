# Five Second Overlay audit — 2026-10-12

Target: World of Warcraft Forever, `## Interface: 16001`, Lua 5.1.
References: Ketho's vscode-wow-api annotations, the Forever API, and the other Joipov addons.

## Already in good shape

`C_Spell.IsAutoRepeatSpell`, secret mana costs, and the single minimap position key from the 2026-10-11 pass still hold. The highlight's `OnUpdate` runs only while the five-second rule is active.

## This pass

- Mana versus another power type is read on `UNIT_DISPLAYPOWER` and when entering the world. The frame loop uses that flag.
- Anchors are set when the host or the edge gap changes. Each frame updates the width.
- `ns.Debug` matches the other addons and stays silent unless `db.debug` is on.
- Compartment and highlight frame names are listed for luacheck and LuaLS. Tests have the same `files["tests/"]` block as the other addons.
- TOC fields follow the house order.
- Ketho's annotation path stays in `.luarc.json`. That file is the library list LuaLS uses for this addon.
