-------------
-- Helpers --
-------------

local function return_as_chat_result(to, target)
	local name, pstat
	if type(target) == "number" then
		name  = ctf_stats.ranks[target]
		pstat = ctf_stats.player_by_rank(target)
	elseif type(target) == "string" then
		name  = target
		pstat = ctf_stats.player_or_nil(name)
	else
		error("Invalid type passed to return_as_chat_result!", 2)
	end

	if pstat then
		-- Build return string
		local result = (to == name and "You are in " or name .. " is in ") ..
			pstat.rank .. " place.\n"

		local kd = pstat.kills
		if pstat.deaths > 1 then
			kd = kd / pstat.deaths
		end
		result = result ..
			"Kills: "          .. pstat.kills ..
			" | Deaths: "      .. pstat.deaths ..
			" | K/D: "         .. math.floor(kd * 10) / 10 ..
			"\nBounty kills: " .. pstat.bounty_kills ..
			" | Captures: "    .. pstat.captures ..
			" | Attempts: "    .. pstat.attempts ..
			"\nScore: "        .. math.floor(pstat.score)

		return result
	else
		return "Invalid player stats!"
	end
end

local function summary_func(name)
	local fs = ctf_stats.get_formspec_match_summary(ctf_stats.current,
	ctf_stats.winner_team, ctf_stats.winner_player, ctf_match.get_match_duration())

	fs = fs .. "button[6,7.5;4,1;b_prev;<< Previous match]"

	minetest.log("action", name .. " requested match summary formspec")
	minetest.show_formspec(name, "ctf_stats:match_summary", fs)
end

-------------------
-- Chat-commands --
-------------------

minetest.register_chatcommand("summary", {
	description = "Display the match summary",
	func = summary_func
})

minetest.register_chatcommand("s", {
	description = "Display the match summary",
	func = summary_func
})

minetest.register_chatcommand("r", {
	params = "[<name> | <rank>]",
	description = "Display rankings of yourself, or another player or rank, as a chat result.",
	func = function(name, param)
		local target, error = ctf_stats.get_target(name, param)
		if not target then
			return false, error
		end

		minetest.log("action", name .. " runs /r " .. param)
		return true, return_as_chat_result(name, target)
	end
})

minetest.register_chatcommand("rn", {
	params = "<rank>",
	description = "Display rankings of player at the specified rank.",
	func = function(name, param)
		if not param or param == "" then
			return false, "Empty arguments not allowed! Specify a rank."
		end

		if not ctf_stats.player_by_rank(param) then
			return false, "Invalid input!"
		end

		minetest.log("action", name .. " runs /rn " .. param)
		return true, return_as_chat_result(name, param)
	end
})

minetest.register_chatcommand("rankings", {
	params = "[<name> | <rank>]",
	description = "Display rankings of yourself, or another player or rank.",
	func = function(name, param)
		local target, error = ctf_stats.get_target(name, param)
		if not target then
			return false, error
		end

		minetest.log("action", name .. " runs /rankings " .. param)
		if not minetest.get_player_by_name(name) then
			return true, return_as_chat_result(name, target)
		else
			local players = table.copy(ctf_stats.ranks)
			for i, pname in pairs(players) do
				players[i] = ctf_stats.players[pname]
				if i == ctf_stats.rankings_display_count then
					break
				end
			end
			minetest.show_formspec(name, "ctf_stats:rankings", ctf_stats.get_formspec(
					"Player Rankings", players, 0, target))
			return true
		end
	end
})

local reset_y = {}
minetest.register_chatcommand("reset_rankings", {
	params = "[<name>]",
	description = "Reset the rankings of yourself or another player",
	func = function(name, param)
		param = param:trim()
		if param ~= "" and not minetest.check_player_privs(name, {ctf_admin = true}) then
			return false, "Missing privilege: ctf_admin"
		end

		local reset_name = param == "" and name or param

		if not ctf_stats.players[reset_name] then
			return false, "Player '" .. reset_name .. "' does not exist."
		end

		if reset_name == name and not reset_y[name] then
			reset_y[name] = true
			minetest.after(30, function()
				reset_y[name] = nil
			end)
			return true, "This will reset your stats and rankings completely."
				.. " You will lose access to any special privileges such as the"
				.. " team chest or userlimit skip. This is irreversable. If you're"
				.. " sure, re-type /reset_rankings within 30 seconds to reset."
		end
		reset_y[name] = nil

		ctf_stats.players[reset_name] = nil
		ctf_stats.player(reset_name)

		if reset_name == name then
			minetest.log("action", name .. " reset their rankings")
		else
			minetest.log("action", name .. " reset rankings of " .. reset_name)
		end

		return true, "Successfully reset the stats and ranking of " .. reset_name
	end
})

minetest.register_chatcommand("transfer_rankings", {
	params = "<src> <dest>",
	description = "Transfer rankings of one player to another.",
	privs = {ctf_admin = true},
	func = function(name, param)
		if not param then
			return false, "Invalid syntax. Provide source and destination player names."
		end
		param = param:trim()
		local src, dest = param:trim():match("([%a%d_-]+) ([%a%d_-]+)")
		if not src or not dest then
			return false, "Invalid usage, see /help transfer_rankings"
		end
		if not ctf_stats.players[src] then
			return false, "Player '" .. src .. "' does not exist."
		end
		if not ctf_stats.players[dest] then
			return false, "Player '" .. dest .. "' does not exist."
		end
		if src == dest then
			return false, "Source name and destination name cannot be the same!"
		end

		ctf_stats.players[dest] = ctf_stats.players[src]
		ctf_stats.players[src] = nil

		minetest.log("action", name .. " transferred stats of " .. src .. " to " .. dest)
		return true, "Stats of '" .. src .. "' have been transferred to '" .. dest .. "'."
	end
})


minetest.register_chatcommand("makepro", {
	description = "Make self a pro",
	privs = {ctf_admin = true},
	func = function(name, param)
		local stats, _ = ctf_stats.player(name)

		if stats.kills < 1.5 * (stats.deaths + 1) then
			stats.kills = 1.51 * (stats.deaths + 1)
		end

		if stats.score < 10000 then
			stats.score = 10000
		end

		return true, "Done"
	end
})
