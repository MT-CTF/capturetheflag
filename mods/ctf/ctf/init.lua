-- CAPTURE THE FLAG
--	by Andrew "rubenwardy" Ward
-----------------------------------------

ctf = {}
ctf.S = minetest.get_translator(minetest.get_current_modname())
local S = ctf.S

-- Privs
minetest.register_privilege("ctf_team_mgr", {
	description = S("Team manager"),
})

minetest.register_privilege("ctf_admin", {
	description = S("Can create teams, manage players, assign team owners."),
})

-- Modules
dofile(minetest.get_modpath("ctf") .. "/core.lua")
dofile(minetest.get_modpath("ctf") .. "/teams.lua")
dofile(minetest.get_modpath("ctf") .. "/hud.lua")

-- Init
ctf.init()
ctf.clean_player_lists()
