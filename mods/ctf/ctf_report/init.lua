ctf_report = {
	registered_on_report = {},
	staff = {},
}

local S = minetest.get_translator(minetest.get_current_modname())

---@param func function (name, message)
function ctf_report.register_on_report(func)
	table.insert(ctf_report.registered_on_report, func)
end

function ctf_report.default_send_report(msg)
	for name in pairs(ctf_report.staff) do
		minetest.sound_play("ctf_report_bell", {
			to_player = name,
			gain = 1.0,
		}, true)
		minetest.chat_send_player(name, minetest.colorize("#ffcc00", "[REPORT]: " .. msg))
	end
end

ctf_report.send_report = ctf_report.default_send_report

local function string_difference(str1, str2)
	local count = math.abs(str1:len() - str2:len())

	for i=1, math.min(str1:len(), str2:len()) do
		if str1[i] ~= str2[i] then
			count = count + 1
		end
	end

	return count
end

local timers   = {}
local cooldown = {}
minetest.register_chatcommand("report", {
	params = S("<msg>"),
	description = S("Report misconduct or bugs"),
	func = function(name, param)
		param = param:trim()
		if param == "" then
			return false, S("Please add a message to your report.") .. " " ..
				S("If it's about (a) particular player(s), please also include their name(s).")
		end

		-- Count the number of words, by counting for replaced spaces
		-- Number of spaces = Number of words - 1
		local _, count = string.gsub(param, " ", "")
		if count == 0 then
			return false,
				S("If you're reporting a player,") .. " " ..
				S("you should also include a reason why (e.g. swearing, griefing, spawnkilling, etc.).")
		end

		if not cooldown[name] or string_difference(cooldown[name], param) >= 6 then
			cooldown[name] = param

			if timers[name] then
				timers[name]:cancel()
			end

			timers[name] = minetest.after(30, function()
				cooldown[name] = nil
				timers[name] = nil
			end)
		else
			return false, "You are sending reports too fast. You only need to report things once"
		end

		local msg = name .. " reported: " .. param

		-- Append player team for every player
		msg = msg:gsub("%S+", function(pname)
			local team = ctf_teams.get(pname)
			if team then
				pname = string.format("%s (team %s)", pname, team)
			end
			return pname
		end)

		RunCallbacks(ctf_report.registered_on_report, name, msg)

		-- Append list of staff in-game
		local staff = ""
		for pname in pairs(ctf_report.staff) do
			staff = staff .. pname .. ", "
		end

		if staff ~= "" then
			msg = msg .. " (staff online: " .. staff:sub(1, -3) .. ")"
		end

		ctf_report.send_report(msg)

		return true, S("Report has been sent.")
	end
})

minetest.register_on_joinplayer(function(player)
	if minetest.check_player_privs(player, { kick = true }) then
		ctf_report.staff[player:get_player_name()] = true
	end
end)

minetest.register_on_leaveplayer(function(player)
	ctf_report.staff[player:get_player_name()] = nil
end)
