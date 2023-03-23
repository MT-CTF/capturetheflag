ctf_modebase.features = function(rankings, recent_rankings)

local FLAG_MESSAGE_COLOR = "#d9b72a"
local FLAG_CAPTURE_TIMER = 60 * 3
local many_teams = false
local team_list
local teams_left

local function calculate_killscore(player)
	local match_rank = recent_rankings.players()[player] or {}
	local kd = (match_rank.kills or 1) / (match_rank.deaths or 1)

	return math.max(1, math.round(kd * 7))
end

local damage_group_textures = {
	grenade = "grenades_frag.png",
	knockback_grenade = "ctf_mode_nade_fight_knockback_grenade.png",
	black_hole_grenade = "ctf_mode_nade_fight_black_hole_grenade.png",
	damage_cobble = "ctf_map_damage_cobble.png",
}

local function get_weapon_image(hitter, tool_capabilities)
	local image

	for group, texture in pairs(damage_group_textures) do
		if tool_capabilities.damage_groups[group] then
			image = texture
			break
		end
	end

	if not image then
		image = hitter:get_wielded_item():get_definition().inventory_image
	end

	if image == "" then
		image = "ctf_kill_list_punch.png"
	end

	if tool_capabilities.damage_groups.ranged then
		image = image .. "^[transformFX"
	elseif tool_capabilities.damage_groups.poison_grenade then
		image = "grenades_smoke_grenade.png^[multiply:#00ff00"
	end

	return image
end

local function get_suicide_image(reason)
	local image = "ctf_modebase_skull.png"

	if reason.type == "node_damage" then
		local node = reason.node
		if node == "ctf_map:spike" then
			image = "ctf_map_spike.png"
		elseif node:match("default:lava") then
			image = "default_lava.png"
		elseif node:match("fire:") then
			image = "fire_basic_flame.png"
		end
	elseif reason.type == "drown" then
		image = "default_water.png"
	end

	return image
end

local function tp_player_near_flag(player)
	local tname = ctf_teams.get(player)
	if not tname then return end

	local pos = vector.offset(ctf_map.current_map.teams[tname].flag_pos,
		math.random(-1, 1),
		0.5,
		math.random(-1, 1)
	)
	local rotation_y = vector.dir_to_rotation(
		vector.direction(pos, ctf_map.current_map.teams[tname].look_pos or ctf_map.current_map.flag_center)
	).y

	local function apply()
		player:set_pos(pos)
		player:set_look_vertical(0)
		player:set_look_horizontal(rotation_y)
	end

	apply()
	minetest.after(0.1, function() -- TODO remove after respawn bug will be fixed
		if player:is_player() then
			apply()
		end
	end)

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

