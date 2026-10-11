# Five Second Overlay

A faint highlight on your mana bar for the five seconds after a mana spell. The bar shrinks from the right toward the left, then clears.

Target client: World of Warcraft **Forever** (`## Interface: 16001`).

## Features

- Starts when a mana spell finishes, or when a channel begins. A cast that is still winding up does not start it. Wand shots and auto-repeat do not start it.
- Draws on EllesmereUI Resource Bars when that bar is present, then the Ellesmere unit-frame power bar, then the default player mana bar.
- White by default, slightly transparent, inset so it stays off the border.
- Minimap launcher via LibDBIcon when present, otherwise a built-in button. On by default. The addon compartment and `/fso` open settings.

## Commands

| Command | Effect |
| --- | --- |
| `/fso`, `/fivesecond` | Open the settings panel |

## Files

Loaded in TOC order; modules communicate only through the shared `ns` table.

| File | Concern |
| --- | --- |
| `Database.lua` | SavedVariables defaults, migrations, validation |
| `Core.lua` | Host bar, mana-spend check, highlight |
| `MinimapButton.lua` | LibDBIcon launcher or built-in button, addon compartment |
| `Options.lua` | Settings panel, slash commands |

## Development

The repository lives outside the game folder; the AddOns entry is a
directory junction to it:

```
mklink /J "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\FiveSecondOverlay" "D:\Repos\Joipov\FiveSecondOverlay"
```

Static checks (no game client needed):

```
luacheck .            # .luacheckrc: Lua 5.1, explicit WoW globals
luajit tests/run.lua  # or: lua5.1 tests/run.lua
```

LuaLS uses `.luarc.json` and Ketho's WoW API annotations. The repo-local
`.annotations/` folder declares the Forever secret-value helpers those
annotations lack.

`assets/` is release media for CurseForge and Wago (screenshots, and a logo
when one exists). The game does not load it, and it is not part of the addon
zip. Do not delete it during cleanup.

Local zip, with the addon folder at the root, written to `.release/`:

```
powershell -File package.ps1
```

Releases: push an annotated tag (`git tag -a 1.6.0 -m "1.6.0"`). The
`Package and release` workflow runs BigWigsMods/packager, which reads the game
version from the TOC and the manual changelog from `CHANGELOG.md`.
The audit note is not shipped.
