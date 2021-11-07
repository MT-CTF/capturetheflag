return function(rankings, recent_rankings, flag_huds)

local FLAG_MESSAGE_COLOR = "#d9b72a"
local FLAG_CAPTURE_TIMER = 60 * 3
local match_over = true
local next_team
local team_list
local teams_left

local function calculate_killscore(player)
	local pname = PlayerName(player)
	local match_rank = recent_rankings.players()[pname] or {}
	local kd = (match_rank.kills or 1) / (match_rank.deaths or 1)

	return math.round(kd * 5)
end

local function tp_player_near_flag(player)
	local tname = ctf_teams.get(player)

	if not tname then return end

	PlayerObj(player):set_pos(
		vector.offset(ctf_map.current_map.teams[tname].flag_pos,
			math.random(-1, 1),
			0.5,
			math.random(-1, 1)
		)
	)

	return true
end

local function celebrate_team(teamname)
	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local pteam = ctf_teams.player_team[pname].name

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

-- Returns true if player was in combat mode
local function end_combat_mode(player, killer)
	local victim_combat_mode = ctf_combat_mode.get(player)

	if not victim_combat_mode then return end

	if killer ~= player then
		local killscore = calculate_killscore(player)
		local attackers = {}

		-- populate attackers table
		ctf_combat_mode.manage_extra(player, function(pname, type)
			if type == "hitter" then
				table.insert(attackers, pname)
			else
				return type
			end
		end)

		if killer then
			local rewards = {kills = 1, score = killscore}
			local bounty = ctf_modebase.bounties.player_has(player)

			if bounty then
				for name, amount in pairs(bounty) do
					rewards[name] = (rewards[name] or 0) + amount
				end

				ctf_modebase.bounties.remove(player)
			end

			recent_rankings.add(killer, rewards)

			-- share kill score with healers
			ctf_combat_mode.manage_extra(killer, function(pname, type)
				if type == "healer" then
					recent_rankings.add(pname, {score = rewards.score})
				end

				return type
			end)
		else
			-- Only take score for suicide if they're in combat for being healed
			if victim_combat_mode and #attackers >= 1 then
				recent_rankings.add(player, {score = -math.ceil(killscore/2)})
			end

			ctf_kill_list.add_kill("", "ctf_modebase_skull.png", player) -- suicide
		end

		for _, pname in pairs(attackers) do
			if not killer or pname ~= killer:get_player_name() then
				recent_rankings.add(pname, {kill_assists = 1, score = math.ceil(killscore / #attackers)})
			end
		end
	end

	ctf_combat_mode.remove(player)

	return true
end

return {
	on_new_match = function()
		match_over = false

		next_team = 1
		team_list = {}
		for tname in pairs(ctf_map.current_map.teams) do
			table.insert(team_list, tname)
		end
		teams_left = #team_list
	end,
	on_match_end = function()
		match_over = true
	end,
	allocate_player = function(player)
		player = PlayerName(player)

		local teams = recent_rankings.teams()
		local best_score = nil
		local worst_score = nil

		for _, team in pairs(team_list) do
			local score = (teams[team] and teams[team].score) or 0
			if not best_score or score > best_score.s then
				best_score = {s = score, t = team}
			end

			if not worst_score or score < worst_score.s then
				worst_score = {s = score, t = team}
			end
		end

		local remembered_team = ctf_teams.remembered_player[player]
		if not best_score or best_score.s - worst_score.s <= 100 then
			if not remembered_team or ctf_modebase.flag_captured[remembered_team] then
				if next_team > #team_list then
					next_team = 1
				end

				ctf_teams.set(player, team_list[next_team])

				next_team = next_team + 1
			else
				ctf_teams.set(player, remembered_team)
			end
		else
			-- Allocate player to remembered team unless they're desperately needed in the other
			if remembered_team and not ctf_modebase.flag_captured[remembered_team] and best_score.s - worst_score.s <= 400 then
				ctf_teams.set(player, remembered_team)
			else
				ctf_teams.set(player, worst_score.t)
			end
		end
	end,
	can_take_flag = function(player, teamname)
		if ctf_modebase.build_timer.in_progress() then
			tp_player_near_flag(player)

			return "You can't take the enemy flag during build time!"
		end
	end,
	on_flag_take = function(player, teamname)
		local pteam = ctf_teams.get(player)
		local tcolor = pteam and ctf_teams.team[pteam].color or "#FFF"
		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_BUILTIN, tcolor)

		minetest.chat_send_all(
			minetest.colorize(tcolor, player) ..
			minetest.colorize(FLAG_MESSAGE_COLOR, " has taken " .. HumanReadable(teamname) .. "'s flag")
		)

		celebrate_team(ctf_teams.get(player))

		recent_rankings.add(player, {score = 20, flag_attempts = 1})

		flag_huds.track_capturer(player, FLAG_CAPTURE_TIMER)
	end,
	on_flag_drop = function(player, teamnames)
		local tcolor = ctf_teams.team[ctf_teams.get(player)].color or "#FFF"

		minetest.chat_send_all(
			minetest.colorize(tcolor, player) ..
			minetest.colorize(FLAG_MESSAGE_COLOR, " has dropped the flag of team(s) " .. HumanReadable(teamnames))
		)
		flag_huds.untrack_capturer(player)

		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_ENTITY)
	end,
	on_flag_capture = function(player, teamnames)
		local pteam = ctf_teams.get(player)
		local tcolor = ctf_teams.team[pteam].color or "#FFF"

		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_ENTITY)
		celebrate_team(pteam)

		minetest.chat_send_all(
			minetest.colorize(tcolor, player) ..
			minetest.colorize(FLAG_MESSAGE_COLOR, " has captured the flag of team(s) " .. HumanReadable(teamnames))
		)
		flag_huds.untrack_capturer(player)

		recent_rankings.add(player, {score = 30 * #teamnames, flag_captures = #teamnames})

		teams_left = teams_left - #teamnames

		if teams_left <= 1 then
			ctf_modebase.summary.set_winner(string.format("Player %s captured the last flag", minetest.colorize(tcolor, player)))

			local match_rankings, special_rankings, rank_values, formdef = ctf_modebase.summary.get()
			formdef.title = HumanReadable(pteam) .." Team Wins!"

			for _, pname in pairs(minetest.get_connected_players()) do
				ctf_modebase.summary.show_gui(pname:get_player_name(), match_rankings, special_rankings, rank_values, formdef)
			end

			match_over = true
			minetest.after(3, ctf_modebase.start_new_match)
		else
			for _, lost_team in ipairs(teamnames) do
				table.remove(team_list, table.indexof(team_list, lost_team))
				lost_team = ctf_teams.get_team(lost_team)

				for _, lost_player in ipairs(lost_team) do
					ctf_teams.allocate_player(lost_player)
				end
			end
		end
	end,
	on_allocplayer = function(player, teamname)
		local tcolor = ctf_teams.team[teamname].color

		player:set_properties({
			textures = {ctf_cosmetics.get_colored_skin(player, tcolor)}
		})

		player:hud_set_hotbar_image("gui_hotbar.png^[colorize:" .. tcolor .. ":128")
		player:hud_set_hotbar_selected_image("gui_hotbar_selected.png^[multiply:" .. tcolor)

		recent_rankings.set_team(player, teamname)

		ctf_playertag.set(player, ctf_playertag.TYPE_ENTITY)

		player:set_hp(player:get_properties().hp_max)

		tp_player_near_flag(player)

		give_initial_stuff(player)

		flag_huds.on_allocplayer(player)

		ctf_modebase.bounties.on_player_join(player)
	end,
	on_leaveplayer = function(player)
		local pname = player:get_player_name()

		if end_combat_mode(player) then
			recent_rankings.add(player, {deaths = 1})
		end

		recent_rankings.on_leaveplayer(pname)
	end,
	on_dieplayer = function(player, reason)
		if reason.type == "punch" and reason.object and reason.object:is_player() then
			end_combat_mode(player, reason.object)
		else
			if not end_combat_mode(player) then
				ctf_kill_list.add_kill("", "ctf_modebase_skull.png", player)
			end
		end

		if ctf_modebase.prep_delayed_respawn(player) then
			if not ctf_modebase.build_timer.in_progress() then
				recent_rankings.add(player, {deaths = 1})
			end
		end
	end,
	on_respawnplayer = function(player)
		if not ctf_modebase.build_timer.in_progress() then
			if ctf_modebase.delay_respawn(player, 7, 4) then
				return true
			end
		else
			if ctf_modebase.delay_respawn(player, 3) then
				return true
			end
		end

		give_initial_stuff(player)

		return tp_player_near_flag(player)
	end,
	get_chest_access = function(pname)
		local rank = rankings:get(pname)
		local deny_pro = "You need to have more than 1.5 kills per death, "..
				"10 captures, and at least 10,000 score to access the pro section"

		-- Remember to update /makepro in ranking_commands.lua if you change anything here
		if rank then
			if (rank.score or 0) >= 10000 and (rank.kills or 0) / (rank.deaths or 0) >= 1.5 and rank.flag_captures >= 10 then
				return true, true
			elseif (rank.score or 0) >= 10 then
				return true, deny_pro
			end
		end

		return "You need at least 10 score to access this chest", deny_pro
	end,
	on_punchplayer = function(player, hitter, ...)
		if match_over then return true end
		if not hitter:is_player() or player:get_hp() <= 0 then return end

		local pname, hname = player:get_player_name(), hitter:get_player_name()
		local pteam, hteam = ctf_teams.get(player), ctf_teams.get(hitter)

		if not pteam then
			minetest.chat_send_player(hname, pname .. " is not in a team!")
			return true
		elseif not hteam then
			minetest.chat_send_player(hname, "You are not in a team!")
			return true
		end

		if pteam == hteam and pname ~= hname then
			minetest.chat_send_player(hname, pname .. " is on your team!")

			return true
		elseif ctf_modebase.build_timer.in_progress() then
			minetest.chat_send_player(hname, "The match hasn't started yet!")
			return true
		end

		if player ~= hitter then
			ctf_combat_mode.set(player, 15, {[hitter:get_player_name()] = "hitter"})
		end

		ctf_kill_list.on_punchplayer(player, hitter, ...)
	end,
	on_healplayer = function(player, patient, amount)
		if match_over then return end
		local stats = {hp_healed = amount}

		if ctf_combat_mode.get(patient) then
			ctf_combat_mode.set(patient, 15, {[player:get_player_name()] = "healer"})
		else
			stats.score = math.ceil(amount/2)
		end

		recent_rankings.add(player, stats, true)
	end,
}

end
