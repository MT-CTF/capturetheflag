kill_assist = {}

local kill_assists = {}

function kill_assist.clear_assists(player)
	if type(player) == "string" then
		kill_assists[player] = nil
	else
		kill_assists = {}
	end
end

function kill_assist.add_assist(victim, attacker, damage)
	if victim == attacker then return end

	if not kill_assists[victim] then
		kill_assists[victim] = {
			players = {},
			hp_offset = 0
		}
	end

	kill_assists[victim].players[attacker] = (kill_assists[victim].players[attacker] or 0) + damage
end

function kill_assist.add_heal_assist(victim, healed_hp)
	if not kill_assists[victim] then return end

	kill_assists[victim].hp_offset = kill_assists[victim].hp_offset + healed_hp
end

function kill_assist.reward_assists(victim, killer, reward)
	local max_hp = minetest.get_player_by_name(victim):get_properties().max_hp or 20

	if not kill_assists[victim] then
		if victim ~= killer then
			kill_assist.add_assist(victim, killer, max_hp)
		else
			return
		end
	end

	for name, damage in pairs(kill_assists[victim].players) do
		if minetest.get_player_by_name(name) then
			local help_percent = damage / (max_hp + kill_assists[victim].hp_offset)
			local main, match = ctf_stats.player(name)
			local color = "0x00FFFF"

			if name == killer or help_percent >= 0.33 then
				reward = math.max(math.floor((reward * help_percent)*100)/100, 1)
			end

			match.score = match.score + reward
			main.score = main.score + reward

			if name == killer then
				color = "0x00FF00"
			end

			hud_score.new(name, {
				name = "kill_assist:score",
				color = color,
				value = reward
			})
		end
	end

	ctf_stats.request_save()
	kill_assist.clear_assists(victim)
end

ctf.register_on_killedplayer(function(victim, killer, toolcaps)
	local reward = ctf_stats.calculateKillReward(victim, killer, toolcaps)
	reward = math.floor(reward * 100) / 100
	kill_assist.reward_assists(victim, killer, reward)
end)

ctf.register_on_attack(function(player, hitter, _, _, _, damage)
	kill_assist.add_assist(player:get_player_name(), hitter:get_player_name(), damage)
end)

ctf_match.register_on_new_match(function()
	kill_assist.clear_assists()
end)
ctf.register_on_new_game(function()
	kill_assist.clear_assists()
end)
minetest.register_on_leaveplayer(function(player)
	kill_assist.clear_assists(player)
end)
