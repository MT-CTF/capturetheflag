return function(rankings)

local rankings_players = {}
local rankings_teams = {}

local function add_recent(storage, key, amounts)
	if not storage[key] then
		storage[key] = {}
	end

	for stat, amount in pairs(amounts) do
		storage[key][stat] = (storage[key][stat] or 0) + amount
	end
end

local function clear_recent(storage, key)
	if storage[key] then
		local count = 0

		for k in pairs(storage[key]) do
			if k:sub(1, 1) ~= "_" then
				count = count + 1
			end
		end

		if count == 0 then
			storage[key] = nil
		end
	end
end

return {
	add = function(player, amounts, no_hud)
		local hud_text = ""
		player = PlayerName(player)

		for name, val in pairs(amounts) do
			hud_text = string.format("%s+%d %s | ", hud_text, math.round(val), HumanReadable(name))
		end

		if not no_hud then
			hud_events.new(player, {text = hud_text:sub(1, -4)})
		end

		add_recent(rankings_players, player, amounts)

		if rankings_players[player]._team then
			add_recent(rankings_teams, rankings_players[player]._team, amounts)
		end

		rankings:add(player, amounts)
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
		if rankings_players[player] and rankings_players[player]._team then
			clear_recent(rankings_teams, rankings_players[player]._team)
		end
		clear_recent(rankings_players, player)
	end,
	on_match_end = function()
		rankings_players = {}
		rankings_teams = {}
	end,
	players = function() return rankings_players end,
	teams   = function() return rankings_teams   end,
}

end
