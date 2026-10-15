# EzPersistence

**Your macros, key bindings, action bars and settings, saved by you and put back anywhere.**

Macros, bindings and bars live in the game's `WTF` folder and on Blizzard's servers, tied to one client install and one character. Move to a new client, realm or character and you rebuild them by hand. EzPersistence saves them with one command and puts them back with another.

## Commands

`/ep` (or `/ezpersistence`)

| Command | What it does |
| --- | --- |
| `/ep save` | Saves this character's macros, key bindings, action bars, settings and Edit Mode layouts |
| `/ep restore [part] [name]` | Puts them back on the character you're on |
| `/ep status [part] [name]` | Shows what differs from the saved copy |
| `/ep list` | Characters with something saved |
| `/ep layouts [n] [name]` | Opens saved Edit Mode layout `n` (default 1), ready to copy into Edit Mode's Import. On a character that didn't save them, add the saver's name: `/ep layouts bergaber` |

Parts are `macros`, `bindings`, `bars`, `settings` and `layouts`; leave them out for all of them. `[name]` is a character's first name; leave it out for the character you're on. `/ep restore bars olizzy` puts Olizzy's action bars on whoever you're playing.

## What gets saved

- **Macros:** this character's and the account's, plus your **EzEmote** custom lines and chains (the `/eze <name>` lines macros run).
- **Key bindings:** every bound key, including keys bound to macros, spells and addon buttons, and whether they were account-wide or character-specific.
- **Action bars:** every slot. Spells, items, macros and equipment sets are put back; mounts, pets and flyouts are left as they are.
- **Settings:** the game options you changed from their defaults (interface, nameplates, combat text, sound volumes). Graphics and hardware options stay with the PC.
- **Edit Mode layouts:** saved as Edit Mode's share text. `/ep restore` does **not** put them back: you import them by hand, see below.

## Restoring Edit Mode layouts (by hand)

Layouts are the one part `/ep restore` can't do for you (writing Edit Mode layouts from an addon could break Edit Mode), so you paste them in yourself. It takes a minute, and you only do it once if you import them as account layouts.

Layouts are saved **per character**, under the name of the character you ran `/ep save` on. On a new character, or one with a different name, plain `/ep layouts` finds nothing — **add the name of the character that saved them**:

1. Type `/ep layouts bergaber` (use your own saved character's first name; `/ep list` shows them). A box opens with the first layout's text already selected.
2. Press **Ctrl+C**.
3. Open **Edit Mode** (Esc > Edit Mode), click the **layout dropdown** at the top, choose **Import**.
4. Press **Ctrl+V**, give the layout a name, and pick **Account** so every character gets it (or **Character** for just this one). Click **Import**.
5. Saved more than one layout? The chat lists them by number. `/ep layouts 2 bergaber` opens the second, `/ep layouts 3 bergaber` the third, and so on. Repeat steps 2–4 for each.
6. Pick the layout you want in the Edit Mode dropdown and **Save**.

If you run plain `/ep layouts` on a character with nothing saved, it tells you which characters do have layouts.

## Moving to a new client

Saved data lives in the client's `WTF` folder, so a new install starts empty. Two ways to bring it along:

- **Copy the save file** (anyone): copy `WTF\Account\<account>\SavedVariables\EzPersistence.lua` from the old client into the same place on the new one, with the game closed.
- **Bake it into the addon** (if you run the addon from its source folder, e.g. a git clone): `tools\bake.ps1` writes your saves into `Baked.lua`, which your install then loads on any client.

Baking, step by step:

1. `/ep save` on every character you want to keep, then log out.
2. Run `tools\bake.ps1` in the addon folder. It finds `EzPersistence.lua` under `C:\Program Files (x86)\World of Warcraft`; if it finds more than one (several clients), it lists them — pass the one you want with `-SavedVariables <path>`.
3. Point the new client at the same addon folder and log in.
4. On a character with the **same first name** as one you saved: `/ep restore`. On any other character: `/ep restore <saved name>` (for example `/ep restore bergaber`).
5. Import your Edit Mode layouts by hand: [Restoring Edit Mode layouts](#restoring-edit-mode-layouts-by-hand).

## Your data stays yours

- Everything is stored in your own client's `WTF` folder (`EzPersistenceDB`), per account. Nothing is sent anywhere.
- The addon you download carries no one's profiles: `/ep list` starts empty until you `/ep save`.
- `Baked.lua` is personal. It's git-ignored and left out of release packages, so baking never ends up in a download.

## Good to know

- Restores run out of combat only, through the game's normal API: the same calls Blizzard's macro window, key binding screen and action bar dragging use.
- `restore` makes things match the saved copy: changed macros are overwritten, extra key bindings and action bar slots are cleared, and settings you hadn't changed go back to default.
- Spells your character doesn't know (yet) are listed and skipped.
- Settings aren't saved or restored while EzCinematic's screenshot mode is on.
- Made for **WoW Forever**
