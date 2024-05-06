ctf_modebase.bounty_algo = {kd = {}}

function ctf_modebase.bounty_algo.kd.get_next_bounty(team_members)
	local sum = 0
	local bounty_worthy_list = {
		-- pname = bounty_worthy_score
	}
	local recent = ctf_modebase:get_current_mode().recent_rankings.players()

	for _, pname in ipairs(team_members) do
		if recent[pname] then
			local kd = (recent[pname].kills or 0) / (recent[pname].deaths or 1)
			-- Kills/Deaths
			local hd = (recent[pname].hp_healed or 0) / (recent[pname].deaths or 1) / 5
			-- HPs Healed/Deaths
			if kd >= 0.95 then
				bounty_worthy_list[pname] = (bounty_worthy_list[pname] or 0) + kd
			end
			if hd >= 0.8 then
				bounty_worthy_list[pname] = (bounty_worthy_list[pname] or 0) + hd
			end
			sum = sum + (bounty_worthy_list[pname] or 0)
		end
	end

	local random = math.random() * sum

	for pname, score in ipairs(bounty_worthy_list) do
		if random <= score then
			return pname
		end
		random = random - score
	end

	return team_members[#team_members]
end

function ctf_modebase.bounty_algo.kd.bounty_reward_func(pname)
	local recent = ctf_modebase:get_current_mode().recent_rankings.players()
	local pstats = recent[pname] or {}
	local kd = (pstats.kills or 1) / (pstats.deaths or 1)
	local hd = (pstats.hp_healed or 1) / (pstats.deaths or 1)
	local score = kd * hd
	return {bounty_kills = 1, score = math.pow(score * 7, 3.5)}
end
