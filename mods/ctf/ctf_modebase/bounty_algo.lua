ctf_modebase.bounty_algo = {kd = {}}

function ctf_modebase.bounty_algo.kd.get_next_bounty(team_members)
	local sum = 0
	local kd_list = {}
	local recent = ctf_modebase:get_current_mode().recent_rankings.players()

	for _, pname in ipairs(team_members) do
		if recent[pname] then
			local kd = (recent[pname].kills or 0) / (recent[pname].deaths or 1)
			if kd >= 0.8 then
				table.insert(kd_list, kd)
				sum = sum + kd
			end
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
	local recent = ctf_modebase:get_current_mode().recent_rankings.players()
	local sum = 0
	for _, tname in ipairs(team_members) do
		local stats = recent[tname]
		if stats then
			sum = sum + (stats.kills or 0) / (stats.deaths or 1)
		end
	end
	local pstats = recent[pname] or {}
	local kd = (pstats.kills or 1) / (pstats.deaths or 1)

	return {bounty_kills = 1, score = math.pow(kd, ))}
end
