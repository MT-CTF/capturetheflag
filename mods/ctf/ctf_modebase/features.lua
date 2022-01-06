ctf_modebase.features = function(rankings, recent_rankings)

local FLAG_MESSAGE_COLOR = "#d9b72a"
local FLAG_CAPTURE_TIMER = 60 * 3
local many_teams = false
local team_list
local teams_left

local function calculate_killscore(player)
	local match_rank = recent_rankings.players()[player] or {}
	local kd = (match_rank.kills or 1) / (match_rank.deaths or 1)

	return math.min(1, math.round(kd * 7))
end

local function tp_player_near_flag(player)
	local tname = ctf_teams.get(player)

	if not tname then return end

	player:set_pos(
		vector.offset(ctf_map.current_map.teams[tname].flag_pos,
			math.random(-1, 1),
			0.5,
			math.random(-1, 1)
		)
	)

	return true
end

local function celebrate_team(teamname)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local pteam = ctf_teams.get(pname)

		if pteam == teamname then
			minetest.sound_play("ctf_modebase_trumpet_positive", {
				to_player = pname,
				gain = 1.0,
				pitch = 1.0,
			}, true)
		else
			minetest.sound_play("ctf_modebase_trumpet_negative", {
				to_player = pname,
				gain = 1.0,
				pitch = 1.0,
			}, true)
		end
	end
end

