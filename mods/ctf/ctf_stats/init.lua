ctf_stats = {}

local _needs_save = false
local storage = minetest.get_mod_storage()
local data_to_persist = { "matches", "players" }

ctf_stats.prev_match_summary = storage:get_string("prev_match_summary")

function ctf_stats.load_legacy()
	local file = io.open(minetest.get_worldpath() .. "/ctf_stats.txt", "r")
	if not file then
		return false
	end

	local table = minetest.deserialize(file:read("*all"))
	file:close()
	if type(table) ~= "table" then
		return false
	end

	ctf.log("ctf_stats", "Migrating stats...")
	ctf_stats.matches = table.matches
	ctf_stats.players = table.players

	for name, player_stats in pairs(ctf_stats.players) do
		if not player_stats.score or player_stats.score < 0 then
			player_stats.score = 0
		end
		if player_stats.score > 300 then
			player_stats.score = (player_stats.score - 300) / 30 + 300
		end
		if player_stats.score > 800 then
			player_stats.score = 800
		end

		player_stats.wins = player_stats.wins or {}
		if player_stats.blue_wins then
			player_stats.wins.blue = player_stats.blue_wins
			player_stats.blue_wins = nil
		end
		if player_stats.red_wins then
			player_stats.wins.red  = player_stats.red_wins
			player_stats.red_wins  = nil
		end
		player_stats.wins.blue = player_stats.wins.blue or 0
		player_stats.wins.red  = player_stats.wins.red  or 0
	end

	ctf_stats.matches.wins = ctf_stats.matches.wins or {
		red  = ctf_stats.matches.red_wins or 0,
		blue = ctf_stats.matches.blue_wins or 0,
	}

	_needs_save = true

	os.remove(minetest.get_worldpath() .. "/ctf_stats.txt")
	return true
end

-- Load persistant data from mod storage (or legacy file)
-- and initialize empty tables where required
function ctf_stats.load()
	if not ctf_stats.load_legacy() then
		for _, key in pairs(data_to_persist) do
			ctf_stats[key] = minetest.parse_json(storage:get_string(key))
		end
		_needs_save = true
	end

	-- Make sure all tables are present
	ctf_stats.players = ctf_stats.players or {}
	ctf_stats.matches = ctf_stats.matches or {
		wins = {
			blue = 0,
			red  = 0,
		},
		skipped = 0,
	}
	ctf_stats.current = ctf_stats.current or {
		red = {},
		blue = {}
	}

	-- Strip players which have no score
	for name, player_stats in pairs(ctf_stats.players) do
		if not player_stats.score or player_stats.score <= 0 then
			ctf_stats.players[name] = nil
			_needs_save = true
		else
			player_stats.bounty_kills = player_stats.bounty_kills or 0
		end
	end
end

-- Save persistant data to mod storage
function ctf_stats.save()
	for _, key in pairs(data_to_persist) do
		storage:set_string(key, minetest.write_json(ctf_stats[key]))
	end
end

-- Separate recursion to check if save required and then call ctf_stats.save
-- This allows ctf_stats.save to be called directly when an immediate save is required
local function check_if_save_needed()
	if _needs_save then
		ctf_stats.save()
		_needs_save = false
	end
	minetest.after(13, check_if_save_needed)
end
minetest.after(13, check_if_save_needed)

-- API function to allow other mods to request a save
-- TODO: This should be done automatically once a proper API is in place
function ctf_stats.request_save()
	_needs_save = true
end

function ctf_stats.player_or_nil(name)
	return ctf_stats.players[name], ctf_stats.current.red[name] or ctf_stats.current.blue[name]
end

-- Returns a tuple: `player_stats`, `match_player_stats`
function ctf_stats.player(name)
	local player_stats = ctf_stats.players[name]
	if not player_stats then
		player_stats = {
			name = name,
			wins = {
				red = 0,
				blue = 0,
			},
			kills = 0,
			deaths = 0,
			captures = 0,
			attempts = 0,
			score = 0,
			bounty_kills = 0,
		}
		ctf_stats.players[name] = player_stats
	end

	local match_player_stats =
			ctf_stats.current.red[name] or ctf_stats.current.blue[name]

	return player_stats, match_player_stats
end

