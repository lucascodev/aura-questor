# WoW constraints

**English** | [Português](pt-BR/restricoes.md)

API limitations that have already caused problems in this project or in
well-known addons. Recommended reading before changing any frame.

## Taint and secret values

The game separates **clean** execution (Blizzard code) from **tainted**
execution (addon code). When an addon touches a protected frame, the taint
spreads, and the action is blocked.

Since 12.0 this has become stricter with *secret values*: certain reads return
values that can only be used in clean execution, and using them outside it
raises the error `Secret values are only allowed during untainted execution`.

### Hiding Blizzard's tracker

There is only one safe way:

```lua
frame:SetAlpha(0)
frame:EnableMouse(false)
```

**Never** `Hide()`, `SetScale()` or `SetPoint()` on it. That was the mistake
that broke another tracker addon in 12.1, and `Hide()` on a frame with a
protected child is blocked in combat. See
[`Game/BlizzardTracker.lua`](../Source/Game/BlizzardTracker.lua).

## Protected frames and combat

`SecureActionButtonTemplate` makes **every frame above it** protected. A quest
item button inside a block protects the block, the content and the panel.

Consequences observed in this project:

- creating the buttons ahead of time produced **116 `ADDON BLOCKED` errors** at
  once
- in combat it is not possible to move, resize or hide anything above them

**Adopted solution: the button does not live inside the block.** It is a child
of its own frame, `AuraQuestorItemButtons`, hung from `UIParent`, and only
*anchored* to the block. An anchor protects no one: above the button there is
only the screen, so the panel never becomes protected and **redraws normally in
combat**, even changing state in the middle of a scenario.

Before this design, a single quest with an item froze the whole list until the
fight was over. It was the addon's biggest limitation and it did not need to
exist.

What still holds, because it is a rule of the game:

- **a secure button's attributes do not change in combat**, so the button keeps
  pointing at the item that was already armed
- **creating, moving, showing or hiding** the button is blocked in combat. A new
  button waits for `PLAYER_REGEN_ENABLED`; one that needs to leave the scene
  goes to alpha zero, which is not protected, and is truly hidden on the next
  refresh

The frame clips whatever extends past it (`SetClipsChildren`), because, living
outside the panel, the button is no longer cut off by the scrolling.

## Taint on the map: a known error with no fix

Opening a quest's details from an addon, via
`QuestMapFrame_OpenToQuestDetails`, runs the map's whole machinery in an
insecure context, and every variable it writes during that pass becomes
tainted. When the game itself goes back through those variables later, in
combat, the pins' protected calls (`SetPassThroughButtons`,
`SetPropagateMouseClicks`) are blocked, and `ADDON_ACTION_BLOCKED` blames
whoever tainted first: this addon.

