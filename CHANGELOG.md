# EzPersistence

## v1.0.0

- First release for WoW Forever.
- `/ep save` saves this character's macros (and the account's), EzEmote chains, key bindings, action bars, game settings and Edit Mode layouts.
- `/ep restore` puts them back on any character, all at once or one part at a time; `/ep status` shows what differs.
- `/ep layouts [n] [name]` opens a saved Edit Mode layout to copy into Edit Mode's Import; on a character with none saved, it names the characters that have some.
- `tools/bake.ps1` copies your saves into your own install (`Baked.lua`, never packaged), so they come along to a new client.
- Login reminder when this character's saved macros are missing or changed.
