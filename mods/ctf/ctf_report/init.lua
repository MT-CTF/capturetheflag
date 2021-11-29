ctf_report = {staff = {}}

function ctf_report.default_send_report(msg)
	for name in pairs(ctf_report.staff) do
		minetest.chat_send_player(name, '[REPORT] ' .. msg)
	end
end

ctf_report.send_report = ctf_report.default_send_report

minetest.register_chatcommand("report", {
	params = "<msg>",
	description = "Report misconduct or bugs",
	func = function(name, param)
		param = param:trim()
		if param == "" then
			return false, "Please add a message to your report. " ..
				"If it's about (a) particular player(s), please also include their name(s)."
		end

		-- Count the number of words, by counting for replaced spaces
		-- Number of spaces = Number of words - 1
		local _, count = string.gsub(param, " ", "")
		if count == 0 then
			return false, "If you're reporting a player, you should" ..
				" also include a reason why (e.g. swearing, griefing, spawnkilling, etc.)."
		end

		local msg = name .. " reported: " .. param

		-- Append player team for every player
		msg = msg:gsub("[^ ]+", function(pname)
			local team = ctf_teams.get(pname)
			if team then
				pname = string.format("%s (team %s)", pname, team)
			end
			return pname
		end)

		-- Append list of staff in-game
		local staff = ""
		for pname in pairs(ctf_report.staff) do
			staff = staff .. pname .. ", "
		end

		if staff ~= "" then
			msg = msg .. " (staff online: " .. staff:sub(0, -3) .. ")"
		end

		ctf_report.send_report(msg)

		return true, "Report has been sent."
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
