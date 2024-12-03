local CHAT_COLOR = "orange"
local timer = nil
local bounties = {}

ctf_modebase.bounties = {}
-- ^ This is for game's own bounties
ctf_modebase.contributed_bounties = {
--[[
	["player_name"] = {
		total = score,
		contributors = {["player1"] = amount, ["player2"] = amount, ...}
	}, a total bounty of `total` score is on `player_name` player contributed
	by those in the list(`player1`, `player2`, ...)
	...
--]]
}
-- ^ This is for player contributed bounties

local function get_contributors(name)
	local bounty = ctf_modebase.contributed_bounties[name]
	if not bounty then
		return ""
	else
		local list = ""
		local first = true
		for contributor, score in pairs(bounty.contributors) do
			if first then
				list = list .. contributor
				first = false
			else
				list = "," .. list .. contributor
			end
		end
		return list
	end
end

local function get_reward_str(rewards)
	local ret = ""

	for reward, amount in pairs(rewards) do
		ret = string.format("%s%s%d %s, ", ret, amount >= 0 and "+" or "-", amount, HumanReadable(reward))
	end

	return ret:sub(1, -3)
end

local function set(pname, pteam, rewards)
	-- pname(str) is the player's name
	-- pteam(str) is the player's team(e.g. "red")
	-- rewards(table) has two entries:
	-- -- bounty_kills(int) which is usually 1
	-- -- score(int) which is the amount of score given to the one
	-- -- -- who claims the bounty
	local bounty_message = core.colorize(CHAT_COLOR, string.format(
		"[Bounty] %s. Rewards: %s",
		pname, get_reward_str(rewards)
	))

	for _, team in ipairs(ctf_teams.current_team_list) do -- show bounty to all but target's team
		if team ~= pteam then
			ctf_teams.chat_send_team(team, bounty_message)
		end
	end

	bounties[pteam] = {name = pname, rewards = rewards, msg = bounty_message}
end

local function remove(pname, pteam)
	core.chat_send_all(core.colorize(CHAT_COLOR, string.format("[Bounty] %s is no longer bountied", pname)))
	bounties[pteam] = nil
end

function ctf_modebase.bounties.claim(player, killer)
	local pteam = ctf_teams.get(player)
	local is_bounty = not (pteam and bounties[pteam] and bounties[pteam].name == player)
	if is_bounty and not ctf_modebase.contributed_bounties[player] then
		-- checking if there is bounty on this player
		return
	end

	local rewards = bounties[pteam].rewards
	if bounties[pteam] and bounties[pteam].rewards then
		local bounty_kill_text =
			string.format(
				"[Bounty] %s killed %s and got %s from the game!",
				killer,
				player,
				get_reward_str(rewards)
			)
		core.chat_send_all(core.colorize(CHAT_COLOR, bounty_kill_text))
		ctf_modebase.announce(bounty_kill_text)

		bounties[pteam] = nil
	end
	if ctf_modebase.contributed_bounties[player] then
		local score = ctf_modebase.contributed_bounties[player].total
		rewards.score = rewards.score + score
		rewards.bounty_kills =
			#ctf_modebase.contributed_bounties[player].contributors
			+ rewards.bounty_kills
		local bounty_kill_text =
				string.format(
					"[Player bounty] %s killed %s and got %d from %s!",
					killer,
					player,
					score,
					get_contributors(player)
				)
		core.chat_send_all(core.colorize(CHAT_COLOR, bounty_kill_text))
		ctf_modebase.announce(bounty_kill_text)
		ctf_modebase.contributed_bounties[player] = nil
	end
	return rewards
end

function ctf_modebase.bounties.reassign()
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

		if old and old ~= new then
			remove(old, tname)
		end

		if new then
			set(new, tname, ctf_modebase.bounties.bounty_reward_func(new))
		end
	end
end

function ctf_modebase.bounties.reassign_timer()
	timer = core.after(math.random(180, 360), function()
		ctf_modebase.bounties.reassign()
		ctf_modebase.bounties.reassign_timer()
	end)
end

ctf_api.register_on_match_start(ctf_modebase.bounties.reassign_timer)

ctf_api.register_on_match_end(function()
	bounties = {}
	if timer then
		timer:cancel()
		timer = nil
	end
end)

function ctf_modebase.bounties.bounty_reward_func()
	return {bounty_kills = 1, score = 500}
end

