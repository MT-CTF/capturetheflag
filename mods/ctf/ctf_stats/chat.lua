-------------
-- Helpers --
-------------

local function return_as_chat_result(to, target)
	local players = ctf_stats.get_ordered_players()

	local name, place, stat
	if type(target) == "number" then
		place = target
		stat  = players[target]
		name  = stat.name
	elseif type(target) == "string" then
		-- If target is a string, search through the player stats for a match
		name = target
		for i = 1, #players do
			local pstat = players[i]
			if pstat.name == name then
				stat = pstat
				place = i
				break
			end
		end

		-- If stat does not exist yet, set place to size of players + 1
		if place < 1 then
			place = #players + 1
		end
	else
		error("Invalid type passed to return_as_chat_result!", 2)
	end

	-- Build return string
	local result = (to == name and "You are in " or name .. " is in ") ..
			place .. " place.\n"

	if stat then
		local kd = stat.kills
		if stat.deaths > 1 then
			kd = kd / stat.deaths
		end
		result = result ..
			"Kills: " .. stat.kills ..
			" | Deaths: " .. stat.deaths ..
			" | K/D: " .. math.floor(kd * 10) / 10 ..
			"\nBounty kills: " .. stat.bounty_kills ..
			" | Captures: " .. stat.captures ..
			" | Attempts: " .. stat.attempts ..
			"\nScore: " .. math.floor(stat.score)
	end
	return result
end

-------------------
-- Chat-commands --
-------------------

minetest.register_chatcommand("summary", {
	func = function(name)
		local fs = ctf_stats.get_formspec_match_summary(ctf_stats.current,
			ctf_stats.winner_team, ctf_stats.winner_player, os.time() - ctf_stats.start)

		fs = fs .. "button[6,7.5;4,1;b_prev;<< Previous match]"

		minetest.log("action", name .. " requested match summary formspec")
		minetest.show_formspec(name, "ctf_stats:match_summary", fs)
	end
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

		param = tonumber(param)
		if not param then
			return false, "Argument isn't a valid number!"
		elseif param <= 0 or param > #ctf_stats.get_ordered_players() or
				param ~= math.floor(param) then
			return false, "Invalid number or number out of bounds!"
			-- TODO: This is the worst way to do it. FIX IT.
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
			minetest.show_formspec(name, "ctf_stats:rankings", ctf_stats.get_formspec(
					"Player Rankings", ctf_stats.get_ordered_players(), 0, target))
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

		ctf_stats.players[dest] = ctf_stats.players[src]
		ctf_stats.players[src] = nil

		minetest.log("action", name .. " transferred stats of " .. src .. " to " .. dest)
		return true, "Stats of '" .. src .. "' have been transferred to '" .. dest .. "'."
	end
})
