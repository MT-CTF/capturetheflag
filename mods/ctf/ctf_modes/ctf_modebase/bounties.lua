local CHAT_COLOR = "orange"

local timer = nil

local self = {
	bounties = {},
	new = function(self, pname, pteam, rewards)
		pname = PlayerName(pname)
		local reward_str = ""
		local current_teams = ctf_map.current_map.teams

		for reward, amount in pairs(rewards) do
			reward_str = string.format("%s%s%d %s, ", reward_str, amount >= 0 and "+" or "-", amount, HumanReadable(reward))
		end

		local bounty_message = minetest.colorize(CHAT_COLOR, string.format(
			"[Bounty] %s. Rewards: %s",
			pname, reward_str:sub(1, -3)
		))

		for team in pairs(current_teams) do -- show bounty to all but target's team
			if team ~= pteam then
				ctf_teams.chat_send_team(team, bounty_message)
			end
		end

		self.bounties[pteam] = {name = pname, rewards = rewards, msg = bounty_message}
	end,
	player_has = function(self, pname)
		pname = PlayerName(pname)
		local pteam = ctf_teams.get(pname)

		if pteam then
			if self.bounties[pteam] and self.bounties[pteam].name == pname then
				return self.bounties[pteam].rewards
			end
		end

		return false
	end,
	remove = function(self, pname)
		pname = PlayerName(pname)
		local pteam = ctf_teams.get(pname)

		minetest.chat_send_all(minetest.colorize(CHAT_COLOR, string.format("[Bounty] %s is no longer bountied", pname)))
		self.bounties[pteam] = nil
	end,
	on_player_join = function(self, pname)
		pname = PlayerName(pname)
		local pteam = ctf_teams.get(pname)
		local output = {}

		for tname, bounty in pairs(self.bounties) do
			if pteam ~= tname then
				table.insert(output, bounty.msg)
			end
		end

		if #output > 0 then
			minetest.chat_send_player(pname, table.concat(output, "\n"))
		end
	end,
	on_match_start = function(self)
		timer = math.random(180, 360)
	end,
	reassign = function(self)
		local teams = ctf_teams.get_teams()
		for tname in pairs(self.bounties) do
			if not teams[tname] then
				teams[tname] = {}
			end
		end

		for tname, team_members in pairs(teams) do
			local old = nil
			if self.bounties[tname] then
				old = self.bounties[tname].name
			end

			local new = nil
			if #team_members > 0 then
				new = self.get_next_bounty(team_members)
			end

			if old ~= new then
				if old then
					self:remove(old)
				end

				if new then
					self:new(new, tname, self.bounty_reward_func(new))
				end
			end
		end
	end,
	on_match_end = function(self)
		self.bounties = {}
		timer = nil
	end,
	bounty_reward_func = function()
		return {bounty_kills = 1, score = 500}
	end,
	get_next_bounty = function(team_members)
		return team_members[math.random(1, #team_members)]
	end,
}

minetest.register_globalstep(function(dtime)
	if timer == nil then
		return
	end

	timer = timer - dtime

	if timer <= 0 then
		timer = nil
		self:reassign()
		self:on_match_start()
	end
end)

return self