local function end_combat_mode(player, reason, killer, weapon_image)
	local comment = nil

	if reason == "combatlog" then
		killer, weapon_image = ctf_combat_mode.get_last_hitter(player)
		if killer then
			comment = " (Combat Log)"
			recent_rankings.add(player, {deaths = 1}, true)
		end
	else
		if reason ~= "punch" or killer == player then
			if reason == "punch" then
				ctf_kill_list.add(player, player, weapon_image)
			else
				ctf_kill_list.add("", player, get_suicide_image(reason))
			end
			killer, weapon_image = ctf_combat_mode.get_last_hitter(player)
			comment = " (Suicide)"
		end
		recent_rankings.add(player, {deaths = 1}, true)
	end

	if killer then
		local killscore = calculate_killscore(player)

		local rewards = {kills = 1, score = killscore}
		local bounty = ctf_modebase.bounties.claim(player, killer)

		if bounty then
			for name, amount in pairs(bounty) do
				rewards[name] = (rewards[name] or 0) + amount
			end
		end

		recent_rankings.add(killer, rewards)

		ctf_kill_list.add(killer, player, weapon_image, comment)

		-- share kill score with other hitters
		local hitters = ctf_combat_mode.get_other_hitters(player, killer)
		for _, pname in ipairs(hitters) do
			recent_rankings.add(pname, {kill_assists = 1, score = math.ceil(killscore / #hitters)})
		end

		-- share kill score with healers
		local healers = ctf_combat_mode.get_healers(killer)
		for _, pname in ipairs(healers) do
			recent_rankings.add(pname, {score = math.ceil(killscore / #healers)})
		end

		if ctf_combat_mode.is_only_hitter(killer, player) then
			ctf_combat_mode.set_kill_time(killer, 5)
		end
	end

	ctf_combat_mode.end_combat(player)
end

local function can_punchplayer(player, hitter)
	if not ctf_modebase.match_started then
		return false, "The match hasn't started yet!"
	end

	local pname, hname = player:get_player_name(), hitter:get_player_name()
	local pteam, hteam = ctf_teams.get(player), ctf_teams.get(hitter)

	if not ctf_modebase.remove_respawn_immunity(hitter) then
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

	return true
end

local item_levels = {
	"wood",
	"stone",
	"bronze",
	"steel",
	"mese",
	"diamond",
}

local delete_queue = {}

return {
	on_new_match = function()
		team_list = {}
		for tname in pairs(ctf_map.current_map.teams) do
			table.insert(team_list, tname)
		end
		teams_left = #team_list
		many_teams = #team_list > 2

		local map_treasures = table.copy(ctf_modebase:get_current_mode().treasures or {})

		for k, v in pairs(ctf_map.treasure.treasure_from_string(ctf_map.current_map.treasures)) do
			map_treasures[k] = v
		end

		if #delete_queue > 0 then
			local p1, p2 = unpack(delete_queue)

			for _, object_drop in pairs(minetest.get_objects_in_area(p1, p2)) do
				if not object_drop:is_player() then
					local drop = object_drop:get_luaentity()

					if drop and drop.name == "__builtin:item" then
						object_drop:remove()
					end
				end
			end

			minetest.delete_area(p1, p2)

			delete_queue = {}
		end

		ctf_map.prepare_map_nodes(
			ctf_map.current_map,
			function(inv) ctf_map.treasure.treasurefy_node(inv, map_treasures) end,
			ctf_modebase:get_current_mode().team_chest_items or {},
			ctf_modebase:get_current_mode().blacklisted_nodes or {}
		)
	end,
	on_match_end = function()
		recent_rankings.on_match_end()

		if ctf_map.current_map then
			-- Queue deletion for after the players have left
			delete_queue = {ctf_map.current_map.pos1, ctf_map.current_map.pos2}
		end
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
		if remembered_team and not ctf_modebase.flag_captured[remembered_team] and kd_diff <= 0.6 and players_diff < 5 then
			return remembered_team
		end

		if players_diff == 0 or (kd_diff > 0.4 and players_diff < 2) then
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
	end,
	on_flag_take = function(player, teamname)
		local pname = player:get_player_name()
		local pteam = ctf_teams.get(player)
		local tcolor = ctf_teams.team[pteam].color

		ctf_modebase.remove_immunity(player)
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
	on_flag_drop = function(player, teamnames, pteam)
		local pname = player:get_player_name()
		local tcolor = pteam and ctf_teams.team[pteam].color or "#FFF"

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
			ctf_combat_mode.end_combat(player)
			return
		end

		local pname = player:get_player_name()

		-- should be no_hud to avoid a race
		end_combat_mode(pname, "combatlog")

		recent_rankings.on_leaveplayer(pname)
	end,
	on_dieplayer = function(player, reason)
		if not ctf_modebase.match_started then return end

		-- punch is handled in on_punchplayer
		if reason.type ~= "punch" then
			end_combat_mode(player:get_player_name(), reason)
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

		-- Remember to update /make_pro in ranking_commands.lua if you change anything here
		if rank then
			if (rank.score or 0) <= 8000 then
				if (rank.score or 0) >= 10 then
					return true, deny_pro
				else
					return false, deny_pro
				end
			end
			if
				((rank.kills or 0) + (rank.kill_assists or 0) * 0.34) / (rank.deaths or 1) >= 1.4 or
				(rank.flag_captures or 0) / (rank.deaths or 1) >= 1/14 or
				(rank.hp_healed or 0) / (rank.deaths or 1) >= 30
			then
				return true, true
			end
		end

		return "You need at least 10 score to access this chest", deny_pro
	end,
	can_punchplayer = can_punchplayer,
	on_punchplayer = function(player, hitter, damage, _, tool_capabilities)
		if not hitter:is_player() or player:get_hp() <= 0 then return false end

		local allowed, message = can_punchplayer(player, hitter)

		if not allowed then
			return false, message
		end

		local weapon_image = get_weapon_image(hitter, tool_capabilities)

		if player:get_hp() <= damage then
			end_combat_mode(player:get_player_name(), "punch", hitter:get_player_name(), weapon_image)
		elseif player:get_player_name() ~= hitter:get_player_name() then
			ctf_combat_mode.add_hitter(player, hitter, weapon_image, 15)
		end

		return damage
	end,
	on_healplayer = function(player, patient, amount)
		if not ctf_modebase.match_started then
			return "The match hasn't started yet!"
		end

		local score = nil

		if ctf_combat_mode.in_combat(patient) then
			score = 1
		end

		ctf_combat_mode.add_healer(patient, player, 60)
		recent_rankings.add(player, {hp_healed = amount, score = score}, true)
	end,
	initial_stuff_item_levels = {
		pick = function(item)
			local match = item:get_name():match("default:pick_(%a+)")

			if match then
				return table.indexof(item_levels, match)
			end
		end,
		axe = function(item)
			local match = item:get_name():match("default:axe_(%a+)")

			if match then
				return table.indexof(item_levels, match)
			end
		end,
		shovel = function(item)
			local match = item:get_name():match("default:shovel_(%a+)")

			if match then
				return table.indexof(item_levels, match)
			end
		end,
		sword = function(item)
			local mod, match = item:get_name():match("(%a+):sword_(%a+)")

			if mod and (mod == "default" or mod == "ctf_melee") and match then
				return table.indexof(item_levels, match)
			end
		end,
	}
}

end
