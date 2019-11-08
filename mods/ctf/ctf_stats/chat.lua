-------------
-- Helpers --
-------------

local function return_as_chat_result(to, name)
	local players = {}
	for pname, pstat in pairs(ctf_stats.players) do
		pstat.name = pname
		pstat.color = nil
		table.insert(players, pstat)
	end

	table.sort(players, function(one, two)
		return one.score > two.score
	end)

	local place = -1
	local me = nil
	for i = 1, #players do
		local pstat = players[i]
		if pstat.name == name then
			me = pstat
			place = i
			break
		end
	end
	if place < 1 then
		place = #players + 1
	end
	local you_are_in = (to == name) and "You are in " or name .. " is in "
	local result = you_are_in .. place .. " place.\n"
	if me then
		local kd = me.kills
		if me.deaths > 1 then
			kd = kd / me.deaths
		end
		result = result .. "Kills: " .. me.kills ..
			" | Deaths: " .. me.deaths ..
			" | K/D: " .. math.floor(kd * 10) / 10 ..
			"\nBounty kills: " .. me.bounty_kills ..
			" | Captures: " .. me.captures ..
			" | Attempts: " .. me.attempts ..
			"\nScore: " .. math.floor(me.score)
	end
	return true, result
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
	params = "[<name>]",
	description = "Display rankings of yourself or another player as a chat result.",
	func = function(name, param)
		local target
		if param ~= "" then
			param = param:trim()
			if ctf_stats.players[param] then
				target = param
				minetest.log("action", name .. " ran /r " .. param)
			else
				return false, "Can't find player '" .. param .. "'"
			end
		else
			target = name
			minetest.log("action", name .. " ran /r")
		end
		return return_as_chat_result(name, target)
	end
})

minetest.register_chatcommand("rankings", {
	params = "[<name>]",
	description = "Display rankings of yourself or another player.",
	func = function(name, param)
		local target
		if param ~= "" then
			param = param:trim()
			if ctf_stats.players[param] then
				target = param
				minetest.log("action", name .. " ran /rankings " .. param)
			else
				return false, "Can't find player '" .. param .. "'"
			end
		else
			target = name
			minetest.log("action", name .. " ran /rankings")
		end

		if not minetest.get_player_by_name(name) then
			return return_as_chat_result(name, target)
		else
			local players = {}
			for pname, pstat in pairs(ctf_stats.players) do
				pstat.name = pname
				pstat.color = nil
				table.insert(players, pstat)
			end

			local fs = ctf_stats.get_formspec("Player Rankings", players, 0, target)
			minetest.show_formspec(name, "ctf_stats:rankings", fs)
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
