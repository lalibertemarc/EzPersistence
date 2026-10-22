# EzPersistence

**Save your macros, key bindings, action bars, settings and Edit Mode layouts with one command. Put them back on any character, or on a new client, with another.**

New client install, new PC, a new character, or a server reset? Your macros, bindings and bars stay behind with the old one, and you rebuild them by hand. EzPersistence keeps a copy you control: `/ep save` today, `/ep restore` wherever you play next.

Made for **WoW Forever**.

## Quick start

1. Log in on your main and type **`/ep save`**.
2. On the character (or client) you want it on, type **`/ep restore`**.
   - Different character name? Add the name you saved: **`/ep restore aelra`**.
3. Done. Chat tells you what was created, changed or skipped.

Not sure what will change? **`/ep status`** compares first and changes nothing.

## What gets saved

- **Macros:** this character's macros and your account-wide ones. If you use **EzEmote**, its custom lines and chains too.
- **Key bindings:** every bound key, including keys bound to macros, spells and other addons' buttons, and whether they were account-wide or for this character only.
- **Action bars:** every slot on every bar. Spells, items, macros and equipment sets are put back; mounts, pets and flyouts are left as they are.
- **Settings:** the game options you changed from their defaults (interface, nameplates, combat text, sound volumes…). Graphics and hardware options stay with the PC.
- **Edit Mode layouts:** saved as Edit Mode share text, ready to paste back in ([see below](#edit-mode-layouts)).

## Commands

`/ep` (or `/ezpersistence`)

| Command | What it does |
| --- | --- |
| `/ep save` | Save this character's macros, key bindings, action bars, settings and Edit Mode layouts |
| `/ep restore [part] [name]` | Put them back on the character you're playing |
| `/ep status [part] [name]` | Show what differs from the saved copy, without changing anything |
| `/ep list` | List the characters you've saved |
| `/ep layouts [n] [name]` | Open saved Edit Mode layout number `n` (default 1), ready to copy into Edit Mode |

- **`[part]`** is `macros`, `bindings`, `bars`, `settings` or `layouts`. Leave it out for everything.
- **`[name]`** is the first name of the character you saved. Leave it out to use the character you're on.

Examples:

- `/ep restore` — everything you saved on this character, back on it.
- `/ep restore aelra` — everything Aelra saved, on the character you're playing now.
- `/ep restore bars aelra` — only Aelra's action bars.
- `/ep restore macros bindings` — only macros and key bindings.

## Restoring on a different character

Saves are kept per character, under the name of the character that ran `/ep save`. Any character on the same account can use any of them: add that name to the command (`/ep restore aelra`).

- Spells the new character doesn't know (another class, or not learned yet) are skipped and listed in chat. Everything else is placed.
- Happy with the result? `/ep save` on the new character so it has its own copy and plain `/ep restore` works there.

## Moving to a new client or PC

Your saves are stored in the client's `WTF` folder, so a fresh install starts empty. Bring them along by copying one file:

1. `/ep save` on every character you want to keep, then **exit the game** (the file is written when you log out).
2. Find the file on the old client:
   `World of Warcraft\_<client>_\WTF\Account\<ACCOUNT NAME>\SavedVariables\EzPersistence.lua`
3. Install EzPersistence on the new client and log in once, so the game creates its `WTF\Account\<ACCOUNT NAME>` folder. Then exit the game.
4. Copy `EzPersistence.lua` into the new client's `WTF\Account\<ACCOUNT NAME>\SavedVariables\` folder. Replace the file if there's one there.
   - The account folder name can differ between clients (a number on one, your account name on another). Use whichever one the new client made.
5. Log in and `/ep restore` (or `/ep restore <name>` on a character with a different name).
6. Import your Edit Mode layouts ([below](#edit-mode-layouts)).

Copy the file only while the game is closed: the game rewrites it when you log out, and would overwrite your copy.

## Edit Mode layouts

Layouts are the one thing `/ep restore` doesn't write back: changing Edit Mode layouts from an addon can break Edit Mode, so you paste them in yourself. It takes a minute, and if you import them as **Account** layouts you only do it once.

1. Type **`/ep layouts`** — or **`/ep layouts aelra`** on a character that didn't save them. A box opens with the layout already selected.
2. Press **Ctrl+C**.
3. Open **Edit Mode** (Esc → Edit Mode), click the **layout dropdown** at the top and choose **Import**.
4. Press **Ctrl+V**, name the layout, choose **Account** (every character) or **Character** (this one), and click **Import**.
5. Saved more than one? Chat lists them by number: `/ep layouts 2 aelra`, `/ep layouts 3 aelra`… Repeat steps 2–4.
6. Pick the layout in the Edit Mode dropdown and **Save**.

On a character with no layouts saved, `/ep layouts` tells you which characters have some.

## Good to know

- **Restore makes things match the saved copy.** Changed macros are overwritten, extra key bindings and action bar slots are cleared, and settings you hadn't changed when you saved go back to default. Use `/ep status` first if you're unsure, or restore one part at a time.
- **Out of combat only.** Restores use the game's normal API: the same calls the macro window, the key bindings screen and dragging onto your bars use.
- **Your data stays yours.** Everything is stored in your own `WTF` folder. Nothing is sent anywhere, and a fresh download carries no one's profiles.
- **Login reminder:** if macros you saved on this character are missing or changed, chat tells you 10 seconds after logging in.
- With **EzCinematic**'s screenshot mode on, settings aren't saved or restored (it changes them temporarily).

## Running from source

If you run the addon from a git clone instead of a download, `tools\bake.ps1` copies your saves into `Baked.lua` inside the addon folder, so any client that loads that folder has them. `Baked.lua` is git-ignored and never packaged. Run it after `/ep save` and logging out; if it finds saves on several clients, pass the one you want with `-SavedVariables <path>`.
