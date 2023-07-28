local backend = minetest.settings:get("ctf_rankings_backend") or "default"

local rankings
local top = ctf_core.include_files("top.lua")

if backend == "redis" then
	local env = minetest.request_insecure_environment()
	assert(env, "Please add 'ctf_rankings' to secure.trusted_mods if you want to use the redis backend")

	local old_require = require

	env.rawset(_G, "require", env.require)
	rankings = env.dofile(env.debug.getinfo(1, "S").source:sub(2, -9) .. "redis.lua")
	env.rawset(_G, "require", old_require)
else
	rankings = ctf_core.include_files(backend..".lua")
end

ctf_rankings = {
	init = function()
		return rankings(minetest.get_current_modname() .. '|', top:new())
	end,

	do_reset = false, -- See ranking_reset.lua
	current_reset = 0, -- See ranking_reset.lua

	leagues = {
		diamond = 20,
		mese = 50,
		gold = 250,
		bronze = 500,
		iron = 1000,
		tin = 2500,
		copper = 5000,
	},
	leagues_list = {
		"diamond", "mese", "gold", "bronze", "iron", "tin", "copper",
	},
	league_textures = {
		diamond = "default_diamond.png",
		mese = "default_mese_crystal.png",
		gold = "default_gold_ingot.png",
		bronze = "default_bronze_ingot.png",
		iron = "default_steel_ingot.png",
		tin = "default_tin_ingot.png",
		copper = "default_copper_ingot.png",
	},
}

ctf_core.include_files("leagues.lua", "ranking_reset.lua")