function ctf_modebase.bounties.get_next_bounty(team_members)
	return team_members[math.random(1, #team_members)]
end

ctf_teams.register_on_allocplayer(function(player, new_team, old_team)
	local pname = player:get_player_name()

	if old_team and old_team ~= new_team and bounties[old_team] and bounties[old_team].name == pname then
		remove(pname, old_team)
	end

	local output = {}

	for tname, bounty in pairs(bounties) do
		if new_team ~= tname then
			table.insert(output, bounty.msg)
		end
	end

	if #output > 0 then
		core.chat_send_player(pname, table.concat(output, "\n"))
	end
end)

ctf_core.register_chatcommand_alias("list_bounties", "lb", {
	description = "List current bounties",
	func = function(name)
		local pteam = ctf_teams.get(name)
		local output = {}
		local x = 0
		for tname, bounty in pairs(bounties) do
			local player = core.get_player_by_name(bounty.name)

			if player and pteam ~= tname then
				local label = string.format(
					"label[%d,0.1;%s: %s score]",
					x,
					bounty.name,
					core.colorize("cyan", bounty.rewards.score)
				)

				table.insert(output, label)
				local model = "model[%d,1;4,6;player;character.b3d;%s,blank.png;{0,160};;;]"
				model = string.format(
					model,
					x,
					player:get_properties().textures[1]
				)
				table.insert(output, model)
				x = x + 4.5
			end
		end
		for pname, bounty in pairs(ctf_modebase.contributed_bounties) do
			local player = core.get_player_by_name(pname)
			if player then
				local label = string.format(
					"label[%d,0.1;%s: %s score]",
					x,
					pname,
					core.colorize("cyan", bounty.total)
				)
				table.insert(output, label)

				local model = "model[%d,1;4,6;player;character.b3d;%s;{0,160};;;]"
				model = string.format(
					model,
					x,
					player:get_properties().textures[1]
				)
				table.insert(output, model)
				x = x + 4.5
			end
		end

		if #output <= 0 then
			return false, "There are no bounties you can claim"
		end
		x = x - 1.5
		local formspec = "size[" .. x .. ",6]\n" .. table.concat(output, "\n")
		core.show_formspec(name, "ctf_modebase:lb", formspec)
		return true, ""
	end,
})

ctf_core.register_chatcommand_alias("place_bounty", "pb", {
	description = "Place bounty on some player",
	params = "<player> <amount>",
	privs = { ctf_admin = true },
	func = function(name, param)
		local player, amount = string.match(param, "(.*) (.*)")

		if not (player and amount) then
			return false, "Incorrect parameters"
		end

		local pteam = ctf_teams.get(player)
		if not pteam then
			return false, "You can only put a bounty on a player in a team!"
		end

		local team_colour = ctf_teams.team[pteam].color

		amount = ctf_core.to_number(amount)
		if amount then
			set(
				player,
				pteam,
				{ bounty_kills=1, score=amount }
			)
			return true, "Successfully placed a bounty of " .. amount .. " on " .. core.colorize(team_colour, player) .. "!"
		else
			return false, "Invalid Amount"
		end
	end,
})



ctf_core.register_chatcommand_alias("bounty", "b", {
	description = "Place a bounty on someone using your match score.\n" ..
	"The score is returned to you if the match ends and nobody kills.\n" ..
	"Use negative score to revoke a bounty",
	params = "<player> <score>",
	func = function(name, params)
		local bname, amount = string.match(params, "([^%s]*) ([^%s]*)")
		if not (amount and bname) then
			return false, "Missing argument(s)"
		end
		amount = math.floor(amount)
		local bteam = ctf_teams.get(bname)
		if not bteam then
			return false, "This player isn't online or isn't in a team"
		end
		if bteam == ctf_teams.get(name) then
			return false, "You cannot place a bounty on your teammate!"
		end
		local current_mode = ctf_modebase:get_current_mode()
		if amount <= 0 then
			local contributors = ctf_modebase.contribued_bounties[bname]
			local contributed_amount = contributors[bname] or 0
			if math.abs(amount) > contributed_amount then
				contributed_amount = math.abs(amount)
			end
			ctf_modebase.contributed_bounties[bname][name] = ctf_modebase.contributed_bounties[bname][name] - contributed_amount
			current_mode.recent_rankings.add(name, { score = contributed_amount }, true)
			return true, tostring(contributed_amount) .. " points returned to you."
		end

		if amount < 5 then
			return false, "Your bounty needs to be of at least 5 points"
		end
		if amount > 100 then
			return false, "Your bounty cannot be of more than 100 points"
		end

		if not current_mode or not ctf_modebase.match_started then
			return false, "Match has not started yet."
		end
		local cur_score = current_mode.recent_rankings.get(name).score or 0
		if amount > cur_score then
			return false, "You haven't got enough points"
		end
		current_mode.recent_rankings.add(name, {score=-amount}, true)
		if not ctf_modebase.contributed_bounties[bname] then
			local contributors = {}
			contributors[name] = amount
			ctf_modebase.contributed_bounties[bname] = { total = amount, contributors = contributors }
		else
			if not ctf_modebase.contributed_bounties[bname].contributors[name] then
				ctf_modebase.contributed_bounties[bname].contributors[name] = amount
			else
				ctf_modebase.contributed_bounties[bname].contributors[name] =
					ctf_modebase.contributed_bounties[bname].contributors[name] + amount
			end
			ctf_modebase.contributed_bounties[bname].total = ctf_modebase.contributed_bounties[bname].total + amount
		end
		local total = ctf_modebase.contributed_bounties[bname].total
		core.chat_send_all(
			core.colorize(
			CHAT_COLOR,
			string.format("%s placed %d bounty on %s!", get_contributors(bname), total, bname)))
	end,
})

ctf_api.register_on_match_end(function()
	local current_mode = ctf_modebase:get_current_mode()
	for pname, bounty in pairs(ctf_modebase.contributed_bounties) do
	for contributor, amount in pairs(bounty.contributors) do
		current_mode.recent_rankings.add(contributor, {score=amount}, true)
	end
	end
end)
