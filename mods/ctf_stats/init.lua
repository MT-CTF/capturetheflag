ctf_stats = {}

function ctf_stats.load()
	print("load")
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
	print("get " .. name)
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
	print("join team")

	ctf_stats.current[tname][name] = {
		kills = 0,
		deaths = 0,
		attempts = 0
	}
end)

ctf_match.register_on_skip_map(function()
	print("skip map")

	ctf_stats.matches.skipped = ctf_stats.matches.skipped + 1
end)

ctf_match.register_on_winner(function(winner)
	print("win " .. winner)

	ctf_stats.matches[winner .. "_wins"] = ctf_stats.matches[winner .. "_wins"] + 1
end)

ctf_match.register_on_new_match(function()
	print("new match")

	-- TODO: create and show match report

	print(dump(ctf_stats.matches))
	print(dump(ctf_stats.current))
	print(dump(ctf_stats.players))

	ctf_stats.current = {
		red = {},
		blue = {}
	}
	minetest.after(3, function()
		print(dump(ctf_stats.current))
	end)
end)

ctf_flag.register_on_pick_up(function(name, flag)
	print("pick up")
	local main, match = ctf_stats.player(name)
	main.attempts = main.attempts + 1
	match.attempts = match.attempts + 1
end)

ctf_flag.register_on_precapture(function(name, flag)
	print("capture")
	local tplayer = ctf.player(name)
	local main, match = ctf_stats.player(name)
	main[tplayer.team .. "_wins"] = main[tplayer.team .. "_wins"] + 1

	return true
end)

minetest.register_on_dieplayer(function(player)
	print("die")
	local main, match = ctf_stats.player(player:get_player_name())
	main.deaths = main.deaths + 1
	match.deaths = match.deaths + 1
end)

ctf_stats.load()
