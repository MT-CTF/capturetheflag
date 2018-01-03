ctf_stats = {}

local storage = minetest.get_mod_storage()
local data_to_persist = { "matches", "players" }

function ctf_stats.load()
	local file = io.open(minetest.get_worldpath() .. "/ctf_stats.txt", "r")
	if file then
		local table = minetest.deserialize(file:read("*all"))
		file:close()
		if type(table) == "table" then
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

			ctf.needs_save = true
		end
		os.remove(minetest.get_worldpath() .. "/ctf_stats.txt")
	else
		for _, key in pairs(data_to_persist) do
			ctf_stats[key] = minetest.parse_json(storage:get_string(key))
		end
		ctf.needs_save = true
	end

	for name, player_stats in pairs(ctf_stats.players) do
		if not player_stats.score or player_stats.score <= 0 then
			ctf_stats.players[name] = nil
			ctf.needs_save = true
		end
	end

	ctf_stats.matches = ctf_stats.matches or {
		wins = {
			blue = 0,
			red = 0,
		},
		skipped = 0
	}

	ctf_stats.current = ctf_stats.current or {
		red = {},
		blue = {}
	}

	ctf_stats.players = ctf_stats.players or {}
end

ctf.register_on_save(function()
	for _, key in pairs(data_to_persist) do
		storage:set_string(key, minetest.write_json(ctf_stats[key]))
	end

	return nil
end)

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
		}
		ctf_stats.players[name] = player_stats
	end

	local match_player_stats =
			ctf_stats.current.red[name] or ctf_stats.current.blue[name]

	return player_stats, match_player_stats
end

ctf.register_on_join_team(function(name, tname)
	ctf_stats.current[tname][name] = ctf_stats.current[tname][name] or {
		kills = 0,
		kills_since_death = 0,
		deaths = 0,
		attempts = 0,
		captures = 0,
		score = 0,
	}
end)

ctf_match.register_on_skip_map(function()
	ctf.needs_save = true
	ctf_stats.matches.skipped = ctf_stats.matches.skipped + 1
end)

ctf_flag.register_on_capture(function(name, flag)
	local main, match = ctf_stats.player(name)
	if main and match then
		main.captures  = main.captures  + 1
		main.score     = main.score     + 25
		match.captures = match.captures + 1
		match.score    = match.score    + 25
		ctf.needs_save = true
	end
end)

ctf_match.register_on_winner(function(winner)
	ctf.needs_save = true
	ctf_stats.matches.wins[winner] = ctf_stats.matches.wins[winner] + 1
end)

ctf_match.register_on_new_match(function()
	local fs = ctf_stats.get_formspec_match_summary(ctf_stats.current)
	local players = minetest.get_connected_players()
	for _, player in pairs(players) do
		minetest.show_formspec(player:get_player_name(), "ctf_stats:eom", fs)
	end

	ctf_stats.current = {
		red = {},
		blue = {}
	}
	ctf.needs_save = true
end)

ctf_flag.register_on_pick_up(function(name, flag)
	local main, match = ctf_stats.player(name)
	if main and match then
		main.attempts  = main.attempts  + 1
		main.score     = main.score     + 5
		match.attempts = match.attempts + 1
		match.score    = match.score    + 10
		ctf.needs_save = true
	end
end)

ctf_flag.register_on_precapture(function(name, flag)
	local tplayer = ctf.player(name)
	local main, match = ctf_stats.player(name)
	if main then
		main.wins[tplayer.team] = main.wins[tplayer.team] + 1
		ctf.needs_save = true
	end
	return true
end)

local good_weapons = {
	"default:sword_stone",
	"default:sword_steel",
	"shooter:grenade",
	"shooter:shotgun",
	"shooter:rifle",
	"shooter:machine_gun",
}
local function invHasGoodWeapons(inv)
	for _, weapon in pairs(good_weapons) do
		if inv:contains_item("main", weapon) then
			return true
		end
	end
	return false
end

local function calculateKillReward(victim, killer)
	local vmain, victim_match = ctf_stats.player(victim)

	-- +5 for every kill they've made since last death in this match.
	local reward = victim_match.kills_since_death * 5
	ctf.log("ctf_stats", "Player " .. victim .. " has made " .. reward ..
			" score worth of kills since last death")

	-- 15 * kd ration, with variable based on player's score
	local kdreward = 30 * vmain.kills / (vmain.deaths + 1)
	local max = vmain.score / 6
	if kdreward > max then
		kdreward = max
	end
	if kdreward > 80 then
		kdreward = 80
	end
	reward = reward + kdreward

	-- Limited to  0 <= X <= 100
	if reward > 150 then
		reward = 150
	elseif reward < 14 then
		reward = 14
	end

	-- Half if no good weapons
	local inv = minetest.get_inventory({ type="player", name = victim })
	if not invHasGoodWeapons(inv) then
		ctf.log("ctf_stats", "Player " .. victim .. " has no good weapons")
		reward = reward * 0.5
	else
		ctf.log("ctf_stats", "Player " .. victim .. " has good weapons")
	end

	return reward
end

ctf.register_on_killedplayer(function(victim, killer)
	local main, match = ctf_stats.player(killer)
	if main and match then
		local reward = calculateKillReward(victim, killer)
		main.kills  = main.kills  + 1
		main.score  = main.score  + reward
		match.kills = match.kills + 1
		match.score = match.score + reward
		match.kills_since_death = match.kills_since_death + 1
		ctf.needs_save = true
	end
end)

minetest.register_on_dieplayer(function(player)
	local main, match = ctf_stats.player(player:get_player_name())
	if main and match then
		main.deaths = main.deaths + 1
		match.deaths = match.deaths + 1
		match.kills_since_death = 0
		ctf.needs_save = true
	end
end)

ctf_stats.load()

dofile(minetest.get_modpath("ctf_stats").."/gui.lua")
