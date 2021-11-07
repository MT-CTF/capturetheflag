return function(recent_rankings)

return {
	get_next_bounty = function(team_members)
		local sum = 0
		local kd_list = {}
		local recent = recent_rankings.players()

		for _, pname in ipairs(team_members) do
			local kd = recent[pname] and (recent[pname].kills or 1) / (recent[pname].deaths or 1) or 1
			table.insert(kd_list, kd)
			sum = sum + kd
		end

		local random = math.random() * sum

		for i, kd in ipairs(kd_list) do
			if random <= kd then
				return team_members[i]
			end
			random = random - kd
		end

		return team_members[#team_members]
	end,

	bounty_reward_func = function(pname)
		local recent = recent_rankings.players()[pname] or {}
		local kd = (recent.kills or 1) / (recent.deaths or 1)

		return {bounty_kills = 1, score = math.max(0, math.min(500, kd * 30))}
	end,
}

end
