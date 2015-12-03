function ctf_stats.get_formspec_match_summary(stats)
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
	local ret = ctf_stats.get_formspec("Match Summary", players, stats)
	ret = ret .. "label[3.5,6.2;Tip: type /rankings for league tables]"
	return ret
end

function ctf_stats.get_formspec(title, players, stats)
	for _, pstat in pairs(players) do
		pstat.score = pstat.captures + 0.2 * pstat.attempts + 7 * pstat.kills / (pstat.deaths + 1)
	end
	table.sort(players, function(one, two)
		return (one.score > two.score)
	end)

	local ret = "size[9,6.5]"
	ret = ret .. "vertlabel[0,0;" .. title .. "]"
	ret = ret .. "tablecolumns[color;text;text;text;text;text;text;text]"
	ret = ret .. "tableoptions[highlight=#00000000]"
	ret = ret .. "table[0.5,0;8.25,6;scores;"
	ret = ret .. "#ffffff,username,kills,deaths,K/D ratio,wins,attempts,score"

	for i, pstat in pairs(players) do
		local color = pstat.color or "#ffffff"
		ret = ret ..
			"," .. string.gsub(color, "0x", "#") ..
			"," .. pstat.name ..
			"," .. pstat.kills ..
			"," .. pstat.deaths ..
			"," .. math.floor(pstat.kills / (pstat.deaths + 1)*10)/10 ..
			"," .. pstat.captures ..
			"," .. pstat.attempts ..
			"," .. pstat.score
	end

	ret = ret .. ";-1]"
	ret = ret .. "button_exit[0.5,6;3,1;close;Close]"
	return ret
end