The signature in BugSack is a stack that starts with a click (on our panel or on
Blizzard's tracker, when both are on), goes through
`QuestMapFrame_OpenToQuestDetails` and dies in `CheckMouseButtonPassthrough` in
the map's providers.

There is no taint-free way for an addon to open quest details; every
third-party tracker carries this same error. The real effect is only that the
pins' click-through flag stays stale until the end of combat; no functionality
is lost.

What can be done is to shrink the window: the map's display mode is only
written when it actually changes (`MapNavigator.Open`), because rewriting the
value already there would taint the field that Blizzard's map shortcut reads on
every press of M. When Blizzard itself rewrites the field, the taint goes away
until we touch it again.

In the same family: writing the super tracking (`C_SuperTrack`) in combat
immediately triggers the refresh of the map pins in a tainted context, and each
pin's `SetPassThroughButtons` is blocked. That is why `SuperTracking` defers the
write until the end of combat; only the last request counts.

Opening the options panel (`Settings.OpenToCategory`) has also been protected in
combat since 12.x. `OptionsPanel` warns in chat and does not try.

## Widgets in the tooltip: never `GameTooltip_AddWidgetSet`

`GameTooltip` keeps **a single** widget container for the whole interface,
created on the first call to `GameTooltip_AddWidgetSet` and rewritten on every
call. Called by an addon, the function creates and writes that container in
tainted execution, and the taint stays on it until `/reload`.

Later the world map draws a point of interest's tooltip through the same
container. Blizzard's execution becomes tainted, `GetStringHeight()` starts
returning a secret number and the text widget's `Clamp` blows up, with this
addon's name on it (issue #68). The stack does not go through our code: it
starts in `AreaPOIDataProvider` and dies in
`Blizzard_UIWidgetTemplateTextWithState`.

A `pcall` around the call does not fix it. It swallows the error in our tooltip,
but the taint is already on the container, and the error comes back in the
map's.

**Adopted solution:** [`WidgetTextReader`](../Source/Game/WidgetTextReader.lua)
reads the widgets' text through `C_UIWidgetManager` and the tooltip adds them as
plain lines. No Blizzard frame is touched and nothing is measured. Purely visual
widgets, such as a bar or an icon without text, are left out of our tooltip; in
the map's they still show.

## The addon's name is its identity

The client stores player data by the addon's folder name, and none of it
survives a rename on its own:

- **SavedVariables** live in `WTF\...\SavedVariables\<Folder>.lua`. On becoming
  `AuraQuestor`, the game started reading `AuraQuestor.lua`, which is empty; no
  API reads another addon's file. That is why the zip carries the
  `AuraTrackerQuestor` folder as a bridge: only the manifest, with
  `## SavedVariables: AuraTrackerQuestorDB`, so the game keeps loading the old
  table. `LegacyDatabase.Resolve` adopts it when the new one is empty. In
  alphabetical order `AuraQuestor` loads before `AuraTrackerQuestor`, so the
  `## OptionalDeps: AuraTrackerQuestor` in the main manifest is what guarantees
  the right order. Both manifests must declare the same `## Interface` (there is
  a test), otherwise the bridge becomes "out of date" and silently disappears
  for anyone who does not load old addons.
- **Key bindings** are saved by command name
  (`AURATRACKERQUESTOR_TOGGLE`, `AURATRACKERQUESTOR_OPTIONS`). These names
  were frozen on purpose in `Bindings.xml` and `KeyBindings.lua`; renaming them
  would unbind the key for everyone.
- **Frame name** (`AuraQuestorTracker`) and **LibDataBroker object**
  (`AuraQuestor`) changed with the folder; third-party addons that anchored by
  name or stored the datatext slot need to repoint.

The bridge can leave the package a few versions later, once nobody is left
coming from the old name.

## Measuring frames

`GetBottom()` and similar functions return screen coordinates that may be
**stale**: the game only recalculates the position at the end of the frame.
Measuring content height with them resulted in a list always one quest short
and a scroll that would not move.

Add up the heights manually, or use `GetStringHeight()` **after** setting the
font string's width. Without a width set, wrapped text reports the height of a
single line.

## Tooltip and quest selection

Reading a quest's description or rewards requires selecting it, and the
selection is **global state**, also read by the quest log. Without saving and
restoring the previous value, hovering over the tracker silently changed what
the quest log displayed:

```lua
local previous = C_QuestLog.GetSelectedQuest()
C_QuestLog.SetSelectedQuest(entry.id)
-- read
if previous then
	C_QuestLog.SetSelectedQuest(previous)
end
```

## Two sources, not one

A failure that happened three times in this project: reading only part of what
the game publishes.

| What | Needs |
|---|---|
| World quests | `GetTasksTable()`, not just the manual watch list |
| Events | `GetOngoingEvents()` **and** `GetScheduledEvents()` |
| Rewards | guaranteed **and** choice ones (`GetNumQuestLogChoices`) |

When something does not show up, first check whether there is a second source
that was not queried.

## On-demand panels

The achievements panel is *load on demand*. Calling
`OpenAchievementFrameToAchievement` directly raises an error; the sequence is
`AchievementFrame_LoadUI()` and only then open and select. See
[`Game/Achievement/Panel.lua`](../Source/Game/Achievement/Panel.lua).

## Counterintuitive signatures

- `GameTooltip:SetText(text, r, g, b, alpha, wrap)`: the fifth parameter is
  **alpha**. In `AddLine` the fifth is wrap. Passing the wrap flag right after
  the color puts it in the alpha slot and raises an error.
- `StaticPopup` has no `.editBox`; use `popup:GetEditBox()`.
- `SOUNDKIT` and FileDataID are **separate ID spaces**. A kit plays with
  `PlaySound`, a file with `PlaySoundFile`. Swapping one for the other produces
  no sound at all.

## Game fonts

The default font does not contain every glyph. `→` renders as an empty square;
use `>` or `·`.

## How to verify

The file `_retail_/Logs/General.log` accumulates everything the client logs, so
its size tells you nothing. What matters are the `[E][Lua] Lua Error` lines
dated after the last `/reload`:

```sh
grep -E "^$(date +%-m/%-d) 1[0-9]:" General.log | grep "Lua Error"
```

Each error carries the full stack with the file path, which is faster than
diagnosing from the symptom on screen. The path also gives away an old log: if
it points to a file that no longer exists, the error predates some
reorganization.
