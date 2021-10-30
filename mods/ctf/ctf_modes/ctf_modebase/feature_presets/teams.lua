return function(rankings, summary, flag_huds)

local FLAG_MESSAGE_COLOR = "#d9b72a"
local FLAG_CAPTURE_TIMER = 60 * 3
local next_team
local team_list
local teams_left

return {
	on_new_match = function()
		next_team = 1
		team_list = {}
		for tname in pairs(ctf_map.current_map.teams) do
			table.insert(team_list, tname)
		end
		teams_left = #team_list
	end,
	allocate_player = function(player)
		player = PlayerName(player)

		local teams = rankings.teams()
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
			mode_classes.tp_player_near_flag(player)

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

		mode_classes.celebrate_team(ctf_teams.get(player))

		rankings.add(player, {score = 20, flag_attempts = 1})

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
		mode_classes.celebrate_team(pteam)

		minetest.chat_send_all(
			minetest.colorize(tcolor, player) ..
			minetest.colorize(FLAG_MESSAGE_COLOR, " has captured the flag of team(s) " .. HumanReadable(teamnames))
		)
		flag_huds.untrack_capturer(player)

		rankings.add(player, {score = 30 * #teamnames, flag_captures = #teamnames})

		teams_left = teams_left - #teamnames

		if teams_left <= 1 then
			summary.set_winner(string.format("Player %s captured the last flag", minetest.colorize(tcolor, player)))

			for _, pname in pairs(minetest.get_connected_players()) do
				local match_rankings, special_rankings, rank_values, formdef = summary.summary_func()
				formdef.title = HumanReadable(pteam) .." Team Wins!"
				ctf_modebase.show_summary_gui(pname:get_player_name(), match_rankings, special_rankings, rank_values, formdef)
			end

			return true
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
}

end