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
	params = "[mode:technical modename] <playername>",
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

		local kills = 0
		local deaths = 1
		for _, rank in ipairs(mode_data.summary_ranks) do
			return_str = string.format("%s%s: %s,\n\t",
				return_str,
				minetest.colorize("#63d437", HumanReadable(rank)),
				minetest.colorize("#ffea00", math.round(prank[rank] or 0))
			)
			if rank == "kills" then
				kills = prank[rank] or 0
			end
			if rank == "deaths" then
				deaths = prank[rank] or 1
			end
		end

		if deaths == 0 then
			deaths = 1
		end

		return_str = string.format("%s%s: %s,\n\t",
			return_str,
			minetest.colorize("#63d437", "K/D"),
			minetest.colorize("#ffea00", tostring(kills/deaths))
		)

		return_str = string.format("%s%s: %s",
			return_str,
			minetest.colorize("#63d437", "Place"),
			minetest.colorize("#ffea00", mode_data.rankings.top:get_place(pname))
		)

		return true, return_str
	end
})

local donate_timer = {}

ctf_api.register_on_match_end(function()
	donate_timer = {}
end)

minetest.register_chatcommand("donate", {
	description = "Donate your match score to your teammate\nCan be used only once in 10 minutes",
	params = "<playername> <score>",
	func = function(name, param)
		local current_mode = ctf_modebase:get_current_mode()
		if not current_mode or not ctf_modebase.match_started then
			return false, "The match hasn't started yet!"
		end

		local pname, score = string.match(param, "^(.*) (.*)$")

		if not pname then
			return false, "You should provide the player name!"
		end

		score = ctf_core.to_number(score)
		if not score then
			return false, "You should provide score amount!"
		end

		score = math.floor(score)

		if score < 5 then
			return false, "You should donate at least 5 score!"
		end

		if score > 100 then
			return false, "You can donate no more than 100 score!"
		end

		if pname == name then
			return false, 'You cannot donate to yourself!'
		end

		local team = ctf_teams.get(pname)

		if not team then
			return false, string.format("Player %s is not online!", pname)
		end

		if team ~= ctf_teams.get(name) then
			return false, string.format("Player %s is not on your team!", pname)
		end

		local cur_score = math.min(
			current_mode.recent_rankings.get(name).score or 0,
			(current_mode.rankings:get(name) or {}).score or 0
		)
		if score > cur_score / 2 then
			return false, "You can donate only half of your match score!"
		end

		if donate_timer[name] and donate_timer[name] + 600 > os.time() then
			return false, "You can donate only once in 10 minutes!"
		end

		current_mode.recent_rankings.add(pname, {score=score}, true)
		current_mode.recent_rankings.add(name, {score=-score}, true)

		donate_timer[name] = os.time()

		minetest.chat_send_all(minetest.colorize("#00EEFF",
			string.format("%s donated %s score to %s for their hard work", name, score, pname)
		))
		minetest.log("action", string.format(
			"Player '%s' donated %s score to player '%s'", name, score, pname
		))
		return true
	end
})

local allow_reset = {}
minetest.register_chatcommand("reset_rankings", {
	description = minetest.colorize("red", "Resets rankings of you or another player to nothing"),
	params = "[mode:technical modename] <playername>",
	func = function(name, param)
		local mode_name, mode_data, pname = get_gamemode(param)
		if not mode_name then
			return false, mode_data
		end

		if pname then
			if minetest.check_player_privs(name, {ctf_admin = true}) then
				mode_data.rankings:set(pname, {}, true)

				minetest.log("action", string.format(
					"[ctf_admin] %s reset rankings for player '%s' in mode %s", name, pname, mode_name
				))
				return true, string.format("Rankings reset for player '%s' in mode %s", pname, mode_name)
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

			minetest.log("action", string.format(
				"Player '%s' reset their rankings in mode %s", name, mode_name
			))
			return true, "Your rankings have been reset"
		end
	end
})

minetest.register_chatcommand("top50", {
	description = "Show the top 50 players",
	params = "[mode:technical modename]",
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

minetest.register_chatcommand("make_pro", {
	description = "Make yourself or another player a pro",
	params = "[mode:technical modename] <playername>",
	privs = {ctf_admin = true},
	func = function(name, param)
		local mode_name, mode_data, pname = get_gamemode(param)
		if not mode_name then
			return false, mode_data
		end

		if not pname then
			return false, "You should provide the player name!"
		end

		local old_ranks = mode_data.rankings:get(pname)
		if not old_ranks then
			return false, string.format("Player '%s' has no rankings!", pname)
		end

		mode_data.rankings:add(pname, {score = 8000, kills = 7, deaths = 5, flag_captures = 5})

		minetest.log("action", string.format(
			"[ctf_admin] %s made player '%s' a pro in mode %s: %s", name, pname, mode_name, dump(old_ranks)
		))
		return true, string.format("Player '%s' is now a pro!", pname)
	end
})

minetest.register_chatcommand("add_score", {
	description = "Add score to player",
	params = "[mode:technical modename] <playername> <score>",
	privs = {ctf_admin = true},
	func = function(name, param)
		local mode_name, mode_data, opt_param = get_gamemode(param)
		if not mode_name then
			return false, mode_data
		end

		local pname, score = string.match(opt_param or "", "^(.*) (.*)$")

		if not pname then
			return false, "You should provide the player name!"
		end

		score = ctf_core.to_number(score)
		if not score then
			return false, "You should provide score amount!"
		end

		local old_ranks = mode_data.rankings:get(pname)
		if not old_ranks then
			return false, string.format("Player '%s' has no rankings!", pname)
		end

		local old_score = old_ranks.score or 0
		mode_data.rankings:set(pname, {score = old_score + score})

		minetest.log("action", string.format(
			"[ctf_admin] %s added %s score to player '%s' in mode %s", name, score, pname, mode_name
		))
		return true, string.format("Added %s score to player '%s'", score, pname)
	end
})

minetest.register_chatcommand("transfer_rankings", {
	description = "Transfer rankings of one player to another.",
	params = "<src> <dest>",
	privs = {ctf_admin = true},
	func = function(name, param)
		local src, dst = param:trim():match("^(.*) (.*)$")

		if not src then
			return false, "You should provide source player name!"
		end
		if not dst then
			return false, "You should provide destination player name!"
		end

		local src_rankings = {}
		local dst_rankings = {}
		local src_exists = false
		local dst_exists = false

		for mode_name, mode in pairs(ctf_modebase.modes) do
			local src_rank = mode.rankings:get(src)
			src_rankings[mode_name] = src_rank or {}
			if src_rank then
				src_exists = true
			end

			local dst_rank = mode.rankings:get(dst)
			dst_rankings[mode_name] = dst_rank or {}
			if dst_rank then
				dst_exists = true
			end
		end

		if not src_exists then
			return false, string.format("Source player '%s' has no rankings!", src)
		end
		if not dst_exists then
			return false, string.format("Destination player '%s' has no rankings!", dst)
		end

		if src == dst then
			return false, "Source name and destination name cannot be the same!"
		end

		for mode_name, mode in pairs(ctf_modebase.modes) do
			mode.rankings:add(dst, src_rankings[mode_name])
		end

		for _, mode in pairs(ctf_modebase.modes) do
			mode.rankings:set(src, {}, true)
		end

		minetest.log("action", string.format(
			"[ctf_admin] %s transferred rankings from '%s' to '%s': %s -> %s",
			name, src, dst, dump(src_rankings), dump(dst_rankings)
		))
		return true, string.format("Rankings of '%s' have been transferred to '%s'", src, dst)
	end
})
