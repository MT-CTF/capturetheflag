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
	sorted = {},

	rankings_sorted = function(self)
		return false -- Returning false, since not all rankings are sorted yet. See below for full func
	end,

	init = function(self)
		local modname = minetest.get_current_modname()

		if self then
			self.sorted[modname] = false
		else
			minetest.log(
				"error",
				"[ctf_rankings] The mode "..modname.." is calling the init() function wrong. Use ':' instead of '.'"
			)
		end

		return rankings(modname .. '|', top:new(), function()
			if self then
				self.sorted[modname] = true
			else
				minetest.log(
					"error",
					"[ctf_rankings] The mode "..modname.." is calling the init() function wrong. Use ':' instead of '.'"
				)
			end
		end)
	end,

	registered_on_rank_reset = {},

	do_reset = false, -- See ranking_reset.lua
	current_reset = 0, -- See ranking_reset.lua

	leagues = {
		diamond = 20,
		mese = 50,
		gold = 250,
		bronze = 500,
		steel = 1000,
		stone = 2500,
		wood = 5000,
		none = math.huge
	},
	leagues_list = {
		"diamond", "mese", "gold", "bronze", "steel", "stone", "wood", "none",
	},
	league_textures = {
		diamond = "ctf_rankings_league_diamond.png",
		mese = "ctf_rankings_league_mese.png",
		gold = "ctf_rankings_league_gold.png",
		bronze = "ctf_rankings_league_bronze.png",
		steel = "ctf_rankings_league_steel.png",
		stone = "ctf_rankings_league_stone.png",
		wood = "ctf_rankings_league_wood.png",
		none = "",
	},

-- Used for cycling through all ranks ingame
-- Remember to remove spaces if running with Worldedit's //lua
--[[
for i, n in pairs(ctf_rankings.leagues_list) do
	minetest.after(i, function()
		hpbar.set_icon("LandarVargan", ctf_rankings.league_textures[n])
	end)
end
--]]
}

---@param func function
--- * pname
--- * rank
--- * mode name
function ctf_rankings.register_on_rank_reset(func)
	table.insert(ctf_rankings.registered_on_rank_reset, func)
end

minetest.register_on_mods_loaded(function()
	ctf_rankings.rankings_sorted = function(self)
		for _, sorted in pairs(self.sorted) do
			if not sorted then
				return false
			end
		end

		return true
	end
end)

ctf_core.include_files("leagues.lua", "ranking_reset.lua")
