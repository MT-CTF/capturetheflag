local CHAT_COLOR = "orange"
local timer = nil
local bounties = {}

local function get_reward_str(rewards)
	local ret = ""

	for reward, amount in pairs(rewards) do
		ret = string.format("%s%s%d %s, ", ret, amount >= 0 and "+" or "-", amount, HumanReadable(reward))
	end

	return ret:sub(1, -3)
end

ctf_modebase.bounties = {
	new = function(pname, pteam, rewards)
		pname = PlayerName(pname)

		local bounty_message = minetest.colorize(CHAT_COLOR, string.format(
			"[Bounty] %s. Rewards: %s",
			pname, get_reward_str(rewards)
		))

		for _, team in ipairs(ctf_teams.current_team_list) do -- show bounty to all but target's team
			if team ~= pteam then
				ctf_teams.chat_send_team(team, bounty_message)
			end
		end

		bounties[pteam] = {name = pname, rewards = rewards, msg = bounty_message}
	end,
	remove = function(pname, killer)
		pname = PlayerName(pname)
		local pteam = ctf_teams.get(pname)

		minetest.chat_send_all(minetest.colorize(CHAT_COLOR, string.format("[Bounty] %s is no longer bountied", pname)))

		bounties[pteam] = nil
	end,
	claim = function(pname, killer)
		pname = PlayerName(pname)
		local pteam = ctf_teams.get(pname)

		if not (pteam and bounties[pteam] and bounties[pteam].name == pname) then
			return
		end

		local rewards = bounties[pteam].rewards
		minetest.chat_send_all(minetest.colorize(CHAT_COLOR,
			string.format("[Bounty] %s killed %s and got %s", PlayerName(killer), pname, get_reward_str(rewards))
		))

		bounties[pteam] = nil
		return rewards
	end,
	on_player_join = function(pname)
		pname = PlayerName(pname)
		local pteam = ctf_teams.get(pname)
		local output = {}

		for tname, bounty in pairs(bounties) do
			if pteam ~= tname then
				table.insert(output, bounty.msg)
			end
		end

		if #output > 0 then
			minetest.chat_send_player(pname, table.concat(output, "\n"))
		end
	end,
	on_match_start = function()
		timer = minetest.after(math.random(180, 360), function()
			timer = nil
			ctf_modebase.bounties.reassign()
			ctf_modebase.bounties.on_match_start()
		end)
	end,
	reassign = function()
		local teams = {}

		for tname, team in pairs(ctf_teams.online_players) do
			teams[tname] = {}
			for player in pairs(team.players) do
				table.insert(teams[tname], player)
			end
		end

		for tname in pairs(bounties) do
			if not teams[tname] then
				teams[tname] = {}
			end
		end

		for tname, team_members in pairs(teams) do
			local old = nil
			if bounties[tname] then
				old = bounties[tname].name
			end

			local new = nil
			if #team_members > 0 then
				new = ctf_modebase.bounties.get_next_bounty(team_members)
			end

			if old ~= new then
				if old then
					ctf_modebase.bounties.remove(old)
				end

				if new then
					ctf_modebase.bounties.new(new, tname, ctf_modebase.bounties.bounty_reward_func(new))
				end
			end
		end
	end,
	on_match_end = function()
		bounties = {}
		if timer then
			timer:cancel()
			timer = nil
		end
	end,
	bounty_reward_func = function()
		return {bounty_kills = 1, score = 500}
	end,
	get_next_bounty = function(team_members)
		return team_members[math.random(1, #team_members)]
	end,
}

ctf_core.register_chatcommand_alias("list_bounties", "lb", {
	description = "List current bounties",
	func = function(name)
		local pteam = ctf_teams.get(name)
		local output = {}

		for tname, bounty in pairs(bounties) do
			if pteam ~= tname then
				table.insert(output, bounty.msg)
			end
		end

		if #output <= 0 then
			return false, "There are no bounties you can claim"
		end

		return true, table.concat(output, "\n")
	end
})