function ctf_stats.get_ordered_players()
	local players = {}

	-- Copy player stats into new empty table
	for pname, pstat in pairs(ctf_stats.players) do
		pstat.name = pname
		pstat.color = nil
		table.insert(players, pstat)
	end

	-- Sort table in the order of descending scores
	table.sort(players, function(one, two)
		return one.score > two.score
	end)

	return players
end

function ctf_stats.get_target(name, param)
	param = param:trim()

	-- If param is not empty, check if it's a number or a string
	if param ~= "" then
		-- Order of the following checks are as given below:
		--
		-- * `param` is returned as a string if player's stats exists
		-- * If no matching stats exist, `param` is checked if it's a number
		-- * If `param` isn't a number, it is assumed to be invalid, and nil is returned
		-- * If `param` is a number, `param` is checked if out of bounds
		-- * If `param` is not out of bounds, `param` is returned as a number, else nil
		--
		-- This order of checks is important because, in the case of `param` matching
		-- both a number and a player name, it would be considered as a player name.

		-- Check if param matches a player name
		if ctf_stats.players[param] then
			return param
		else
			-- Check if param is a number
			local rank = tonumber(param)
			if rank then
				-- Check if param is within range
				-- TODO: Fix this hack by maintaining two tables - an ordered list, and a hashmap
				if rank <= 0 or rank > #ctf_stats.get_ordered_players() or
						rank ~= math.floor(rank) then
					return nil, "Invalid number or number out of bounds!"
				else
					return rank
				end
			else
				return nil, "Invalid player name specified!"
			end
		end
	else
		return name
	end
end

function ctf_stats.is_pro(name)
	local stats = ctf_stats.player(name)
	local kd = stats.kills / (stats.deaths == 0 and 1 or stats.deaths)
	return stats.score >= 10000 and kd >= 1.5
end

ctf.register_on_join_team(function(name, tname, oldteam)
	if not ctf_stats.current[tname] then
		ctf_stats.current[tname] = {}
	end

	if oldteam and ctf_stats.current[oldteam] then
		ctf_stats.current[oldteam][name] = nil
	end

	ctf_stats.current[tname][name] = ctf_stats.current[tname][name] or {
		kills = 0,
		kills_since_death = 0,
		deaths = 0,
		attempts = 0,
		captures = 0,
		score = 0,
		bounty_kills = 0,
	}
end)

ctf_stats.winner_team = "-"
ctf_stats.winner_player = "-"

table.insert(ctf_flag.registered_on_capture, 1, function(name, flag)
	local score = 0
	for i, pstat in pairs(ctf_stats.current.red) do
		score = score + pstat.score
	end
	for i, pstat in pairs(ctf_stats.current.blue) do
		score = score + pstat.score
	end
	local capturereward = math.floor(score * 10) / 100
	if capturereward < 50 then capturereward = 50 end
	if capturereward > 750 then capturereward = 750 end

	local main, match = ctf_stats.player(name)
	if main and match then
		main.captures  = main.captures  + 1
		main.score     = main.score     + capturereward
		match.captures = match.captures + 1
		match.score    = match.score    + capturereward
		_needs_save = true
	end
	ctf_stats.winner_player = name

	hud_score.new(name, {
		name  = "ctf_stats:flag_capture",
		color = "0xFF00FF",
		value = capturereward
	})
end)

ctf_match.register_on_winner(function(winner)
	ctf_stats.matches.wins[winner] = ctf_stats.matches.wins[winner] + 1
	ctf_stats.winner_team = winner

	-- Show match summary
	local fs = ctf_stats.get_formspec_match_summary(ctf_stats.current,
		ctf_stats.winner_team, ctf_stats.winner_player, ctf_match.get_match_duration())

	for _, player in pairs(minetest.get_connected_players()) do
		minetest.show_formspec(player:get_player_name(), "ctf_stats:eom", fs)
	end

	-- Set prev_match_summary and write to mod_storage
	ctf_stats.prev_match_summary = fs
	storage:set_string("prev_match_summary", fs)

	-- Flush data to mod_storage at the end of each match
	ctf_stats.save()
end)

