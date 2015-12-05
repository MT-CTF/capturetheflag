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
	local ret = ctf_stats.get_formspec("Match Summary", players)
	ret = ret .. "label[3.5,6.2;Tip: type /rankings for league tables]"
	return ret
end

function ctf_stats.get_formspec(title, players)
	for i = 1, #players do
		local pstat = players[i]
		pstat.kills = pstat.kills or 0
		pstat.deaths = pstat.deaths or 0
		pstat.captures = pstat.captures or 0
		pstat.attempts = pstat.attempts or 0
		pstat.score = 0.1 * pstat.kills + 10 * pstat.captures +
				5 * pstat.attempts + 5 * pstat.kills / (pstat.deaths + 1)
	end
	table.sort(players, function(one, two)
		return one.score > two.score
	end)

	local ret = "size[12,6.5]"
	ret = ret .. "vertlabel[0,0;" .. title .. "]"
	ret = ret .. "tablecolumns[color;text;text;text;text;text;text;text;text]"
	ret = ret .. "tableoptions[highlight=#00000000]"
	ret = ret .. "table[0.5,0;11.25,6;scores;"
	ret = ret .. "#ffffff,,username,kills,deaths,K/D ratio,captures,attempts,score"

	for i = 1, #players do
		local pstat = players[i]
		local color = pstat.color or "#ffffff"
		ret = ret ..
			"," .. string.gsub(color, "0x", "#") ..
			"," .. i ..
			"," .. pstat.name ..
			"," .. pstat.kills ..
			"," .. pstat.deaths ..
			"," .. math.floor(pstat.kills / (pstat.deaths + 1)*10)/10 ..
			"," .. pstat.captures ..
			"," .. pstat.attempts ..
			"," .. math.floor(pstat.score*10)/10
		if i > 40 then
			break
		end
	end

	ret = ret .. ";-1]"
	ret = ret .. "button_exit[0.5,6;3,1;close;Close]"
	return ret
end


minetest.register_chatcommand("rankings", {
	func = function(name)
		local players = {}
		for name, pstat in pairs(ctf_stats.players) do
			pstat.name = name
			pstat.color = nil
			table.insert(players, pstat)
		end
		local fs = ctf_stats.get_formspec("Player Rankings", players)
		minetest.show_formspec(name, "ctf_stats:rankings", fs)
	end
})
