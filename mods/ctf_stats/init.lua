ctf_stats = {}

function ctf_stats.load()
	local file = io.open(minetest.get_worldpath().."/ctf_stats.txt", "r")
	if file then
		local table = minetest.deserialize(file:read("*all"))
		if type(table) == "table" then
			ctf_stats.matches = table.matches
			ctf_stats.current = table.current
			ctf_stats.players = table.players
			return
		end
	end

	ctf_stats.matches = {
		blue_wins = 0,
		red_wins = 0,
		skipped = 0
	}

	ctf_stats.current = {
		red = {},
		blue = {}
	}

	ctf_stats.players = {}
end

ctf.register_on_save(function()
	local file = io.open(minetest.get_worldpath().."/ctf_stats.txt", "w")
	if file then
		file:write(minetest.serialize({
			matches = ctf_stats.matches,
			current = ctf_stats.current,
			players = ctf_stats.players
		}))
		file:close()
	else
		ctf.error("io", "CTF file failed to save!")
	end

	return nil
end)

function ctf_stats.player(name)
	local tplayer = ctf.player(name)
	local player = ctf_stats.players[name]
	if not player then
		player = {
			red_wins = 0,
			blue_wins = 0,
			kills = 0,
			deaths = 0,
			attempts = 0
		}
		ctf_stats.players[name] = player
	end

	local mplayer = ctf_stats.current.red[name] or
			ctf_stats.current.blue[name]

	return player, mplayer
end

ctf.register_on_join_team(function(name, tname)
	ctf_stats.current[tname][name] = {
		kills = 0,
		deaths = 0,
		attempts = 0
	}
end)

ctf_match.register_on_skip_map(function()
	ctf_stats.matches.skipped = ctf_stats.matches.skipped + 1
end)

ctf_match.register_on_winner(function(winner)
	ctf_stats.matches[winner .. "_wins"] = ctf_stats.matches[winner .. "_wins"] + 1
end)

ctf_match.register_on_new_match(function()
	-- TODO: create and show match report

	ctf_stats.current = {
		red = {},
		blue = {}
	}
end)

ctf_flag.register_on_pick_up(function(name, flag)
	local main, match = ctf_stats.player(name)
	if main and match then
		main.attempts = main.attempts + 1
		match.attempts = match.attempts + 1
	end
end)

ctf_flag.register_on_precapture(function(name, flag)
	local tplayer = ctf.player(name)
	local main, match = ctf_stats.player(name)
	if main then
		main[tplayer.team .. "_wins"] = main[tplayer.team .. "_wins"] + 1
	end
	return true
end)

minetest.register_on_dieplayer(function(player)
	local main, match = ctf_stats.player(player:get_player_name())
	if main and match then
		main.deaths = main.deaths + 1
		match.deaths = match.deaths + 1
	end
end)

ctf_stats.load()