ctf_match.register_on_skip_map(function()
	ctf_stats.matches.skipped = ctf_stats.matches.skipped + 1

	-- Show match summary
	local fs = ctf_stats.get_formspec_match_summary(ctf_stats.current,
		ctf_stats.winner_team, ctf_stats.winner_player, ctf_match.get_match_duration())

	for _, player in pairs(minetest.get_connected_players()) do
		minetest.show_formspec(player:get_player_name(), "ctf_stats:eom", fs)
	end

	-- Set prev_match_summary and write to mod_storage
	ctf_stats.prev_match_summary = fs
	storage:set_string("prev_match_summary", fs)

	ctf_stats.save()
end)

ctf_match.register_on_new_match(function()
	ctf_stats.current = {
		red = {},
		blue = {}
	}
	ctf_stats.winner_team = "-"
	ctf_stats.winner_player = "-"
	_needs_save = true
end)

-- ctf_map can't be added as a dependency, as that'd result
-- in cyclic dependencies between ctf_map and ctf_stats
minetest.after(0, function()
	ctf_map.register_on_map_loaded(function(map)
		ctf_stats.current.map = map.name
	end)
end)

ctf_flag.register_on_pick_up(function(name, flag)
	local main, match = ctf_stats.player(name)
	if main and match then
		main.attempts  = main.attempts  + 1
		main.score     = main.score     + 20
		match.attempts = match.attempts + 1
		match.score    = match.score    + 20
		_needs_save = true
	end

	hud_score.new(name, {
		name  = "ctf_stats:flag_pick_up",
		color = "0xAA00AA",
		value = 20
	})
end)

ctf_flag.register_on_precapture(function(name, flag)
	local tplayer = ctf.player(name)
	local main, _ = ctf_stats.player(name)
	if main then
		main.wins[tplayer.team] = main.wins[tplayer.team] + 1
		_needs_save = true
	end
	return true
end)

local good_weapons = {
	"default:sword_steel",
	"default:sword_bronze",
	"default:sword_mese",
	"default:sword_diamond",
	"default:pick_mese",
	"default:pick_diamond",
	"default:axe_mese",
	"default:axe_diamond",
	"default:shovel_mese",
	"default:shovel_diamond",
	"shooter:grenade",
	"shooter:shotgun",
	"shooter:rifle",
	"shooter:machine_gun",
	"sniper_rifles:rifle_762",
	"sniper_rifles:rifle_magnum",
}

local function invHasGoodWeapons(inv)
	for _, weapon in pairs(good_weapons) do
		if inv:contains_item("main", weapon) then
			return true
		end
	end
	return false
end

function ctf_stats.calculateKillReward(victim, killer, toolcaps)
	local vmain, victim_match = ctf_stats.player(victim)

	if not vmain or not victim_match then return 5 end

	-- +5 for every kill they've made since last death in this match.
	local reward = victim_match.kills_since_death * 5
	ctf.log("ctf_stats", "Player " .. victim .. " has made " .. reward ..
			" score worth of kills since last death")

	-- 30 * K/D ratio, with variable based on player's score
	local kdreward = 30 * vmain.kills / (vmain.deaths + 1)
	local max = vmain.score / 5
	if kdreward > max then
		kdreward = max
	end
	if kdreward > 100 then
		kdreward = 100
	end
	reward = reward + kdreward

	-- Limited to  5 <= X <= 250
	if reward > 250 then
		reward = 250
	elseif reward < 5 then
		reward = 5
	end

	-- Half if no good weapons, +50% if combat logger
	local inv = minetest.get_inventory({ type = "player", name = victim })

	if toolcaps.damage_groups.combat_log == 1 then
		ctf.log("ctf_stats", "Player " .. victim .. " is a combat logger")
		reward = reward * 1.5
	elseif not invHasGoodWeapons(inv) then
		ctf.log("ctf_stats", "Player " .. victim .. " has no good weapons")
		reward = reward * 0.5
	else
		ctf.log("ctf_stats", "Player " .. victim .. " has good weapons")
	end

	return reward
end

minetest.register_on_dieplayer(function(player)
	local main, match = ctf_stats.player(player:get_player_name())

	if main and match then
		main.deaths = main.deaths + 1
		match.deaths = match.deaths + 1
		match.kills_since_death = 0
		_needs_save = true
	end
end)

ctf_stats.load()

dofile(minetest.get_modpath("ctf_stats") .. "/gui.lua")
dofile(minetest.get_modpath("ctf_stats") .. "/chat.lua")
