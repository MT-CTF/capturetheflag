local mods = minetest.get_mod_storage()

local cache = {}

function ctf_rankings.update_league(player)
	player = PlayerObj(player)
	local pname = player:get_player_name()
	local league = cache[pname]

	if not league then
		league = player:get_meta():get_string("ctf_rankings:leagues")

		if league ~= "" then
			league = minetest.deserialize(league)
		else
			hpbar.set_icon(player, "")
			return
		end

		cache[pname] = league
	end

	if ctf_modebase.current_mode and league[ctf_modebase.current_mode] then
		hpbar.set_icon(player, ctf_rankings.league_textures[league[ctf_modebase.current_mode]])
	end
end

minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	local pname = player:get_player_name()
	local leagues = {}

	if meta:get_string("ctf_rankings:leagues") == "" or
	ctf_rankings.current_reset > meta:get_int("ctf_rankings:last_reset") then
		minetest.log("action", "[CTF_RANKINGS]: Getting league of player "..pname.." for the first time")

		local data = mods:get_string("rank:"..pname)
		data = (data ~= "") and minetest.parse_json(data) or false

		if data and data._last_reset then
			for mode, rank in pairs(data[data._last_reset]) do
				if rank.place then
					for _, league in ipairs(ctf_rankings.leagues_list) do
						if rank.place <= ctf_rankings.leagues[league] then
							leagues[mode] = league
							break
						end
					end
				end

				if rank._pro_chest then
					meta:set_int("ctf_rankings:pro_chest:"..mode, 1)
				end
			end

			cache[pname] = leagues
			meta:set_string("ctf_rankings:leagues", minetest.serialize(leagues))
			meta:set_int("ctf_rankings:last_reset", ctf_rankings.current_reset)
		end
	end

	-- This commented code needs to be changed to only run when there are a certain amount of players in the rankings
	-- Maybe up to wood league?

	-- for mode, def in pairs(ctf_modebase.modes) do
	-- 	local place = def.rankings.top:get_place(pname)

	-- 	for _, league in ipairs(ctf_rankings.leagues_list) do
	-- 		if place <= ctf_rankings.leagues[league] then
	-- 			leagues[mode] = league
	-- 			break
	-- 		end
	-- 	end
	-- end

	-- cache[pname] = leagues

	if ctf_modebase.current_mode then
		ctf_rankings.update_league(player)
	end
end)

-- The following with keep a rough limit on the cache size
-- This implementation is pretty much just me messing around, sensible implementations welcome
local persisted_cache_count = 0
local removed_cache_count = 0
local PERSIST_LIM = 1000
local CLEAR_CACHE_TRIGGER = PERSIST_LIM
minetest.register_on_leaveplayer(function(player)
	if persisted_cache_count <= PERSIST_LIM then
		persisted_cache_count = persisted_cache_count + 1
	elseif removed_cache_count >= CLEAR_CACHE_TRIGGER then
		cache = {}
		removed_cache_count = 0
		persisted_cache_count = 0

		minetest.log("action", "[CTF Leagues]: Reset league cache")
	else
		removed_cache_count = removed_cache_count + 1
		cache[player:get_player_name()] = nil
	end
end)

ctf_api.register_on_new_match(function()
	minetest.after(1, function()
		for _, p in pairs(minetest.get_connected_players()) do
			ctf_rankings.update_league(p)
		end
	end)
end)

minetest.register_chatcommand("league", {
	description = "See the past league/ranking placements of yourself or another player",
	params = "[pname]",
	func = function(name, params)
		if params == "" then
			params = name
		end

		local key = "rank:" .. params
		local data = mods:get_string(key)

		local oldrank_data = (data ~= "") and minetest.parse_json(data) or false

		if oldrank_data then
			local out = ""

			for date, modes in pairs(oldrank_data) do
				if date:sub(1, 1) ~= "_" then
					out = out .. string.format("%s Reset (%s):\n", date, params)

					for mode, rank in pairs(modes) do
						if rank.place then
							for _, league in ipairs(ctf_rankings.leagues_list) do
								if rank.place <= ctf_rankings.leagues[league] then
									local th = "th"

									if rank.place == 2 then
										th = "nd"
									elseif rank.place == 3 then
										th = "rd"
									end

									out = out .. string.format("\t[%s]: %s League (%s%s place%s)\n",
										HumanReadable(mode), HumanReadable(league), rank.place,
										th, rank._pro_chest and ", with pro chest access" or ""
									)
									break
								end
							end
						end
					end
				end
			end

			return true, out:sub(1, -2)
		else
			return true, "No league data for player " .. params
		end
	end
})

minetest.register_chatcommand("leagues", {
	description = "Shows a list of leagues and the placement needed to get in each of them",
	func = function(name)
		local out = ""
		for _, league in pairs(ctf_rankings.leagues_list) do
			if league ~= "none" then
				out = out .. string.format("%s League: Top %d\n",
					HumanReadable(league),
					ctf_rankings.leagues[league]
				)
			end
		end

		return true, out:sub(1, -2)
	end
})
