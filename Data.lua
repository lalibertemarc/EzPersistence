-- EzPersistence: profiles that come with the addon. Empty here: your own saves go to
-- EzPersistenceDB. tools/bake.ps1 writes your saves into Baked.lua (git-ignored, never packaged),
-- which replaces this table on your own install so they ride along to a new client.
local _, ns = ...

ns.DATA = { characters = {} }
