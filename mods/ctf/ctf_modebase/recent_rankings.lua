ctf_modebase.recent_rankings = function(rankings)

local rankings_players = {}
local rankings_teams = {}

return {
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

		local team = rankings_players[player]._team

		for stat, amount in pairs(amounts) do
			rankings_players[player][stat] = (rankings_players[player][stat] or 0) + amount

			if team then
				rankings_teams[team][stat] = (rankings_teams[team][stat] or 0) + amount
				if stat == "score" then
					rankings_players[player][team.."_"..stat] = (rankings_players[player][team.."_"..stat] or 0) + amount
				end
			end
		end

		rankings:add(player, amounts)
	end,
	get = function(player)
		player = PlayerName(player)
		return rankings_players[player] or {}
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
		rankings_players = {}
		rankings_teams = {}
	end,
	players = function() return rankings_players end,
	teams   = function() return rankings_teams   end,
}

end
