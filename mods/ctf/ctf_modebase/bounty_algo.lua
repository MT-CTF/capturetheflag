ctf_modebase.bounty_algo = {kd = {}}

function ctf_modebase.bounty_algo.kd.get_next_bounty(team_members)
	local sum = 0
	local kd_list = {}
	local recent = ctf_modebase:get_current_mode().recent_rankings.players()

	for _, pname in ipairs(team_members) do
		local team = ctf_teams.get(pname)
		if team and not ctf_teams.team[team].not_playing then
			local kd = 0.1
			if recent[pname] then
				kd = math.max(kd, (recent[pname].kills or 0) / (recent[pname].deaths or 1))
			end

			table.insert(kd_list, kd)
			sum = sum + kd
		end
	end

	local random = math.random() * sum

	for i, kd in ipairs(kd_list) do
		if random <= kd then
			return team_members[i]
		end
		random = random - kd
	end

	return team_members[#team_members]
end

function ctf_modebase.bounty_algo.kd.bounty_reward_func(pname)
	local recent = ctf_modebase:get_current_mode().recent_rankings.players()[pname] or {}
	local kd = (recent.kills or 1) / (recent.deaths or 1)

	return {bounty_kills = 1, score = math.max(5, math.min(120, math.ceil(kd * 7)))}
end
