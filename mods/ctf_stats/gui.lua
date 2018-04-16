function ctf_stats.get_formspec_match_summary(stats, winner_team, winner_player, time)
	local players = {}
	for name, pstat in pairs(stats.red) do
		pstat.name = name
		pstat.color = ctf.flag_colors.red
		table.insert(players, pstat)
	end
	for name, pstat in pairs(stats.blue) do
		pstat.name = name
		pstat.color = ctf.flag_colors.blue
		table.insert(players, pstat)
	end

	local ret = ctf_stats.get_formspec("Match Summary", players, 1)

	if stats[winner_team] then
		local winner_color = ctf.flag_colors[winner_team]:gsub("0x", "#")
		ret = ret .. "item_image[0,0;1,1;ctf_flag:flag_top_"..winner_team.."]"
		ret = ret .. "label[1,0;" .. minetest.colorize(winner_color, "TEAM " .. winner_team:upper() .. " WON!") .. "]"
		ret = ret .. "label[1,0.5;Flag captured by " .. winner_player .. "]"
	else
		ret = ret .. "label[1,0;NO WINNER]"
	end

	local total_kills = 0
	local total_attempts = 0
	local total_score = 0
	for i, pstat in ipairs(players) do
		total_kills = total_kills + pstat.kills
		total_attempts = total_attempts + pstat.attempts
		total_score = total_score + pstat.score
	end

	ret = ret .. "label[4,0;Kills]"
	ret = ret .. "label[6,0;" .. total_kills .. "]"
	ret = ret .. "label[4,0.5;Attempts]"
	ret = ret .. "label[6,0.5;" .. total_attempts .. "]"

	local time_display = ""
	if time >= 3600 then
		time_display = math.floor(time/3600) .. "h"
	end
	time_display = time_display .. math.floor((time % 3600) / 60) .. "m" .. math.floor(time % 60) .. "s"
	ret = ret .. "label[8,0;Duration]"
	ret = ret .. "label[10,0;" .. time_display .. "]"
	ret = ret .. "label[8,0.5;Total score]"
	ret = ret .. "label[10,0.5;" .. math.floor(total_score*10)/10 .. "]"

	ret = ret .. "label[3.5,7.2;Tip: type /rankings for league tables]"
	return ret
end

function ctf_stats.get_formspec(title, players, header)
	table.sort(players, function(one, two)
		return one.score > two.score
	end)

	local ret = "size[12,"..6.5+header.."]"
	ret = ret .. "container[0,"..header.."]"

	ret = ret .. "vertlabel[0,0;" .. title .. "]"
	ret = ret .. "tablecolumns[color;text;text;text;text;text;text;text;text]"
	ret = ret .. "tableoptions[highlight=#00000000]"
	ret = ret .. "table[0.5,0;11.25,6;scores;"
	ret = ret .. "#ffffff,,username,kills,deaths,K/D ratio,captures,attempts,score"

	for i = 1, #players do
		local pstat = players[i]
		local color = pstat.color or "#ffffff"
		local kd = pstat.kills
		if pstat.deaths > 0 then
			kd = kd / pstat.deaths
		end
		ret = ret ..
			"," .. string.gsub(color, "0x", "#") ..
			"," .. i ..
			"," .. pstat.name ..
			"," .. pstat.kills ..
			"," .. pstat.deaths ..
			"," .. math.floor(kd*10)/10  ..
			"," .. pstat.captures ..
			"," .. pstat.attempts ..
			"," .. math.floor(pstat.score*10)/10
		if i > 49 then
			break
		end
	end

	ret = ret .. ";-1]"
	ret = ret .. "button_exit[0.5,6;3,1;close;Close]"
	ret = ret .. "container_end[]"
	return ret
end