local function end_combat_mode(player, killer, leaving)
	local killscore = calculate_killscore(player)
	local hitters = {}

	ctf_combat_mode.get(player, "hitter", function(pname)
		if not killer or pname ~= killer then
			table.insert(hitters, pname)
		end
	end)

	if killer == player then
		recent_rankings.add(player, {deaths = 1}, true)
	elseif killer then
		local rewards = {kills = 1, score = killscore}
		local bounty = ctf_modebase.bounties.claim(player, killer)

		if bounty then
			for name, amount in pairs(bounty) do
				rewards[name] = (rewards[name] or 0) + amount
			end
		end

		recent_rankings.add(killer, rewards)

		-- share kill score with healers
		ctf_combat_mode.get(killer, "healer", function(pname)
			recent_rankings.add(pname, {score = rewards.score})
		end)

		recent_rankings.add(player, {deaths = 1}, true)

		local killer_attacked = nil
		ctf_combat_mode.get(killer, "hitter", function(pname)
			if not killer_attacked then
				killer_attacked = pname ~= player
			end
		end)

		if killer_attacked == false then
			ctf_combat_mode.set_time(killer, 5)
		end
	else
		-- Only take score if they're in combat for being hit
		if #hitters > 0 then
			recent_rankings.add(player, {score = -math.ceil(killscore/2)}, leaving)
		end

		if #hitters > 0 or not leaving then
			ctf_kill_list.add_kill("", "ctf_modebase_skull.png", player)
			recent_rankings.add(player, {deaths = 1}, true)
		end
	end

	for _, pname in ipairs(hitters) do
		recent_rankings.add(pname, {kill_assists = 1, score = math.ceil(killscore / #hitters)})
	end

	ctf_combat_mode.remove(player)
end

return {
	on_new_match = function()
		team_list = {}
		for tname in pairs(ctf_map.current_map.teams) do
			table.insert(team_list, tname)
		end
		teams_left = #team_list
		many_teams = #team_list > 2

		ctf_map.place_chests(ctf_map.current_map)
	end,
	on_match_end = function()
		recent_rankings.on_match_end()
	end,
	team_allocator = function(player)
		player = PlayerName(player)

		local team_scores = recent_rankings.teams()

		local best_kd = nil
		local worst_kd = nil
		local best_players = nil
		local worst_players = nil

		for _, team in ipairs(team_list) do
			local players_count = ctf_teams.online_players[team].count

			local kd = 0.1
			if team_scores[team] then
				kd = math.max(kd, (team_scores[team].kills or 0) / (team_scores[team].deaths or 1))
			end

			if not best_kd or kd > best_kd.s then
				best_kd = {s = kd, t = team}
			end

			if not worst_kd or kd < worst_kd.s then
				worst_kd = {s = kd, t = team}
			end

			if not best_players or players_count > best_players.s then
				best_players = {s = players_count, t = team}
			end

			if not worst_players or players_count < worst_players.s then
				worst_players = {s = players_count, t = team}
			end
		end

		local kd_diff = best_kd.s - worst_kd.s
		local players_diff = best_players.s - worst_players.s

		local remembered_team = ctf_teams.get(player)

		if worst_players.s == 0 then
			return worst_players.t
		end

		-- Allocate player to remembered team unless they're desperately needed in the other
		if remembered_team and not ctf_modebase.flag_captured[remembered_team] and kd_diff <= 0.4 and players_diff < 3 then
			return remembered_team
		end

		if players_diff == 0 or kd_diff > 0.2 and players_diff < 2 then
			return worst_kd.t
		else
			return worst_players.t
		end
	end,
	can_take_flag = function(player, teamname)
		if not ctf_modebase.match_started then
			tp_player_near_flag(player)

			return "You can't take the enemy flag during build time!"
		end

		if ctf_modebase.is_immune(player) then
			return "You can't take the flag while immune"
		end
	end,
	on_flag_take = function(player, teamname)
		local pname = player:get_player_name()
		local pteam = ctf_teams.get(player)
		local tcolor = ctf_teams.team[pteam].color

		playertag.set(player, playertag.TYPE_BUILTIN, tcolor)

		local text = " has taken the flag"
		if many_teams then
			text = " has taken " .. HumanReadable(teamname) .. "'s flag"
		end

		minetest.chat_send_all(
			minetest.colorize(tcolor, pname) ..
			minetest.colorize(FLAG_MESSAGE_COLOR, text)
		)
		ctf_modebase.announce(string.format("Player %s (team %s)%s", pname, pteam, text))

		celebrate_team(ctf_teams.get(pname))

		recent_rankings.add(pname, {score = 30, flag_attempts = 1})

		ctf_modebase.flag_huds.track_capturer(pname, FLAG_CAPTURE_TIMER)
	end,
	on_flag_drop = function(player, teamnames)
		local pname = player:get_player_name()
		local pteam = ctf_teams.get(pname)
		local tcolor = ctf_teams.team[pteam].color

		local text = " has dropped the flag"
		if many_teams then
			text = " has dropped the flag of team(s) " .. HumanReadable(teamnames)
		end

		minetest.chat_send_all(
			minetest.colorize(tcolor, pname) ..
			minetest.colorize(FLAG_MESSAGE_COLOR, text)
		)
		ctf_modebase.announce(string.format("Player %s (team %s)%s", pname, pteam, text))

		ctf_modebase.flag_huds.untrack_capturer(pname)

		playertag.set(player, playertag.TYPE_ENTITY)
	end,
	on_flag_capture = function(player, teamnames)
		local pname = player:get_player_name()
		local pteam = ctf_teams.get(pname)
		local tcolor = ctf_teams.team[pteam].color

		playertag.set(player, playertag.TYPE_ENTITY)
		celebrate_team(pteam)

		local text = " has captured the flag"
		if many_teams then
			text = " has captured the flag of team(s) " .. HumanReadable(teamnames)
			minetest.chat_send_all(
				minetest.colorize(tcolor, pname) ..
				minetest.colorize(FLAG_MESSAGE_COLOR, text)
			)
		end
		ctf_modebase.announce(string.format("Player %s (team %s)%s", pname, pteam, text))

		ctf_modebase.flag_huds.untrack_capturer(pname)

		local team_scores = recent_rankings.teams()
		local capture_reward = 0
		for _, lost_team in ipairs(teamnames) do
			local score = ((team_scores[lost_team] or {}).score or 0) / 4
			score = math.max(75, math.min(500, score))
			capture_reward = capture_reward + score
		end

		recent_rankings.add(pname, {score = capture_reward, flag_captures = #teamnames})

		teams_left = teams_left - #teamnames

		if teams_left <= 1 then
			local capture_text = "Player %s captured"
			if many_teams then
				capture_text = "Player %s captured the last flag"
			end

			ctf_modebase.summary.set_winner(string.format(capture_text, minetest.colorize(tcolor, pname)))

			local win_text = HumanReadable(pteam) .. " Team Wins!"

			local match_rankings, special_rankings, rank_values, formdef = ctf_modebase.summary.get()
			formdef.title = win_text

			for _, p in ipairs(minetest.get_connected_players()) do
				ctf_modebase.summary.show_gui(p:get_player_name(), match_rankings, special_rankings, rank_values, formdef)
			end

			ctf_modebase.announce(win_text)

			ctf_modebase.start_new_match(5)
		else
			for _, lost_team in ipairs(teamnames) do
				table.remove(team_list, table.indexof(team_list, lost_team))

				for lost_player in pairs(ctf_teams.online_players[lost_team].players) do
					ctf_teams.allocate_player(lost_player)
				end
			end
		end
	end,
	on_allocplayer = function(player, new_team)
		player:set_hp(player:get_properties().hp_max)

		ctf_modebase.update_wear.cancel_player_updates(player)

		ctf_modebase.player.remove_bound_items(player)
		ctf_modebase.player.give_initial_stuff(player)

		local tcolor = ctf_teams.team[new_team].color
		player:hud_set_hotbar_image("gui_hotbar.png^[colorize:" .. tcolor .. ":128")
		player:hud_set_hotbar_selected_image("gui_hotbar_selected.png^[multiply:" .. tcolor)

		player:set_properties({textures = {ctf_cosmetics.get_skin(player)}})

		recent_rankings.set_team(player, new_team)

		playertag.set(player, playertag.TYPE_ENTITY)

		tp_player_near_flag(player)
	end,
	on_leaveplayer = function(player)
		if not ctf_modebase.match_started then
			ctf_combat_mode.remove(player)
			return
		end

		local pname = player:get_player_name()

		-- should be no_hud to avoid a race
		end_combat_mode(pname, nil, true)

		recent_rankings.on_leaveplayer(pname)
	end,
	on_dieplayer = function(player, reason)
		if not ctf_modebase.match_started then return end

		-- punch is handled in on_punchplayer
		if reason.type ~= "punch" then
			end_combat_mode(player:get_player_name())
		end

		ctf_modebase.prepare_respawn_delay(player)
	end,
	on_respawnplayer = function(player)
		tp_player_near_flag(player)
	end,
	get_chest_access = function(pname)
		local rank = rankings:get(pname)
		local deny_pro = "You need to have more than 1.4 kills per death, "..
				"5 captures, and at least 8,000 score to access the pro section"

		-- Remember to update /makepro in ranking_commands.lua if you change anything here
		if rank then
			if (rank.score or 0) >= 8000 and (rank.kills or 0) / (rank.deaths or 0) >= 1.4 and rank.flag_captures >= 5 then
				return true, true
			elseif (rank.score or 0) >= 10 then
				return true, deny_pro
			end
		end

		return "You need at least 10 score to access this chest", deny_pro
	end,
	on_punchplayer = function(player, hitter, damage, _, tool_capabilities)
		if not hitter:is_player() or player:get_hp() <= 0 then return false end

		if not ctf_modebase.match_started then
			return false, "The match hasn't started yet!"
		end

		local pname, hname = player:get_player_name(), hitter:get_player_name()
		local pteam, hteam = ctf_teams.get(player), ctf_teams.get(hitter)

		if ctf_modebase.is_immune(hname) then
			return false, "You can't attack while immune"
		end

		if not pteam then
			return false, pname .. " is not in a team!"
		end

		if not hteam then
			return false, "You are not in a team!"
		end

		if pteam == hteam and pname ~= hname then
			return false, pname .. " is on your team!"
		end

		if player:get_hp() <= damage then
			end_combat_mode(pname, hname)
			ctf_kill_list.on_kill(player, hitter, tool_capabilities)
		elseif pname ~= hname then
			ctf_combat_mode.set(player, hitter, "hitter", 15, true)
		end

		return damage
	end,
	on_healplayer = function(player, patient, amount)
		if not ctf_modebase.match_started then
			return "The match hasn't started yet!"
		end

		ctf_combat_mode.set(patient, player, "healer", 60, false)
		recent_rankings.add(player, {hp_healed = amount}, true)
	end,
}

end
