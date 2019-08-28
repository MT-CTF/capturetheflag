-- CAPTURE THE FLAG
--	by Andrew "rubenwardy" Ward
-----------------------------------------

ctf = {}

-- Fix for https://github.com/minetest/minetest/issues/2383
local csa = minetest.chat_send_all
function minetest.chat_send_all(msg)
	minetest.after(0, function()
		csa(msg)
	end)
end

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
