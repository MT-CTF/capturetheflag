-- Formspec element that governs table columns and their attributes
local tablecolumns = {
	"tablecolumns[color;",
	"text;",
	"text,width=16;",
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

	-- Winning team and flag capturer name
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

	-- Map name
	ret = ret .. "label[1,7.6;Map: " .. minetest.colorize("#EEEE00", stats.map) .. "]"

	ret = ret .. "label[6.5,0;Kills]"
	ret = ret .. "label[8,0;" .. render_team_stats(red, blue, "kills") .. "]"
	ret = ret .. "label[6.5,0.5;Attempts]"
	ret = ret .. "label[8,0.5;" .. render_team_stats(red, blue, "attempts") .. "]"
	ret = ret .. "label[10.5,0;Duration]"
	ret = ret .. "label[12,0;" .. match_length .. "]"
	ret = ret .. "label[10.5,0.5;Total score]"
	ret = ret .. "label[12,0.5;" .. render_team_stats(red, blue, "score", true) .. "]"
	ret = ret .. "label[8,7.2;Tip: type /rankings for league tables]"

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

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "ctf_stats:match_summary" then
		return
	end

	local fs
	if fields.b_prev then
		fs = ctf_stats.prev_match_summary
		fs = fs .. "button[6,7.5;4,1;b_curr;Current match >>]"
	elseif fields.b_curr then
		fs = ctf_stats.get_formspec_match_summary(ctf_stats.current,
			ctf_stats.winner_team, ctf_stats.winner_player, os.time() - ctf_stats.start)
		fs = fs .. "button[6,7.5;4,1;b_prev;<< Previous match]"
	else
		return
	end

	minetest.show_formspec(player:get_player_name(), "ctf_stats:match_summary", fs)
end)
