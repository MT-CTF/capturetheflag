ctf_modebase.recent_rankings = function(rankings)

local rankings_players = {}
local rankings_teams = {}

-- Used when ctf_core.settings.buffer_ranking_writes > 0
local ranking_timer = nil

-- Used when ctf_core.settings.buffer_ranking_writes > 0
local write_queue = {}

local function write_rankings()
	assert(ctf_core.settings.buffer_ranking_writes ~= -1, "write_rankings() called when ctf_buffer_ranking_writes is -1")

	minetest.log("action", "Writing recent_rankings to backend..")

	if ctf_core.settings.buffer_ranking_writes == 0 then
		write_queue = rankings_players
	end

	for player, stats in pairs(write_queue) do
		local pstats = {}

		for stat, amount in pairs(stats) do
			if stat:sub(1, 1) ~= "_" and amount > 0 then
				pstats[stat] = amount
			end
		end

		rankings:add(player, pstats)
	end

	if ctf_core.settings.buffer_ranking_writes > 0 then
		ranking_timer = nil
		write_queue = {}
	end
end

if ctf_core.settings.buffer_ranking_writes > -1 then
	core.register_on_shutdown(function()
		write_rankings()
	end)
end

return {
	get_last_updated = function()
		if ranking_timer then
			return os.clock() - ranking_timer
		else
			return 0
		end
	end,
	add = function(player, amounts, no_hud)
		player = PlayerName(player)

		if not no_hud then
			local hud_text = ""
			for name, val in pairs(amounts) do
				hud_text = string.format("%s%s%d %s | ", hud_text, val >= 0 and "+" or "", math.round(val), HumanReadable(name))
			end

			hud_events.new(player, {text = hud_text:sub(1, -4)})
		end

		if not rankings_players[player] then
			rankings_players[player] = {}
		end

		if ctf_core.settings.buffer_ranking_writes > 0
		and not write_queue[player] then
			write_queue[player] = {}
		end

		local team = rankings_players[player]._team

		for stat, amount in pairs(amounts) do
			rankings_players[player][stat] = (rankings_players[player][stat] or 0) + amount

			if ctf_core.settings.buffer_ranking_writes > 0 then
				write_queue[player][stat] = (write_queue[player][stat] or 0) + amount
			end

			if team then
				rankings_teams[team][stat] = (rankings_teams[team][stat] or 0) + amount
				if stat == "score" then
					rankings_players[player]["_"..team.."_"..stat] = (rankings_players[player]["_"..team.."_"..stat] or 0) + amount
				end
			end
		end

		if ctf_core.settings.buffer_ranking_writes == -1 then
			rankings:add(player, amounts)
		elseif ctf_core.settings.buffer_ranking_writes > 0 then
			if not ranking_timer then
				ranking_timer = os.clock()
			elseif os.clock() - ranking_timer >= ctf_core.settings.buffer_ranking_writes then
				write_rankings()
			end
		end
	end,
	get = function(player)
		player = PlayerName(player)

		if rankings_players[player] then
			return table.copy(rankings_players[player])
		else
			return {}
		end
	end,
	set_team = function(player, team)
		player = PlayerName(player)
		local tcolor = ctf_teams.team[team].color

		if not rankings_players[player] then
			rankings_players[player] = {}
		end

		if not rankings_teams[team] then
			rankings_teams[team] = {}
		end

		rankings_players[player]._row_color = tcolor
		rankings_players[player]._team = team
	end,
	on_leaveplayer = function(player)
		player = PlayerName(player)

		if rankings_players[player] then
			local count = 0

			for k in pairs(rankings_players[player]) do
				if k:sub(1, 1) ~= "_" then
					count = count + 1
				end
			end

			if count == 0 then
				rankings_players[player] = nil
			end
		end
	end,
	on_match_end = function()
		if ctf_core.settings.buffer_ranking_writes > -1 then
			write_rankings()
		end

		rankings_players = {}
		rankings_teams = {}
	end,
	players = function() return rankings_players end,
	teams   = function()
		local out = {}

		for k, v in pairs(rankings_teams) do
			if not ctf_teams.team[k].not_playing then
				out[k] = v
			end
		end

		return out
	end,
}

end
