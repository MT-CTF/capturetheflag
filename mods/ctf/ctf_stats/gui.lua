-- Number of entries to display in the player rankings table
ctf_stats.rankings_display_count = 50

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
		deaths = 0,
		attempts = 0,
		score = 0,
	}
	local blue = {
		color = ctf.flag_colors.blue:gsub("0x", "#"),
		kills = 0,
		deaths = 0,
		attempts = 0,
		score = 0,
	}
	for name, pstat in pairs(stats.red) do
		pstat.name = name
		pstat.color = ctf.flag_colors.red
		table.insert(players, pstat)
		red.kills = red.kills + pstat.kills
		red.deaths = red.deaths + pstat.deaths
		red.attempts = red.attempts + pstat.attempts
		red.score = red.score + pstat.score
	end
	for name, pstat in pairs(stats.blue) do
		pstat.name = name
		pstat.color = ctf.flag_colors.blue
		table.insert(players, pstat)
		blue.kills = blue.kills + pstat.kills
		blue.deaths = blue.deaths + pstat.deaths
		blue.attempts = blue.attempts + pstat.attempts
		blue.score = blue.score + pstat.score
	end

	local match_length = "-"
	if time then
		match_length = string.format("%02d:%02d:%02d",
			math.floor(time / 3600),        -- hours
			math.floor((time % 3600) / 60), -- minutes
			math.floor(time % 60))          -- seconds
	end
	
		local red_kd = math.floor(red.kills / red.deaths * 10) / 10
		if red.deaths <1 then
			red_kd = red.kills
    end
	
	local blue_kd = math.floor(blue.kills / blue.deaths * 10) / 10
		if blue.deaths <1 then
			blue_kd = blue.kills
    end

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
	ret = ret .. "label[3.5,0.5;Team K/D]"
	ret = ret .. "label[5,0.5;" .. minetest.colorize(red.color, tostring(red_kd))
		.. " - " .. " " .. minetest.colorize(blue.color, tostring(blue_kd)) .. "]"
	ret = ret .. "label[6.5,0.5;Attempts]"
	ret = ret .. "label[8,0.5;" .. render_team_stats(red, blue, "attempts") .. "]"
	ret = ret .. "label[9.5,0;Duration]"
	ret = ret .. "label[11,0;" .. match_length .. "]"
	ret = ret .. "label[9.5,0.5;Total score]"
	ret = ret .. "label[11,0.5;" .. render_team_stats(red, blue, "score", true) .. "]"
	ret = ret .. "label[8,7.2;Tip: type /rankings for league tables]"

	return ret
end

function ctf_stats.get_formspec(title, players, header, target)
	table.sort(players, function(one, two)
		return one.score > two.score
	end)

	local ret = "size[14," .. 7 + header .. "]"
	ret = ret .. "container[0," .. header .. "]"

	ret = ret .. "vertlabel[0,1;" .. title .. "]"
	ret = ret .. tablecolumns
	ret = ret .. "tableoptions[highlight=#00000000]"
	ret = ret .. "table[0.5,0;13.25,6.1;scores;"
	ret = ret .. "#ffffff,,Player,Kills,Deaths,K/D,Bounty Kills,Captures,Attempts,Score"

	local hstat, hplace
	if type(target) == "number" then
		hstat  = players[target]
		hplace = target
	elseif type(target) == "string" then
		for i, stat in pairs(players) do
			if stat.name == target then
				hplace = i
				hstat  = stat
				break
			end
		end
	end

	for i = 1, math.min(#players, ctf_stats.rankings_display_count) do
		local pstat = players[i]
		local color
		if hplace == i then
			color = "#ffff00"
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

	-- If target not in top 50, add a separate table
	-- This would result in the player's score displayed at the bottom
	-- of the list but yet be visible without having to scroll
	if hplace and hplace > ctf_stats.rankings_display_count then
		local h_kd = hstat.kills
		if hstat.deaths > 1 then
			h_kd = h_kd / hstat.deaths
		end

		ret = ret .. tablecolumns
		ret = ret .. "tableoptions[highlight=#00000000]"
		ret = ret .. "table[0.5,6.1;13.25,0.4;hlt_score;"
		ret = ret .. "#ffff00" ..
			"," .. hplace ..
			"," .. hstat.name ..
			"," .. hstat.kills ..
			"," .. hstat.deaths ..
			"," .. math.floor(h_kd * 10) / 10 ..
			"," .. hstat.bounty_kills ..
			"," .. hstat.captures ..
			"," .. hstat.attempts ..
			"," .. math.floor(hstat.score * 10) / 10 .. ";-1]"
	--[[ else
		ret = ret .. "box[0.5,6.1;13.25,0.4;#101010]"
		Adds a box where the extra table should be, in order to make it
		appear as an extension of the main table, but the color can't be
		matched, and looks slightly brighter or slightly darker than the table]]
	end

	ret = ret .. "button_exit[10,6.5;3,1;close;Close]"
	ret = ret .. "container_end[]"
	return ret
end

function ctf_stats.get_html(title)
	local players = ctf_stats.get_ordered_players()
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
	local f = io.open(filepath, "w")
	f:write("<!doctype html>\n")
	f:write("<html><head>\n")
	f:write("<meta charset=\"utf-8\">\n")
	f:write("<title>Player Rankings</title>\n")
	f:write("<link rel=\"stylesheet\" href=\"score_style.css\">\n")
	f:write("</head><body>\n")
	f:write(ctf_stats.get_html("Player Rankings"))
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
			ctf_stats.winner_team, ctf_stats.winner_player, ctf_match.get_match_duration())
		fs = fs .. "button[6,7.5;4,1;b_prev;<< Previous match]"
	else
		return
	end

	minetest.show_formspec(player:get_player_name(), "ctf_stats:match_summary", fs)
end)
