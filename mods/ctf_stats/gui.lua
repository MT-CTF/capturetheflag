local storage = minetest.get_mod_storage()
local prev_match_summary = storage:get_string("prev_match_summary")

-- Formspec element that governs table columns and their attributes
local tablecolumns = {
	"tablecolumns[color;",
	"text;",
	"text,width=20;",
	"text,width=4;",
	"text,width=4;",
	"text,width=4;",
	"text,width=6;",
	"text,width=6;",
	"text,width=6;",
	"text,width=6]"
}
tablecolumns = table.concat(tablecolumns, "")

local function render_team_stats(red, blue, stat, round)
	local red_stat, blue_stat = red[stat], blue[stat]
	if round then
		red_stat  = math.floor(red_stat  * 10) / 10
		blue_stat = math.floor(blue_stat * 10) / 10
	end
	return red_stat + blue_stat .. " (" ..
			minetest.colorize(red.color, tostring(red_stat)) .. " - " ..
			minetest.colorize(blue.color, tostring(blue_stat)) .. ")"
end

function ctf_stats.get_formspec_match_summary(stats, winner_team, winner_player, time)
	local players = {}
	local red = {
		color = ctf.flag_colors.red:gsub("0x", "#"),
		kills = 0,
		attempts = 0,
		score = 0,
	}
	local blue = {
		color = ctf.flag_colors.blue:gsub("0x", "#"),
		kills = 0,
		attempts = 0,
		score = 0,
	}
	for name, pstat in pairs(stats.red) do
		pstat.name = name
		pstat.color = ctf.flag_colors.red
		table.insert(players, pstat)
		red.kills = red.kills + pstat.kills
		red.attempts = red.attempts + pstat.attempts
		red.score = red.score + pstat.score
	end
	for name, pstat in pairs(stats.blue) do
		pstat.name = name
		pstat.color = ctf.flag_colors.blue
		table.insert(players, pstat)
		blue.kills = blue.kills + pstat.kills
		blue.attempts = blue.attempts + pstat.attempts
		blue.score = blue.score + pstat.score
	end

	local match_length = string.format("%02d:%02d:%02d",
		math.floor(time / 3600),        -- hours
		math.floor((time % 3600) / 60), -- minutes
		math.floor(time % 60))          -- seconds

	local ret = ctf_stats.get_formspec("Match Summary", players, 1)

	if stats[winner_team] then
		local winner_color = ctf.flag_colors[winner_team]:gsub("0x", "#")
		ret = ret .. "item_image[0,0;1,1;ctf_flag:flag_top_"..winner_team.."]"
		ret = ret .. "label[1,0;" .. minetest.colorize(winner_color,
						"TEAM " .. winner_team:upper() .. " WON!") .. "]"
		ret = ret .. "label[1,0.5;Flag captured by " ..
						minetest.colorize(winner_color, winner_player) .. "]"
	else
		ret = ret .. "label[1,0;NO WINNER]"
	end

	ret = ret .. "label[6.5,0;Kills]"
	ret = ret .. "label[8,0;" .. render_team_stats(red, blue, "kills") .. "]"
	ret = ret .. "label[6.5,0.5;Attempts]"
	ret = ret .. "label[8,0.5;" .. render_team_stats(red, blue, "attempts") .. "]"
	ret = ret .. "label[10.5,0;Duration]"
	ret = ret .. "label[12,0;" .. match_length .. "]"
	ret = ret .. "label[10.5,0.5;Total score]"
	ret = ret .. "label[12,0.5;" .. render_team_stats(red, blue, "score", true) .. "]"
	ret = ret .. "label[2,7.75;Tip: type /rankings for league tables]"

	-- Set prev_match_summary and write to mod_storage
	prev_match_summary = ret
	storage:set_string("prev_match_summary", ret)

	return ret
end