function ctf_stats.get_html(title, players)
	table.sort(players, function(one, two)
		return one.score > two.score
	end)

	local ret = "<h1>" .. title .. "</h1>"
	ret = ret .. "<table>" ..
		"<tr><th></th>" ..
		"<th>username</th>" ..
		"<th>kills</th>" ..
		"<th>deaths</th>" ..
		"<th>K/D ratio</th>" ..
		"<th>captures</th>" ..
		"<th>attempts</th>" ..
		"<th>score</th></tr>"

	for i = 1, #players do
		local pstat = players[i]
		local kd = pstat.kills
		if pstat.deaths > 0 then
			kd = kd / pstat.deaths
		end
		ret = ret ..
			"<tr><td>" .. i ..
			"</td><td>" .. pstat.name ..
			"</td><td>" .. pstat.kills ..
			"</td><td>" .. pstat.deaths ..
			"</td><td>" .. math.floor(kd*10)/10 ..
			"</td><td>" .. pstat.captures ..
			"</td><td>" .. pstat.attempts ..
			"</td><td>" .. math.floor(pstat.score*10)/10 .. "</td></tr>"
		if i > 49 then
			break
		end
	end

	ret = ret .. "</table>\n"
	return ret
end

function ctf_stats.html_to_file(filepath)
	local players = {}
	for name, pstat in pairs(ctf_stats.players) do
		pstat.name = name
		pstat.color = nil
		table.insert(players, pstat)
	end
	local html = ctf_stats.get_html("Player Rankings", players)
	local f = io.open(filepath, "w")
	f:write("<!doctype html>\n")
	f:write("<html><head>\n")
	f:write("<meta charset=\"utf-8\">\n")
	f:write("<title>Player Rankings</title>\n")
	f:write("<link rel=\"stylesheet\" href=\"score_style.css\">\n")
	f:write("</head><body>\n")
	f:write(html)
	f:write("</body></html>\n")
	f:close()
end

local function send_as_chat_result(to, name)
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
	local you_are_in = (to == name) and "You are in " or "They are in "
	local result = you_are_in .. place .. " place.\n"
	if me then
		local kd = me.kills
		if me.deaths > 0 then
			kd = kd / me.deaths
		end
		result = result .. "Kills: " .. me.kills ..
			" | Deaths: " .. me.deaths ..
			" | K/D: " .. math.floor(kd*10)/10 ..
			" | Captures: " .. me.captures ..
			" | Attempts: " .. me.attempts ..
			" | Score: " .. math.floor(me.score)
	end
	return true, result
end

minetest.register_chatcommand("rankings", {
	func = function(name, param)
		if param == "me" then
			return send_as_chat_result(name, name)
		elseif param ~= "" then
			if ctf_stats.players[param:trim()] then
				return send_as_chat_result(name, param:trim())
			else
				return false, "Can't find player '" .. param:trim() .. "'"
			end
		else
			local players = {}
			for pname, pstat in pairs(ctf_stats.players) do
				pstat.name = pname
				pstat.color = nil
				table.insert(players, pstat)
			end
			local fs = ctf_stats.get_formspec("Player Rankings", players, 0)
			fs = fs .. "label[3.5,6.2;Tip: to see where you are, type /rankings me]"
			minetest.show_formspec(name, "ctf_stats:rankings", fs)
		end
	end
})

local reset_y = {}
minetest.register_chatcommand("reset_rankings", {
	func = function(name, param)
		param = param:trim()
		if param ~= "" and not minetest.check_player_privs(name, { ctf_admin = true}) then
			return false, "Missing privilege: ctf_admin"
		end

		local reset_name = param == "" and name or param

		if reset_name == name and not reset_y[name] then
			reset_y[name] = true
			return true, "This will reset your stats and rankings completely. You will lose access to any special privileges such as the team chest or userlimit skip. This is irreversable. If you're sure, type /reset_rankings again to perform the reset"
		end
		reset_y[name] = nil

		ctf_stats.players[name] = nil
		ctf_stats.player(reset_name)
		return true, "Reset the stats and ranking of " .. reset_name
	end
})
