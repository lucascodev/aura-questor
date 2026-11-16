# Aura Questor: Objective Tracker

**English** | [Português](README.pt-BR.md)

A standalone objective tracker for World of Warcraft: a tracker for quests,
achievements, professions and scenarios, built on the game's public APIs. In
English, Portuguese, Spanish and French.

It doesn't dress up Blizzard's tracker: it draws its own, reading the same data
the game exposes. That's the difference that lets an addon survive a patch: the
data surface changes far less than the interface does.

## What it shows

Quests, Campaign, World Quests, Bonus Objectives, Achievements, Professions,
Traveler's Log, Collections, Endeavors and Scenario, including
keystone level, affixes and deaths in Mythic+.

Plus a section Blizzard's tracker doesn't have: **World events**, with the zone
and the time left.

## Features

- Filters by zone, campaign, dailies, dungeon, finished, and by quest log
  grouping
- Sorting by level, grouping or title
- Collapsible sections, with their state kept between sessions
- Settings profiles, one active per character
- Scrolling, free dragging, and adjustable width, height and space between
  sections and entries
- Font, size, outline and shadow, picked from the fonts your addons register
- Background and border with a texture from the shared media library, colour,
  thickness, opacity and inset, or your class colour on the border
- Each header button, and the minimap button, can be turned off one by one
- Tooltip with the quest description and the rewards, with icons
- Minimap button and key bindings

## Installation

Extract the zip into `World of Warcraft\_retail_\Interface\AddOns\`. It holds
two folders: `AuraQuestor`, the addon, and `AuraTrackerQuestor`, a bridge with
just the manifest that keeps the settings saved under the old name loaded until
the addon picks them up. If you already used Aura Tracker Questor, leave the
bridge enabled on your first login and you won't lose a thing; after that it
can be removed.

In game, `/atq` opens the options and `/atq help` lists the commands.

## Development

The code follows Clean Architecture, with the dependency rule pointing
inwards:

| Folder | Responsibility |
|---|---|
| `Locales/` | text, `enUS.lua` as the default and the translations on top |
| `Source/Core/` | rules in pure Lua: `Preferences/`, `Filtering/`, `Tracker/`, `Commands/`. **No WoW API** |
| `Source/Ports/` | type contracts, read by the language server and left out of the package |
| `Source/Game/` | reads the game API and draws nothing: `Objectives/`, `Quest/`, `Achievement/` |
| `Source/Modules/` | one folder per content type: what it collects and what its entries do |
| `Source/UI/` | frames: `Entry/` draws an entry, `Tracker/` the panel, `Header/` the buttons at the top |
| `Source/Options/` | options pages and the `Components/` kit |
| `Source/System/` | chat, commands, events, sound and shared media |
| `Source/Bootstrap.lua` | composition root, the only place that knows the implementations |

```sh
lua Tests/Run.lua     # the Core tests, without opening the game
luacheck .            # static analysis
.\build.ps1           # builds dist\AuraQuestor-<version>.zip
```

`Libs/` is not in the repository: the packager fetches the libraries from the
source declared in `.pkgmeta`. A clean clone won't run in the game until you
bring them in.

The full documentation lives in **[docs/](docs/)**:

| | |
|---|---|
| [Architecture](docs/architecture.md) | the layers and the dependency rule |
| [Execution flow](docs/flow.md) | initialization, update cycle and combat |
| [Adding content](docs/adding-content.md) | implementing a new content type |
| [WoW constraints](docs/constraints.md) | taint, combat and API limits |
| [Development](docs/development.md) | environment, tests, packaging and publishing |

## License

MIT. The libraries in `Libs/` belong to their authors and keep their own
licenses.
