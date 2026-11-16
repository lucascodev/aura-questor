# Documentation

**English** | [Português](pt-BR/README.md)

Technical documentation for Aura Questor, for those who will modify the code.

| Document | Subject |
|---|---|
| [Architecture](architecture.md) | the layers and the dependency rule |
| [Execution flow](flow.md) | initialization, update cycle and combat |
| [Adding content](adding-content.md) | implementing a new content type |
| [WoW constraints](constraints.md) | knowing the API's limits before touching a frame |
| [Development](development.md) | environment, tests, packaging and publishing |

## Summary

The addon reads the game's **public data APIs**, builds the objective list in
pure Lua and draws its own frame. It neither modifies nor depends on Blizzard's
tracker.

## The project in numbers

| | |
|---|---|
| Lua files loaded by the game | 106: 99 of ours and 7 from libraries |
| Lines in `Core/`, without a single game API | ~1,600 |
| Content providers, feeding 11 sections | 10 |
| Game events listened to | 27 |
| Preferences | 35 |
| Contracts in `Source/Ports/` | 17 |
| Tests running outside the client | 141 |
