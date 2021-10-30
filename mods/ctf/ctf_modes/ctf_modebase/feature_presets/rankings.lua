-- dofile(filepath)("mode_technical_name", mode_data)
-- mode_data must hold variables: SUMMARY_RANKS

return function(mode_tech_name, mode_data)

local rankings = ctf_rankings.init()
local rankings_recent = {}
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

----
------ COMMANDS
----

local rank_def = {
	description = "Get the rank of yourself or a player",
	params = "[playername]",
	func = function(name, param)
		local target = name

		if param and param ~= "" then
			target = param
		end

		local prank = rankings:get(target) -- [p]layer [rank]

		if not prank then
			return false, string.format("Player %s has no rankings!", target)
		end

		local return_str = string.format("Rankings for player %s:\n\t", minetest.colorize("#ffea00", target))

		for _, rank in ipairs(mode_data.SUMMARY_RANKS) do
			return_str = string.format("%s%s: %s,\n\t",
				return_str,
				minetest.colorize("#63d437", HumanReadable(rank)),
				minetest.colorize("#ffea00", prank[rank] or 0)
			)
		end

		return_str = string.format("%s%s: %s",
			return_str,
			minetest.colorize("#63d437", "Place"),
			minetest.colorize("#ffea00", rankings.top:get_place(target))
		)

		return true, return_str
	end
}

ctf_modebase.register_chatcommand_alias(mode_tech_name, "rank", "r", rank_def)

ctf_modebase.register_chatcommand(mode_tech_name, "reset_rankings", {
	description = minetest.colorize("red", "Resets rankings of you or another player to nothing"),
	params = "[playername]",
	func = function(name, param)
		if param and param ~= "" then
			if minetest.check_player_privs(name, {ctf_admin = true}) then
				rankings:set(param, {}, true)

				return true, "Rankings reset for player "..param
			else
				return false, "The ctf_admin priv is required to reset the rankings of other players!"
			end
		else
			rankings:set(name, {}, true)

			return true, "Your rankings have been reset"
		end
	end
})

ctf_modebase.register_chatcommand(mode_tech_name, "makepro", {
	description = "Make yourself or another player into a pro",
	params = "[playername]",
	privs = {ctf_admin = true},
	func = function(name, param)
		if not param or param == "" then
			param = name
		end

		rankings:set(param, {score = 10000, kills = 15, deaths = 10, flag_captures = 10})

		return true, "Player "..param.." is now a pro!"
	end
})

ctf_modebase.register_chatcommand(mode_tech_name, "add_score", {
	description = "Add score to player",
	params = "[playername] [score]",
	privs = {ctf_admin = true},
	func = function(name, param)
		local pname, score = string.match(param, "^(.*) (.*)$")

		if not pname then
			return false, "You should provide the player name"
		end

		score = tonumber(score)
		if not score then
			return false, "You should provide score amount"
		end

		local old_ranks = rankings:get(pname)
		if not old_ranks then
			return false, string.format("Player %s has no rankings", pname)
		end

		local old_score = old_ranks.score or 0
		rankings:set(pname, {score = old_score + score})

		return true, string.format("Added %d score to player %s", score, pname)
	end
})

ctf_modebase.register_chatcommand(mode_tech_name, "top50", {
	description = "Show the top 50 players",
	func = function(name)
		local top50 = {}

		for i, pname in ipairs(rankings.top:get_top(50)) do
			local t = table.copy(rankings:get(pname) or {})
			t.pname = pname
			table.insert(top50, t)
		end

		local own_pos = rankings.top:get_place(name)
		if own_pos > 50 then
			local t = table.copy(rankings:get(name) or {})
			t.pname = name
			t.number = own_pos
			table.insert(top50, t)
		end

		ctf_modebase.show_summary_gui_sorted(name, top50, {}, mode_data.SUMMARY_RANKS, {
			title = "Top 50 Players",
			gamemode = ctf_modebase.current_mode,
			disable_nonuser_colors = true,
		})
	end,
})

return {
	add = function(player, amounts, no_hud)
		local hud_text = ""
		player = PlayerName(player)

		for name, val in pairs(amounts) do
			hud_text = string.format("%s+%d %s | ", hud_text, val, HumanReadable(name))
		end

		add_recent(rankings_recent, player, amounts)

		if rankings_recent[player]._team then
			add_recent(rankings_teams, rankings_recent[player]._team, amounts)
		end

		if not no_hud then
			hud_events.new(player, {text = hud_text:sub(1, -4)})
		end

		rankings:add(player, amounts)
	end,
	set_team = function(player, team)
		player = PlayerName(player)
		local tcolor = ctf_teams.team[team].color

		if not rankings_recent[player] then
			rankings_recent[player] = {}
		end

		if not rankings_teams[team] then
			rankings_teams[team] = {}
		end

		rankings_recent[player]._row_color = tcolor
		rankings_recent[player]._team = team
	end,
	get = function(player, specific)
		local rank = rankings:get(player)

		return (specific and rank[specific]) or rank
	end,
	on_leaveplayer = function(player)
		player = PlayerName(player)
		if rankings_recent[player] and rankings_recent[player]._team then
			clear_recent(rankings_teams, rankings_recent[player]._team)
		end
		clear_recent(rankings_recent, player)
	end,
	on_match_end = function()
		rankings_recent = {}
		rankings_teams = {}
	end,
	recent = function() return rankings_recent end,
	teams  = function() return rankings_teams  end,
}

end
