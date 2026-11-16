# Changelog

**English** | [Português](CHANGELOG.pt-BR.md)

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/).

## [0.90.0] - 2026-11-16

### Added

- **Space between sections** and **space between entries**, under Appearance >
  Window. The defaults keep the look you already had; at zero the next header
  sits right under the last entry. The list also no longer ends with an empty
  gap at the bottom. Requested by a player on CurseForge.

### Fixed

- Hovering a point of interest on the world map could throw a "secret value"
  error naming Aura Questor, after an event had been hovered in the tracker
  ([#68](https://github.com/lucascodev/aura-questor/issues/68)). The event's
  extra details now go into the tracker's tooltip as text; purely graphical
  ones, like bars or icons without text, show only on the map.

### Changed

- Compatible with WoW patch **12.1.7**, while still running on 12.1.5, which is
  live.

## [0.89.0] - 2026-10-06

### Added

- **Shift + right-click** an entry to stop tracking it, without opening the
  menu. Works on quests, world quests, achievements, recipes, collectables,
  monthly activities and initiative tasks; bonus objectives, events and
  scenarios still open the menu. It follows the game's own untrack modifier,
  Shift unless you changed it. Requested by a player on CurseForge.
- **Stop Tracking** in the right-click menu of profession recipes. The game
  keeps plain and recraft recipes in separate lists, so untracking one leaves
  the other in place. Requested by a player on CurseForge.
- Clicking a tracked **collectable** opens where it comes from: an achievement
  opens the achievement, a recipe opens the profession, and a vendor, boss or
  chest opens the map on it. It used to always open the collections journal,
  which made housing decor look unclickable. Collectables also get a pin that
  points the arrow, a chat link on Shift-click, the dressing room on
  Ctrl-click and, for appearances, the journal in the menu.
- Clicking an **initiative task** opens the housing dashboard on the Endeavors
  tab, at that task; it used to do nothing. Tasks also get a chat link on
  Shift-click and a menu item for the tab.

### Fixed

- The line under a tracked collectable's name was empty. It now shows where it
  comes from: who sells it, where it drops, what it costs.

## [0.88.1] - 2026-09-14

### Changed

- Compatible with WoW patch **12.1.5**, while still running on 12.1.0, which is
  live. Nothing changes in how you use it: the game functions the addon calls
  stayed the same in the new patch, and what Blizzard removed in it wasn't used
  here.

## [0.88.0] - 2026-08-28

### Added

- **Newest first**, under Sorting: the quests you accepted most recently go to
  the top of the section. The game doesn't record when a quest was accepted, so
  the addon now keeps track of that on its own, per character.
- The quests already in your log when you update to this version all come in at
  once, in the order the log returns them. Only what you accept from now on gets
  the exact order of arrival.

## [0.87.1] - 2026-08-24

### Fixed

- In combat the whole tracker froze: nothing new came into the list, the
  scenario didn't change state, and collapsing or moving the window didn't
  respond. The cause was the quest item button, which sits inside the block and,
  by the game's rules, protects every frame above it. It now lives in a frame of
  its own, outside the panel, and is only anchored to the block. The list
  updates during a fight just like at any other time.
- The only thing still on hold in combat is the button itself, because the game
  forbids it: the item button of a quest that shows up mid-fight comes in when
  the fight ends.

## [0.87.0] - 2026-08-23

### Added

- **Collapse during Mythic+**, under Content: the window collapses on its own
  when the key starts and opens again when the run ends. Only a window the addon
  collapsed is opened again; if you collapsed it yourself beforehand, it stays
  as you left it, and if you open it by hand during the run, the addon leaves it
  alone. Off by default. Requested by a player on CurseForge.

## [0.86.1] - 2026-08-22

### Fixed

- Inside a Mythic+ dungeon a Lua error naming Aura Questor showed up, coming
  from the aura reading done by the game's tracker. Even hidden, it kept
  building its blocks on every update, and that building reads auras, which
  inside an instance the client refuses to hand to code an addon has touched.
  Now, while the game's tracker is hidden, its modules leave the panel: the
  part that caused the error never gets to run, and the work of drawing a
  tracker nobody sees goes away with it. Showing it again puts everything back
  in place, no `/reload` needed.

## [0.86.0] - 2026-08-21

### Fixed

- The window moved a little on every `/reload`, and its height changed with it.
  To re-anchor itself, the tracker measured its own position on every size
  change, and the game answers that measurement with the previous layout, not
  the current one. At login this saved a spot slightly off from the real one,
  and the window wandered. Now the saved position is the only reference:
  measuring only happens when you let go of a drag.
- Changing the scale in the options moved the window to another spot on the
  screen. The saved numbers are in the window's scale, so changing the scale
  changed what they mean. The position is now reapplied right after the scale.

### Changed

- Section order is now saved as a preference instead of a profile table: that
  way the page's **Defaults** button restores the order along with everything
  else, and the card got a **Restore order** button of its own. A section that a
  future version adds goes next to the section it sits beside by default,
  instead of at the end of a list you arranged.

## [0.85.0] - 2026-08-21

### Fixed

- The window crept upward on its own when the list reached the bottom edge of
  the screen: it grew past the limit and the game pushed everything up, taking
  the header with it. Now it stops growing there and the list scrolls, as it
  already did when it hit the height limit.
- The window could move when the list changed size, and the default position is
  anchored by the right edge, where this happened every time. It's now held by
  its top corner, which is what keeps the header still, and the spot you choose
  is saved by that same corner.

### Added

- **Fit height to the list**, on by default: the window shrinks to the size of
  what's tracked, and the height you pick in the panel becomes the limit instead
  of a fixed size.
- **Hide when empty**, on by default: with nothing tracked the window leaves the
  screen. Hiding sections with the filter doesn't count as empty, because that's
  your choice.
- **Open when something is tracked**, off by default: with the window collapsed,
  it opens on its own when something new reaches the list.
- **Wowhead link** in a quest's or achievement's menu, in the client's language,
  in a box to copy from, since the game doesn't open a browser.

## [0.84.1] - 2026-08-21

### Fixed

- Hovering a quest with an item reward threw a game error on screen. The rewards
  block embeds the item's tooltip, which measures itself with values the client
  hides from addons, and that breaks the math inside the game itself. Rewards
  still show, with name, colour and icon, without the embedded item tooltip.

## [0.84.0] - 2026-08-21

### Fixed

- A quest's objectives sat as close to each other as the lines of an objective
  that wraps onto two, and you couldn't tell where one ended. Now there's a
  clear step between them.
- Progress bars took up the full width of the block, pressed against the text
  above and below. Now they're inset on both sides, with more breathing room
  above and below, so they read as a graphic between the lines.
- In combat, clicking a quest to follow it did nothing. The change waited for
  the fight to end because of a problem with the map pins, which only happens
  with the map open. Now it only waits in that case, and with the map closed the
  click takes effect right away, as in the game's tracker.
- A scenario's bar came out plain, while the game draws it split into five, the
  same art as bonus objectives and world quests. Only regular quests use the
  plain bar.

## [0.83.1] - 2026-08-21

### Fixed

- Hovering an event could throw a game error on screen. The details it publishes
  on its map pin arrive incomplete away from the map, and Blizzard's own
  renderer breaks on them. A set that fails once is no longer drawn until your
  next login, and the rest of the tooltip stays the same.

## [0.83.0] - 2026-08-21

### Added

- The countdown shows seconds: `4min 32s` under an hour and `45s` in the last
  minute. Above an hour nothing changes. The number ticks second by second while
  there's a countdown on screen.
- What the game shows on an event's map pin, with rewards and items, now appears
  in the entry's tooltip, which is where that content fits.
- The event menu gained **Focus** and **Remove Focus**, the same options the
  game shows on the map pin. Clicking the event's icon already did this, but
  nothing said so.
- The event you're following gets the same glow the game puts behind its pin on
  the map. Its own art has no selected version, so before there was no way to
  tell which one was chosen.
- Events go to chat with the same click as quests, using the event link the game
  itself created for its reminders.
- A quest's tooltip now shows rewards with the same block the game draws on the
  map, so currency, reputation and War Mode bonus show up. Ours only read money
  and items, and a world quest pays outside the quest log, which left its
  tooltip with no reward at all.
- The tooltip picks the side that has room and stays inside the screen, since
  the rewards block brings the full item tooltip and the tracker can be in any
  corner.

### Changed

- Progress bars now come in a style of your choice, on the Frame page:
  **Aura Questor**, flat with a thin outline, which is the default, or
  **Blizzard**, with the metal frame of the game's tracker. In both, world
  quests and bonus objectives are split into five parts, as in the game's
  tracker. Their height is now a preference too.
- You can choose what the world quests section lists, in the panel and in the
  funnel menu: **Tracked**, as before, or **All in this zone** and **All where I
  am**, which bring in the world quests around you even if you haven't tracked
  any. With **Tracked**, a quest followed from the map stays on the list
  wherever you go, which is how the game's tracker behaves.

### Fixed

- An event in progress didn't show how much time it had left. The deadline for
  these doesn't come from the scheduler but from the map pin, and that's where
  it's read from now.
- Each event's art and countdown now follow what that event asks for, instead of
  being the same for all of them.

## [0.82.0] - 2026-08-20

### Added

- **Defaults** button in the header of each settings page, in the same corner
  where the game puts its own. It restores only what that page shows, and asks
  first, since there's no undo.

### Fixed

- The higher height cap promised in 0.81.0 didn't actually go up: the screen
  height was measured at load, before the interface scale applied, and the
  control ended up stopping at the same 900 as before. It's now measured when
  the page opens, and as a bonus, changing resolution or scale mid-session
  takes effect without a `/reload`.

## [0.81.0] - 2026-08-20

### Changed

- The tracker's height cap now follows your screen instead of stopping at 900:
  on a tall monitor you can stretch it down close to the bottom edge. On a
  shorter screen the old cap still applies, so no height you already saved
  shrinks.

## [0.80.2] - 2026-08-20

### Fixed

- With many media addons installed, a dropdown's list ran past the edge of the
  screen and whatever fell below it was impossible to pick. The panel's
  dropdowns now scroll instead of growing endlessly.
- The game's tracker reappeared under ours mid-session and only went away again
  after a `/reload`. Every time the interface comes back, when leaving a
  cinematic or a vehicle, the game turns the frames in that corner of the screen
  back on, and the addon trusted its own memory of having already hidden it, so
  it never wrote it again. Opacity is now read from the frame itself, so the
  next update hides it again.
- With both trackers on screen, the game's no longer reappears at moments when
  the game itself hides it, like under a vehicle's action bar.

## [0.80.1] - 2026-08-19

### Fixed

- On Chinese and Korean clients the text came out unreadable: the Inter and
  JetBrains Mono fonts that ship with the addon don't have those glyphs. On
  those clients the tracker and the options panel now use the game's own font,
  the font picker no longer offers the fonts missing those glyphs, and a choice
  of one of them that was already saved is migrated. The **Game Default** font
  joins the shared library in every language, for anyone who prefers the
  game's.

## [0.80.0] - 2026-08-18

### Added

- Clicking a quest, bonus objective or achievement with the chat link modifier
  (Shift by default) puts its link in the chat box to share, as in the game's
  tracker.
- **Only the dungeon in Mythic+**, on by default as in the game's tracker:
  during an active keystone the other sections step aside, and everything comes
  back when you leave. You can turn it off on the Content page.

## [0.79.3] - 2026-08-17

### Fixed

- The Delve card showed up twice, with one tier in each. The game publishes one
  header per state in the same widget set and counts on them overlapping, as in
  Blizzard's stage container; ours stacked them. The container now uses the same
  anchors and, along the way, rebuilds itself when it reappears, and blocks in
  use are no longer hidden and shown again on every redraw.

## [0.79.2] - 2026-08-17

### Fixed

- A quest that completes remotely but whose notification had already gone by
  (completed before login, or the alert dismissed) showed up as a normal
  turn-in, and clicking it opened the quest log. The check now follows the quest
  log's own flag (`isAutoComplete`), like Blizzard's tracker, and the entry
  shows "Quest Complete" and "(click to complete)"; clicking it opens the
  completion window.
- In combat, with an item button on the list, the tracker didn't update anything
  until the fight ended, and a "kill creatures" world quest kept its bar stuck
  at 0% while the map already said 30%. Now the text of the lines and the value
  of the bars of the blocks on screen are rewritten in place during combat; only
  what would change shape (an extra line, a new entry) waits for the fight to
  end.

## [0.79.1] - 2026-08-17

### Added

- **Track world quests**, in the filter menu and on the Content page, the same
  switch events already had: when off, the section goes away entirely, whether
  or not you're inside a world quest's area.

### Fixed

- World quests tracked from the map didn't appear: the section only read the
  ones in the area you're in. It now lists both sources, in the order of
  Blizzard's tracker: first the ones in the area, then the tracked ones,
  wherever they are. **Stop Tracking** on a world quest used the quest log call
  and did nothing; it now uses the right list and, if the quest was the
  supervised one, releases the arrow along with it.

## [0.79.0] - 2026-08-17

### Changed

- The addon is now called **Aura Questor: Objective Tracker**; the folder and
  the manifest become `AuraQuestor`. Nobody loses their settings: the zip also
  carries the `AuraTrackerQuestor` folder as a bridge, with only the manifest
  that keeps the old table loaded, and the addon adopts it on the first login
  under the new name, letting you know in chat. Key bindings and `/atq` stay the
  same. The frame name (`AuraQuestorTracker`) and the LibDataBroker object
  (`AuraQuestor`) changed along with the folder: addons that anchored by name or
  saved the datatext slot need to be pointed at the new names. The bridge can be
  removed after the first login and will leave the package in future versions.

### Fixed

- With a narrow panel, the header buttons ran over the addon's name. The name
  now ends before the row of buttons and is cut with an ellipsis when it doesn't
  fit.

## [0.78.0] - 2026-08-16

### Added

- Collapse button in the corner of the header, the same one Blizzard's tracker
  has: the panel shrinks until only the header is left and comes back with
  another click. The state is saved in the profile, and the header stays in
  place when collapsing.
- **Edit mode** in the filter menu too, in the Window group at the end of the
  list, to unlock dragging without opening the options.

## [0.77.0] - 2026-08-15

### Changed

- The options were redesigned from top to bottom, with their own identity in
  the logo's palette: near-black background, section cards and a single blue
  accent. Eight subpages became five (Appearance, Frame, Content, Integration
  and Profiles), without removing any preference: Advanced went into the main
  page, Buttons and Sound went into Content, and Background and border became
  Frame. Hints moved out of the tooltip and became helper text on the line
  itself, switches replaced the checkboxes, and Integration became a list with
  version and state per addon. The Inter and JetBrains Mono fonts ship with the
  addon (SIL OFL license) and are available in the shared library.
- The built-in Options search and the Defaults button no longer reach these
  pages, an accepted consequence of drawing them ourselves.
- The code folders moved down into `Source/`, leaving the addon's root with only
  the manifest, bindings, media, locales and libraries. No change in behaviour.
- The tracker adopts the options' typography: Inter becomes the default font on
  new installs (existing profiles keep their choice), and the progress bar
  percentages switch to JetBrains Mono, which lines up the digits.

### Added

- The quest context menu gained **Abandon Quest**, with Blizzard's own
  confirmation, only when the quest can be abandoned.
- A quest that completes remotely shows up on the list even if it isn't being
  watched, with Blizzard's notice in place of the objectives, and clicking it
  opens the reward window right there. This also applies to quests offered
  remotely, which show "Quest Discovered!" and open the offer when clicked.

### Fixed

- The stage card was missing Blizzard's art when the scenario didn't declare a
  set of its own: the lookup stopped before the fallbacks. Now the card wears
  the art at its own size and follows the game's design, with the stage number
  highlighted, the name smaller below it and **Final Stage** on the last one.
- Supervising an entry during combat tainted the map pin refresh and caused
  blocked action warnings. The change now waits for combat to end; only the
  last click counts.
- Opening the options in combat has been protected by the game since 12.x and
  ran into a blocked action. The click now warns you in chat and doesn't try.

## [0.76.1] - 2026-08-14

### Fixed

- The map display mode is only written when it actually changes. Rewriting the
  value that was already there tainted the field the map key binding reads, and
  opening the map in combat caused blocked action warnings in the addon's name.

## [0.76.0] - 2026-08-14

### Added

- TomTom integration, on the **Integration** tab of the options: the arrow
  follows the supervised quest, set by clicking the pin or selecting it on the
  map, and the context menu gains **Send to TomTom**. The line shows the addon's
  version when it's there; installed but disabled shows in a secondary colour,
  and the integration starts off, for you to turn on.
- **I** button in the tracker header, with a tooltip, that opens the Integration
  page directly. You can turn it off on the Buttons page, like the others.
- **Spanish** (esES and esMX) and **French** (frFR) translations, with parity
  tests covering all four languages.

### Changed

- The main options screen introduces the addon: the general switches and the
  version, author and command info in one place. The About subpage left the
  list.
- Completed quest titles use the game's "ready to turn in" green instead of the
  pastel tone.

### Fixed

- The "Escolha uma:" header of choice rewards was hardcoded in Portuguese and
  showed up that way in every language.

## [0.75.0] - 2026-08-13

### Added

- Scenario stage in the spotlight: a card with the art the scenario itself
  declares and, when the step publishes widgets, Blizzard's own block, with a
  wave timer or the Delve header with tier, lives and modifiers, all updating on
  their own.
- Item button on world quests and bonus objectives too, to the right of the
  block, with a frame, charge count, cooldown clock and the icon in red when out
  of range.
- **Completed at the top** option, in the filter menu and in the options, to
  group completed entries at the top of the section instead of the bottom.

### Changed

- The section says **Dungeon** in any dungeon, not just Mythic+, and says
  **Delves** inside a Delve.
- A quest with a percentage objective shows the line and the bar, instead of a
  bar with no text.
- Wrapping long text is now the default on new accounts; existing profiles keep
  the choice they made.

### Fixed

- Anchoring error when a quest with an item joined the list: the scroll area was
  anchored to a texture, and a protected frame doesn't accept that.
- Clicking the item button didn't fire: the click registration didn't match
  `ActionButtonUseKeyDown`.
- In combat, the tracker with an item button no longer tries to touch protected
  frames: scale, size, scrolling, edit mode and visibility wait for combat to
  end, and the refresh that follows the end of combat applies everything at
  once.
- Blizzard's tracker is only touched when the requested state changes, instead
  of on every update.

## [0.74.0] - 2026-08-13

### Added

- A logo of its own, used in the game's addon list, on the minimap button and
  in the tracker header.
- Published on Wago Addons alongside CurseForge, through the same packager.
- **Sound** tab: an alert when you complete a quest, with a choice of sound and
  audio channel. The sounds come from the game itself and from the shared
  library.
- Progress bar for objectives that report a percentage, with a configurable
  texture.
- **Background and border** page: texture, colour, thickness, opacity and
  inset, or your class colour on the border.
- **Profiles** page in the options, replacing the filter button's submenu.
- **Buttons** page: each header button and the minimap button can be turned off
  separately.
- Font outline and shadow; option to cut long text with an ellipsis instead of
  wrapping it.
- CI integration and packaging with the BigWigs packager.
- Localization: `Locales/` with `enUS.lua` as the default and `ptBR.lua` on
  top. A key with no translation falls back to English instead of disappearing.

### Changed

- Tracker header: the logo comes before the name, and a rule separates it from
  the list, in the same design that divides the sections.
- Folder structure: `Adapters/` gave way to `Game/`, `Modules/`, `UI/`,
  `Options/` and `System/`, and `Core/` was grouped by subject.
- Libraries are now downloaded by the packager instead of committed.
- World quests are listed by zone, with the type icon inside the pin.
- A completed quest shows where to turn it in instead of the full counter, and
  moves down to the end of the section.
- Bonus objectives got the star the game draws inside the marker.

### Fixed

- The default profile's name was translated, and changing the client's language
  made the profile disappear along with all its settings. It's now a fixed
  identifier, and a profile saved under the old name is renamed on load.

- World quests didn't appear when none had been tracked by hand.
- Clicking the pin of an entry that was already selected didn't release the
  selection.
- Task quest progress didn't update until the next quest log scan.

## [0.1.0]

First version of the standalone tracker, with Quests, Campaign, World Quests,
Bonus Objectives, Achievements, Professions, Traveler's Log, Collectables,
Endeavors, Scenario and World Events sections.