function ctf_stats.get_formspec(title, players, header, hlt_name)
	table.sort(players, function(one, two)
		return one.score > two.score
	end)

	local ret = "size[14," .. 7 + header .. "]"
	ret = ret .. default.gui_bg .. default.gui_bg_img
	ret = ret .. "container[0," .. header .. "]"

	ret = ret .. "vertlabel[0,1;" .. title .. "]"
	ret = ret .. tablecolumns
	ret = ret .. "tableoptions[highlight=#00000000]"
	ret = ret .. "table[0.5,0;13.25,6.1;scores;"
	ret = ret .. "#ffffff,,Player,Kills,Deaths,K/D,Bounty Kills,Captures,Attempts,Score"

	local player_in_top_50 = false

	for i = 1, math.min(#players, 50) do
		local pstat = players[i]
		local color
		if hlt_name and pstat.name == hlt_name then
			color = "#ffff00"
			player_in_top_50 = true
		else
			color = pstat.color or "#ffffff"
		end
		local kd = pstat.kills
		if pstat.deaths > 1 then
			kd = kd / pstat.deaths
		end
		ret = ret ..
			  "," .. string.gsub(color, "0x", "#") ..
			  "," .. i ..
			  "," .. pstat.name ..
			  "," .. pstat.kills ..
			  "," .. pstat.deaths ..
			  "," .. math.floor(kd * 10) / 10  ..
			  "," .. pstat.bounty_kills ..
			  "," .. pstat.captures ..
			  "," .. pstat.attempts ..
			  "," .. math.floor(pstat.score * 10) / 10
	end
	ret = ret .. ";-1]"

	-- If hlt_name not in top 50, add a separate table
	-- This would result in the player's score displayed at the bottom
	-- of the list but yet be visible without having to scroll
	if hlt_name and not player_in_top_50 then
		local hlt_player, hlt_rank, hlt_kd

		for i = 1, #players do
			if players[i].name == hlt_name then
				hlt_player = players[i]
				hlt_rank = i
				break
			end
		end

		if hlt_player then
			hlt_kd = hlt_player.kills
			if hlt_player.deaths > 1 then
				hlt_kd = hlt_kd / hlt_player.deaths
			end

			ret = ret .. tablecolumns
			ret = ret .. "tableoptions[highlight=#00000000]"
			ret = ret .. "table[0.5,6.1;13.25,0.4;hlt_score;"
			ret = ret .. "#ffff00" ..
				  "," .. hlt_rank ..
				  "," .. hlt_player.name ..
				  "," .. hlt_player.kills ..
				  "," .. hlt_player.deaths ..
				  "," .. math.floor(hlt_kd * 10) / 10 ..
				  "," .. hlt_player.bounty_kills ..
				  "," .. hlt_player.captures ..
				  "," .. hlt_player.attempts ..
				  "," .. math.floor(hlt_player.score * 10) / 10 .. ";-1]"
		end
	-- else
		-- ret = ret .. "box[0.5,6.1;13.25,0.4;#101010]"
		-- Adds a box where the extra table should be, in order to make it
		-- appear as an extension of the main table, but the color can't be
		-- matched, and looks slightly brighter or slightly darker than the table
	end

	ret = ret .. "button_exit[10,6.5;3,1;close;Close]"
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
		"<th>Player</th>" ..
		"<th>Kills</th>" ..
		"<th>Deaths</th>" ..
		"<th>K/D ratio</th>" ..
		"<th>Bounty kills</th>" ..
		"<th>Captures</th>" ..
		"<th>Attempts</th>" ..
		"<th>Score</th></tr>"

	for i = 1, math.min(#players, 50) do
		local pstat = players[i]
		local kd = pstat.kills
		if pstat.deaths > 1 then
			kd = kd / pstat.deaths
		end
		ret = ret ..
			"<tr><td>" .. i ..
			"</td><td>" .. pstat.name ..
			"</td><td>" .. pstat.kills ..
			"</td><td>" .. pstat.deaths ..
			"</td><td>" .. math.floor(kd * 10) / 10 ..
			"</td><td>" .. pstat.bounty_kills ..
			"</td><td>" .. pstat.captures ..
			"</td><td>" .. pstat.attempts ..
			"</td><td>" .. math.floor(pstat.score*10)/10 .. "</td></tr>"
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

minetest.register_chatcommand("r", {
	description = "Display your rankings as a chat result.",
	func = function(name, param)
		return send_as_chat_result(name, name)
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
			else
				return false, "Can't find player '" .. param .. "'"
			end
		else
			target = name
		end

		if not minetest.get_player_by_name(name) then
			return send_as_chat_result(name, target)
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
		ctf.needs_save = true

		return true, "Stats of '" .. src .. "' have been transferred to '" .. dest .. "'."
	end
})

minetest.register_chatcommand("summary", {
	description = "Display the scoreboard of the previous match.",
	func = function (name, param)
		if not prev_match_summary then
			return false, "Couldn't find the requested data."
		end

		minetest.show_formspec(name, "ctf_stats:prev_match_summary", prev_match_summary)
	end
})
