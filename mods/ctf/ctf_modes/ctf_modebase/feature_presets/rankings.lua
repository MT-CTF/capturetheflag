-- dofile(filepath)("mode_technical_name", mode_data)
-- mode_data must hold variables: SUMMARY_RANKS

return function(mode_tech_name, mode_data)

local rankings = ctf_rankings.init()

-- can't call minetest.get_mod_storage() twice, the modstorage rankings backend calls it first
local mods = rankings.modstorage or minetest.get_mod_storage()

rankings.total = {}
rankings.top_50 = minetest.deserialize(mods:get_string("top_50")) or {}

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

		return true, return_str:sub(1, -3)
	end
}

ctf_modebase.register_chatcommand(mode_tech_name, "rank", rank_def)
ctf_modebase.register_chatcommand(mode_tech_name, "r"   , rank_def)

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

ctf_modebase.register_chatcommand(mode_tech_name, "top50", {
	description = "Show the top 50 players",
	func = function(name)
		local top50 = {}

		for _, pname in pairs(rankings.top_50) do
			top50[pname] = rankings:get(pname) or nil
		end

		ctf_modebase.show_summary_gui(name, top50, mode_data.SUMMARY_RANKS, {
			title = "Top 50 Players",
			disable_nonuser_colors = true
		})
	end,
})

local function update_top_50()
	local cache = {}

	table.sort(rankings.top_50, function(a, b)
		if not cache[a] then cache[a] = rankings:get(a) or {score = 0} end
		if not cache[b] then cache[b] = rankings:get(b) or {score = 0} end

		return (cache[a].score or 0) < (cache[b].score or 0)
	end)

	mods:set_string("top_50", minetest.serialize(rankings.top_50))
end

return {
	add = function(player, amounts, no_hud)
		local hud_text = ""
		local pteam = ctf_teams.get(player)
		player = PlayerName(player)

		for name, val in pairs(amounts) do
			hud_text = string.format("%s+%d %s | ", hud_text, val, HumanReadable(name))
		end

		if amounts.score then -- handle top50
			local current = rankings:get(player)

			if table.indexof(rankings.top_50, player) == -1 then
				if rankings.top_50[50] then
					if (current and current.score or 0) + amounts.score > rankings:get(rankings.top_50[50]).score then
						table.remove(rankings.top_50)
						table.insert(rankings.top_50, player)

						update_top_50()
					end
				else
					table.insert(rankings.top_50, player)
					update_top_50()
				end
			else
				update_top_50()
			end
		end

		if pteam then
			if not rankings.total[pteam] then
				rankings.total[pteam] = {}
			end

			for stat, amount in pairs(amounts) do
				rankings.total[pteam][stat] = (rankings.total[pteam][stat] or 0) + amount
			end
		end

		if not no_hud then
			hud_events.new(player, {text = hud_text:sub(1, -4)})
		end

		rankings:add(player, amounts)
	end,
	set_team = function(player, team)
		local pname = PlayerName(player)
		local tcolor = ctf_teams.team[team].color

		if not rankings.recent[pname] then
			rankings.recent[pname] = {_row_color = tcolor, _group = team}
		else
			rankings.recent[pname]._row_color = tcolor
			rankings.recent[pname]._group = team
		end
	end,
	get = function(player, specific)
		local rank = rankings:get(player)

		return (specific and rank[specific]) or rank
	end,
	reset_recent = function(player)
		rankings.recent[player] = nil
	end,
	next_match = function()
		rankings.previous_recent = table.copy(rankings.recent)
		rankings.previous_total  = table.copy(rankings.total )
		rankings.recent = {}
		rankings.total = {}
	end,
	total           = function() return rankings.total           end,
	previous_total  = function() return rankings.previous_total  end,
	recent          = function() return rankings.recent          end,
	previous_recent = function() return rankings.previous_recent end,
}

end
