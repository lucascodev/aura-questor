# Development

**English** | [Português](pt-BR/desenvolvimento.md)

## Setting up

```sh
git clone <repo>
cd aura-questor
```

`Libs/` **is not in the repository**. The seven libraries are fetched from the
source declared in [`.pkgmeta`](../.pkgmeta) at release time, so a clean clone
does not run in the game until you bring them in:

```sh
# with the packager installed
release.sh -d -z
```

Or download the seven manually into `Libs/`, once. After that they stay on disk
and are ignored by git.

To develop with the game open, create two junctions (they do not need
administrator rights) in `World of Warcraft\_retail_\Interface\AddOns\`:
`AuraQuestor` pointing to the project folder and `AuraTrackerQuestor` pointing
to `Bridge\AuraTrackerQuestor` inside it. The game only loads
`<Folder>\<Folder>.toc`, so the name of each junction must match the manifest
it contains.

## Testing

```sh
lua Tests/Run.lua              # every suite
lua Tests/Run.lua Tracker      # only the ones in Tests/Core/Tracker/
```

Tests cover `Core/`, in pure Lua, with no dependencies. The harness loads
`Locales/`, `Source/Core/` and two pure files from `Source/Options/Components/`
(Theme and Schematic, which do not touch the game API) in the same order as the
`.toc` and simulates the vararg the game passes to each file. It returns exit
code 1 if any test fails.

`Tests/` mirrors the inside of `Source/`: each suite sits at the path matching
the module it exercises. Shared fakes and builders live in
[`Tests/Support.lua`](../Tests/Support.lua); loading and assertions, in
[`Tests/Harness.lua`](../Tests/Harness.lua).

Covered: filters, sorting, section assembly, completion detection, colors,
profiles, preferences, achievement categories and consistency between the
locale files.

Not covered: anything that accesses the game API or creates frames, which can
only be verified in the client.

## Linting

```sh
luacheck .
```

The configuration is in [`.luacheckrc`](../.luacheckrc), with the game's 106
globals declared as read-only and the 7 that the addon writes kept separate. It
runs in CI on every push.

## Packaging

```powershell
.\build.ps1
```

Produces `dist\AuraQuestor-<version>.zip` with two folders at the root:
`AuraQuestor`, the addon, and `AuraTrackerQuestor`, the bridge with the old
name (the same layout that `.pkgmeta`'s `move-folders` gives the release zip).
The script validates the `.toc` **in both directions**:

- a listed file that was not packaged, which would fail in the player's client
  without pointing to the cause
- a packaged file that is not listed, which never loads and gives the
  impression that the feature was not implemented

`Ports/`, `Tests/` and `docs/` are left out of the package: the first contains
only type annotations, the other two are not loaded by the game.

## Publishing

```sh
git tag v0.72.0
git push --tags
```

The tag triggers [`release.yml`](../.github/workflows/release.yml), which runs
the BigWigs packager: it fetches the libraries, applies the `.pkgmeta`, builds
the zip and publishes it to GitHub Releases and CurseForge.

Each storefront needs two things, an identifier in the `.toc` and a token in the
repository secrets:

| Storefront | `.toc` | Secret |
| --- | --- | --- |
| CurseForge | `## X-Curse-Project-ID` | `CF_API_KEY` |

If either one is missing, the packager skips that storefront and carries on:
the release does not fail, and the zip is still published on GitHub. That is
what makes it possible to add a new storefront without stopping releases while
it is not ready.

## Conventions

**Commits** in [Conventional Commits](https://www.conventionalcommits.org/), in
Portuguese, as the history already does: `feat:`, `fix:`, `refactor:`, `test:`,
`build:`, `chore:`, `style:`.

**Comments** explain the decision, not what the line does. A block that needs a
comment to be understood should usually be extracted into a function with a
descriptive name. Code in English; player-visible text in `Locales/`.

**Indentation** with tabs, per [`.editorconfig`](../.editorconfig). Line
endings normalized to LF by [`.gitattributes`](../.gitattributes).

**Text** is never hard-coded. A new key goes into `Locales/enUS.lua` **and**
into `ptBR.lua`. There is a test that fails if either one is missing, or if the
`%s` count differs between them.

## Version

The version is declared in a single place, the `## Version:` in the `.toc`.
`build.ps1` uses that value to name the zip, and `AddonMetadata` reads it to
display in the options and in `/atq status`.
