local function get_gamemode(param)
	local opt_param, mode_param = ctf_modebase.match_mode(param)

	if mode_param then
		local mode = ctf_modebase.modes[mode_param]
		if not mode then
			return false, "No such game mode: " .. mode_param
		end

		return mode_param, mode, opt_param
	else
		local current_mode = ctf_modebase:get_current_mode()
		if not current_mode then
			return false, "The game isn't running"
		end

		return ctf_modebase.current_mode, current_mode, opt_param
	end
end

ctf_core.register_chatcommand_alias("rank", "r", {
	description = "Get the rank of yourself or a player",
	params = "<mode:technical modename> <playername>",
	func = function(name, param)
		local mode_name, mode_data, pname = get_gamemode(param)
		if not mode_name then
			return false, mode_data
		end

		if not pname then
			pname = name
		end
		local prank = mode_data.rankings:get(pname) -- [p]layer [rank]

		if not prank then
			return false, string.format("Player %s has no rankings in mode %s!", pname, mode_name)
		end

		local return_str = string.format(
			"Rankings for player %s in mode %s:\n\t", minetest.colorize("#ffea00", pname), mode_name
		)

		for _, rank in ipairs(mode_data.summary_ranks) do
			return_str = string.format("%s%s: %s,\n\t",
				return_str,
				minetest.colorize("#63d437", HumanReadable(rank)),
				minetest.colorize("#ffea00", math.round(prank[rank] or 0))
			)
		end

		return_str = string.format("%s%s: %s",
			return_str,
			minetest.colorize("#63d437", "Place"),
			minetest.colorize("#ffea00", mode_data.rankings.top:get_place(pname))
		)

		return true, return_str
	end
})

local allow_reset = {}
minetest.register_chatcommand("reset_rankings", {
	description = minetest.colorize("red", "Resets rankings of you or another player to nothing"),
	params = "<mode:technical modename> <playername>",
	func = function(name, param)
		local mode_name, mode_data, pname = get_gamemode(param)
		if not mode_name then
			return false, mode_data
		end

		if pname then
			if minetest.check_player_privs(name, {ctf_admin = true}) then
				mode_data.rankings:set(pname, {}, true)

				return true, "Rankings reset for player " .. pname
			else
				return false, "The ctf_admin priv is required to reset the rankings of other players!"
			end
		else
			local key = string.format("%s:%s", mode_name, name)
			if not allow_reset[key] then
				allow_reset[key] = true

				minetest.after(30, function()
					allow_reset[key] = nil
				end)

				return true, "This will reset your stats and rankings for " .. mode_name .." mode completely."
					.. " You will lose access to any special privileges such as the"
					.. " team chest or userlimit skip. This is irreversable. If you're"
					.. " sure, re-type /reset_rankings within 30 seconds to reset."
			end
			mode_data.rankings:set(name, {}, true)
			allow_reset[key] = nil

			return true, "Your rankings have been reset"
		end
	end
})

minetest.register_chatcommand("makepro", {
	description = "Make yourself or another player into a pro",
	params = "<mode:technical modename> <playername>",
	privs = {ctf_admin = true},
	func = function(name, param)
		local mode_name, mode_data, pname = get_gamemode(param)
		if not mode_name then
			return false, mode_data
		end

		if not pname then
			return false, "You should provide the player name"
		end

		mode_data.rankings:set(pname, {score = 10000, kills = 15, deaths = 10, flag_captures = 10})

		return true, "Player " .. pname .. " is now a pro!"
	end
})

minetest.register_chatcommand("addscore", {
	description = "Add score to player",
	params = "<mode:technical modename> [playername] [score]",
	privs = {ctf_admin = true},
	func = function(name, param)
		local mode_name, mode_data, opt_param = get_gamemode(param)
		if not mode_name then
			return false, mode_data
		end

		local pname, score = string.match(opt_param or "", "^(.*) (.*)$")

		if not pname then
			return false, "You should provide the player name"
		end

		score = tonumber(score)
		if not score then
			return false, "You should provide score amount"
		end

		local old_ranks = mode_data.rankings:get(pname)
		if not old_ranks then
			return false, string.format("Player %s has no rankings", pname)
		end

		local old_score = old_ranks.score or 0
		mode_data.rankings:set(pname, {score = old_score + score})

		return true, string.format("Added %s score to player %s", score, pname)
	end
})

minetest.register_chatcommand("top50", {
	description = "Show the top 50 players",
	params = "<mode:technical modename>",
	func = function(name, param)
		local mode_name, mode_data = get_gamemode(param)
		if not mode_name then
			return false, mode_data
		end

		local top50 = {}

		for i, pname in ipairs(mode_data.rankings.top:get_top(50)) do
			local t = table.copy(mode_data.rankings:get(pname) or {})
			t.pname = pname
			table.insert(top50, t)
		end

		local own_pos = mode_data.rankings.top:get_place(name)
		if own_pos > 50 then
			local t = table.copy(mode_data.rankings:get(name) or {})
			t.pname = name
			t.number = own_pos
			table.insert(top50, t)
		end

		ctf_modebase.summary.show_gui_sorted(name, top50, {}, mode_data.summary_ranks, {
			title = "Top 50 Players",
			gamemode = mode_name,
			disable_nonuser_colors = true,
		})
	end,
})
