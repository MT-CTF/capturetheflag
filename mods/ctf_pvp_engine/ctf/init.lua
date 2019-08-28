-- CAPTURE THE FLAG
--	by Andrew "rubenwardy" Ward
-----------------------------------------

ctf = {}

-- Privs
minetest.register_privilege("ctf_team_mgr", {
	description = "Team manager",
})

minetest.register_privilege("ctf_admin", {
	description = "Can create teams, manage players, assign team owners.",
})

-- Modules
dofile(minetest.get_modpath("ctf") .. "/core.lua")
dofile(minetest.get_modpath("ctf") .. "/teams.lua")
dofile(minetest.get_modpath("ctf") .. "/diplomacy.lua")
dofile(minetest.get_modpath("ctf") .. "/gui.lua")
dofile(minetest.get_modpath("ctf") .. "/hud.lua")

-- Init
ctf.init()
ctf.clean_player_lists()
