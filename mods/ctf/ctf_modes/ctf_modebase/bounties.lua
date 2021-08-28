local CHAT_COLOR = "orange"

return {
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

		if pteam and self.bounties[pteam] and self.bounties[pteam].name == pname then
			self.bounties[pteam] = nil
		end
	end,
	update_team_bounties = function(self, tname, get_rewards, ignore_player)
		if not self.bounties[tname] then
			local members = ctf_teams.get_team(tname)

			if ignore_player then
				local idx = table.indexof(members, ignore_player)

				if idx then
					table.remove(members, idx)
				end
			end

			if #members <= 0 then
				return
			end

			local target = self.get_next_bounty(members)

			if target then
				self:new(target, tname, get_rewards(target, tname))
			end
		end
	end,
	get_next_bounty = function(team_members)
		return team_members[math.random(1, #team_members)]
	end,
}
