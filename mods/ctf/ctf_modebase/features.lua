local mapload_huds = mhud.init()
local LOADING_SCREEN_TARGET_TIME = 7
local loading_screen_time

local function supports_observers(x)
	if x then
		if x.object then x = x.object end

		if x.get_observers and x:get_pos() then
			return true
		end
	end

	return false
end

local function update_playertag(player, t, nametag, team_nametag, symbol_nametag)
	if not      supports_observers(nametag.object) or
	   not supports_observers(team_nametag.object) or
	   not supports_observers(symbol_nametag.object)
	then
		return
	end

	local entity_players = {}
	local nametag_players = ctf_modebase.get_allowed_nametag_observers(player)
	local symbol_players = {}
	nametag_players[player:get_player_name()] = nil

	for n, extra in pairs(table.copy(nametag_players)) do
		local setting = extra

		if setting == true then
			setting = ctf_settings.get(minetest.get_player_by_name(n), "teammate_nametag_style")
		end

		if setting == "3" then
			nametag_players[n] = nil
		elseif setting == "2" then
			symbol_players[n] = true
			nametag_players[n] = nil
		end
	end

	for k, v in ipairs(minetest.get_connected_players()) do
		local n = v:get_player_name()
		if not nametag_players[n] then
			entity_players[n] = true
		end
	end

	       nametag.object:set_observers(entity_players )
	  team_nametag.object:set_observers(nametag_players)
	symbol_nametag.object:set_observers(symbol_players )
end

local tags_hidden = false
local update_timer = false
function ctf_modebase.update_playertags(time)
	if not update_timer and not tags_hidden then
		update_timer = true
		minetest.after(time or 1.2, function()
			update_timer = false
			for _, p in pairs(minetest.get_connected_players()) do
				local t = ctf_teams.get(p)
				local playertag = playertag.get(p)

				if playertag then
					local team_nametag = playertag.nametag_entity
					local nametag = playertag.entity
					local symbol_entity = playertag.symbol_entity

					if t and nametag and team_nametag and symbol_entity then
						update_playertag(p, t, nametag, team_nametag, symbol_entity)
					end
				end
			end
		end)
	end
end

local PLAYERTAGS_OFF = false
local PLAYERTAGS_ON = true
local function set_playertags_state(state)
	if state == PLAYERTAGS_ON and tags_hidden then
		tags_hidden = false

		ctf_modebase.update_playertags(0)
	elseif state == PLAYERTAGS_OFF and not tags_hidden then
		tags_hidden = true

		for _, p in pairs(minetest.get_connected_players()) do
			local playertag = playertag.get(p)

			if ctf_teams.get(p) and playertag then
				local team_nametag = playertag.nametag_entity
				local nametag = playertag.entity
				local symbol_entity = playertag.symbol_entity

				if supports_observers(nametag) and supports_observers(team_nametag) and supports_observers(symbol_entity) then
					 team_nametag.object:set_observers({})
					symbol_entity.object:set_observers({})
					      nametag.object:set_observers({})
				end
			end
		end
	end
end

local old_announce = ctf_modebase.map_chosen
function ctf_modebase.map_chosen(map, ...)
	set_playertags_state(PLAYERTAGS_OFF)

	mapload_huds:clear_all()

	for _, p in pairs(minetest.get_connected_players()) do
		if ctf_teams.get(p) then
			mapload_huds:add(p, "loading_screen", {
				hud_elem_type = "image",
				position = {x = 0.5, y = 0.5},
				image_scale = -100,
				z_index = 1000,
				texture = "[combine:1x1^[invert:rgba^[opacity:1^[colorize:#141523:255"
			})

			mapload_huds:add(p, "map_image", {
				hud_elem_type = "image",
				position = {x = 0.5, y = 0.5},
				image_scale = -100,
				z_index = 1001,
				texture = map.dirname.."_screenshot.png^[opacity:30",
			})

			mapload_huds:add(p, "loading_text", {
				hud_elem_type = "text",
				position = {x = 0.5, y = 0.5},
				alignment = {x = "center", y = "up"},
				text_scale = 2,
				text = "Loading Map: " .. map.name .. "...",
				color = 0x7ec5ff,
				z_index = 1002,
			})
			mapload_huds:add(p, {
				hud_elem_type = "text",
				position = {x = 0.5, y = 0.75},
				alignment = {x = "center", y = "center"},
				text = random_messages.get_random_message(),
				color = 0xffffff,
				z_index = 1002,
			})
		end
	end

	loading_screen_time = minetest.get_us_time()

	return old_announce(map, ...)
end

ctf_settings.register("teammate_nametag_style", {
	type = "list",
	description = "Controls what style of nametag to use for teammates.",
	list = {"Minetest Nametag: Full", "Minetest Nametag: Symbol", "Entity Nametag"},
	default = "1",
	on_change = function(player, new_value)
		minetest.log("action", "Player "..player:get_player_name().." changed their nametag setting")
		ctf_modebase.update_playertags()
	end
})

ctf_modebase.features = function(rankings, recent_rankings)

local FLAG_MESSAGE_COLOR = "#d9b72a"
local FLAG_CAPTURE_TIMER = 60 * 3
local many_teams = false
local team_list
local teams_left

local function calculate_killscore(player)
	local match_rank = recent_rankings.players()[player] or {}
	local kd = (match_rank.kills or 1) / (match_rank.deaths or 1)
	local flag_multiplier = 1
	for tname, carrier in pairs(ctf_modebase.flag_taken) do
		if carrier.p == player then
			flag_multiplier = flag_multiplier * 2
		end
	end

	minetest.log("ACTION", string.format(
		"[KILLDEBUG] { og = %f, kills = %d, assists = %f, deaths = %d, score = %f, hp_healed = %f, attempts = %d, " ..
				"reward_given_to_enemy = %f },",
		math.max(1, math.round(kd * 7 * flag_multiplier)),
		match_rank.kills or 1,
		match_rank.kill_assists or 0,
		match_rank.deaths or 1,
		match_rank.score or 0,
		match_rank.hp_healed or 0,
		match_rank.flag_attempts or 0,
		match_rank.reward_given_to_enemy or 0
	))

	return math.max(1, math.round(kd * 7 * flag_multiplier))
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

	local rotation_y
	local pos

	if ctf_map.current_map.teams[tname] then
		pos = vector.offset(ctf_map.current_map.teams[tname].flag_pos,
			math.random(-1, 1),
			0.5,
			math.random(-1, 1)
		)
		rotation_y = vector.dir_to_rotation(
			vector.direction(pos, ctf_map.current_map.teams[tname].look_pos or ctf_map.current_map.flag_center)
		).y
	else
		pos = vector.add(ctf_map.current_map.pos1, vector.divide(ctf_map.current_map.size, 2))
		rotation_y = player:get_look_horizontal()
	end

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
		local volume = (tonumber(ctf_settings.get(player, "flag_sound_volume")) or 10.0) / 10

		if volume > 0 then
			if pteam == teamname then
				minetest.sound_play("ctf_modebase_trumpet_positive", {
					to_player = pname,
					gain = volume,
					pitch = 1.0,
				}, true)
			else
				minetest.sound_play("ctf_modebase_trumpet_negative", {
					to_player = pname,
					gain = volume,
					pitch = 1.0,
				}, true)
			end
		end
	end
end

local function drop_flag(teamname)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local pteam = ctf_teams.get(pname)
		local drop_volume = (tonumber(ctf_settings.get(player, "flag_sound_volume")) or 10.0) / 10

		if pteam and drop_volume > 0 then
			if pteam == teamname then
				minetest.sound_play("ctf_modebase_drop_flag_negative", {
					to_player = pname,
					gain = math.max(0.1, drop_volume - 0.5),
					pitch = 1.0,
				}, true)
			else
				minetest.sound_play("ctf_modebase_drop_flag_positive", {
					to_player = pname,
					gain = math.max(0.1, drop_volume - 0.5),
					pitch = 1.0,
				}, true)
			end
		end
	end
end

local function end_combat_mode(player, reason, killer, weapon_image)
	local comment = nil

	if ctf_teams.get(player) then
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
			local total_enemy_reward = 0

			local rewards = {kills = 1, score = killscore}
			local bounty = ctf_modebase.bounties.claim(player, killer)

			if bounty then
				for name, amount in pairs(bounty) do
					rewards[name] = (rewards[name] or 0) + amount
				end
			end

			recent_rankings.add(killer, rewards)
			total_enemy_reward = total_enemy_reward + rewards.score

			if ctf_teams.get(killer) then
				ctf_kill_list.add(killer, player, weapon_image, comment)
				hud_events.new(player, {
					quick = false,
					text = killer.." killed you for ".. rewards.score .." points!",
					color = "warning",
				})
			end

			-- share kill score with other hitters
			local hitters = ctf_combat_mode.get_other_hitters(player, killer)
			for _, pname in ipairs(hitters) do
				recent_rankings.add(pname, {kill_assists = 1, score = math.ceil(killscore / #hitters)})
				total_enemy_reward = total_enemy_reward + math.ceil(killscore / #hitters)
			end

			-- share kill score with healers
			local healers = ctf_combat_mode.get_healers(killer)
			for _, pname in ipairs(healers) do
				recent_rankings.add(pname, {score = math.ceil(killscore / #healers)})
				total_enemy_reward = total_enemy_reward + math.ceil(killscore / #healers)
			end

			recent_rankings.add(player, {reward_given_to_enemy = total_enemy_reward}, true)

			if ctf_combat_mode.is_only_hitter(killer, player) then
				ctf_combat_mode.set_kill_time(killer, 5)
			end
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
local team_switch_after_capture = false

return {
	tp_player_near_flag = tp_player_near_flag,

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

		if #delete_queue > 0 and delete_queue._map ~= ctf_map.current_map.dirname then
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

		if loading_screen_time then
			local total_time = (minetest.get_us_time() - loading_screen_time) / 1e6

			minetest.after(math.max(0, LOADING_SCREEN_TARGET_TIME - total_time), function()
				mapload_huds:clear_all()
				set_playertags_state(PLAYERTAGS_ON)

				ctf_modebase.build_timer.start()
			end)
		end
	end,
	on_match_end = function()
		recent_rankings.on_match_end()

		if ctf_map.current_map then
			minetest.log("action",
				"matchend: Match ended for map "..ctf_map.current_map.name..
				" in mode "..(ctf_modebase.current_mode or "<nil>")..
				". Duration: "..ctf_map.get_duration()
			)
			-- Queue deletion for after the players have left
			delete_queue = {ctf_map.current_map.pos1, ctf_map.current_map.pos2, _map = ctf_map.current_map.dirname}
		end
	end,
	-- If you set this in a mode def it will replace the call to ctf_teams.allocate_teams() in match.lua
	-- allocate_teams = function()
	team_allocator = function(player)
		player = PlayerName(player)

		local team_scores = recent_rankings.teams()

		local best_kd = nil
		local worst_kd = nil
		local best_players = nil
		local worst_players = nil
		local total_players = 0

		for _, team in ipairs(team_list) do
			local players_count = ctf_teams.online_players[team].count
			local players = ctf_teams.online_players[team].players

			local bk = 0
			local bd = 1

			for name in pairs(players) do
				local rank = rankings:get(name)

				if rank then
					if bk <= (rank.kills or 0) then
						bk = rank.kills or 0
						bd = rank.deaths or 0
					end
				end
			end

			total_players = total_players + players_count

			local kd = bk / bd
			local match_kd = 0
			local tk = 0
			if team_scores[team] then
				if (team_scores[team].score or 0) >= 50 then
					tk = team_scores[team].kills or 0

					kd = math.max(kd, (team_scores[team].kills or bk) / (team_scores[team].deaths or bd))
				end

				match_kd = (team_scores[team].kills or 0) / (team_scores[team].deaths or 1)
			end

			if not best_kd or match_kd > best_kd.a then
				best_kd = {s = kd, a = match_kd, t = team, kills = tk}
			end

			if not worst_kd or match_kd < worst_kd.a then
				worst_kd = {s = kd, a = match_kd, t = team, kills = tk}
			end

			if not best_players or players_count > best_players.s then
				best_players = {s = players_count, t = team}
			end

			if not worst_players or players_count < worst_players.s then
				worst_players = {s = players_count, t = team}
			end
		end

		if worst_players.s == 0 then
			return worst_players.t
		end

		local kd_diff = best_kd.s - worst_kd.s
		local actual_kd_diff = best_kd.a - worst_kd.a
		local players_diff = best_players.s - worst_players.s

		local rem_team = ctf_teams.get(player)
		local player_rankings = recent_rankings.get(player) --[pteam.."_score"]

		if not rem_team or
		math.max(player_rankings[rem_team.."_kills"] or 0, player_rankings[rem_team.."_deaths"] or 0) <= 6 then
			player_rankings = rankings:get(player) or {}
		else
			player_rankings.kills  = player_rankings[rem_team.."_kills"]  or 0
			player_rankings.deaths = player_rankings[rem_team.."_deaths"] or 1
		end

		local one_third     = math.ceil(0.34 * total_players)

		-- Allocate player to remembered team unless teams are imbalanced
		if rem_team and not ctf_modebase.flag_captured[rem_team] and
		(worst_kd.kills <= total_players or actual_kd_diff <= 0.8) and players_diff <= one_third then
			return rem_team
		end

		local pkd = (player_rankings.kills or 0) / (player_rankings.deaths or 1)

		local one_fourth     = math.ceil(0.25 * total_players)
		local avg = (kd_diff + actual_kd_diff) / 2
		local pcount_diff_limit = (
			(players_diff <= math.min(one_fourth, 1)) or
			(pkd >= 1.8 and players_diff <= math.min(one_third, 2))
		)
		if best_kd.kills + worst_kd.kills >= 30 then
			avg = actual_kd_diff
		end

		local result = pcount_diff_limit and ((best_kd.kills + worst_kd.kills >= 30 and best_kd.t == best_players.t) or
				(pkd >= math.min(1, kd_diff/2) and avg >= 0.4))

		if players_diff == 0 or result then
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

		recent_rankings.add(pname, {
			score = ctf_teams.online_players[teamname].count * 3 * #ctf_modebase.taken_flags[pname],
			flag_attempts = 1
		})

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

		if player.set_observers then
			ctf_modebase.update_playertags()
		end

		drop_flag(pteam)
	end,
	on_flag_capture = function(player, teamnames)
		local pname = player:get_player_name()
		local pteam = ctf_teams.get(pname)
		local tcolor = ctf_teams.team[pteam].color

		playertag.set(player, playertag.TYPE_ENTITY)

		if player.set_observers then
			ctf_modebase.update_playertags()
		end

		celebrate_team(pteam)

		ctf_modebase.flag_huds.untrack_capturer(pname)

		local team_scores = recent_rankings.teams()
		local player_scores = recent_rankings.players()
		local capture_reward = 0
		for _, lost_team in ipairs(teamnames) do
			local team_score = 0

			for n in pairs(ctf_teams.online_players[lost_team].players) do
				team_score = team_score + (player_scores[n].score or 0)
			end

			local score = team_score / math.max(1, ctf_teams.online_players[lost_team].count)
			score = math.max(
				8 * ((player_scores[pname].flag_attempts or 0) + math.min(
					(os.time() - ctf_map.start_time) / 60,
					10
				)),
				score * (2.4 + ctf_teams.online_players[lost_team].count/30)
			)

			score = math.max(score, #ctf_teams.get_connected_players() * 1.4)

			capture_reward = capture_reward + math.min(score, 800)

			minetest.log("action", string.format(
				"[CAPDEBUG] div: %.1f {team_score = %d, capture_score = %d, connected_players = %d, lost_team_count = %d, "..
				"player_attempts = %d, time = %d, winteam_score = %d, \"%s\"},",
				team_score / score,
				team_score,
				score,
				#ctf_teams.get_connected_players(),
				ctf_teams.online_players[lost_team].count,
				player_scores[pname].flag_attempts or 0,
				os.time() - ctf_map.start_time,
				team_scores[pteam].score or 0,
				many_teams and "many teams" or "2 teams"
			))
		end

		local text = string.format(" has captured the flag and got %d points", capture_reward)
		if many_teams then
			text = string.format(
				" has captured the flag of team(s) %s and got %d points",
				HumanReadable(teamnames),
				capture_reward
			)
		end

		minetest.chat_send_all(
			minetest.colorize(tcolor, pname) .. minetest.colorize(FLAG_MESSAGE_COLOR, text)
		)

		ctf_modebase.announce(string.format("Player %s (team %s)%s", pname, pteam, text))

		local team_score = team_scores[pteam].score
		local healers = ctf_combat_mode.get_healers(pname)
		for teammate in pairs(ctf_teams.online_players[pteam].players) do
			if teammate ~= pname then
				local teammate_value = (recent_rankings.get(teammate)[pteam.."_score"] or 0) / (team_score or 1)

				if table.indexof(healers, teammate) ~= -1 then
					teammate_value = teammate_value + ((#ctf_teams.get_connected_players() / 10) / #healers)
				end

				local victory_bonus = math.max(5, math.min(capture_reward / 2, capture_reward * teammate_value))
				recent_rankings.add(teammate, {score = victory_bonus}, true)
			end
		end

		recent_rankings.add(pname, {score = capture_reward, flag_captures = #teamnames})

		teams_left = teams_left - #teamnames

		if teams_left <= 1 then
			local capture_text = "Player %s captured and got %d points"
			if many_teams then
				capture_text = "Player %s captured the last flag and got %d points"
			end

			ctf_modebase.summary.set_winner(string.format(capture_text, minetest.colorize(tcolor, pname), capture_reward))

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
					team_switch_after_capture = true
					ctf_teams.allocate_player(lost_player)
					team_switch_after_capture = false
				end
			end
		end
	end,
	on_allocplayer = function(player, new_team)
		player:set_hp(player:get_properties().hp_max)

		if not team_switch_after_capture then
			ctf_modebase.update_wear.cancel_player_updates(player)

			ctf_modebase.player.remove_bound_items(player)
			ctf_modebase.player.give_initial_stuff(player)
		end

		local tcolor = ctf_teams.team[new_team].color
		player:hud_set_hotbar_image("gui_hotbar.png^[colorize:" .. tcolor .. ":128")
		player:hud_set_hotbar_selected_image("gui_hotbar_selected.png^[multiply:" .. tcolor)

		player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))

		recent_rankings.set_team(player, new_team)

		playertag.set(player, playertag.TYPE_ENTITY)

		if player.set_observers then
			ctf_modebase.update_playertags()
		end

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

		if ctf_teams.get(player) then
			ctf_modebase.prepare_respawn_delay(player)
		end
	end,
	on_respawnplayer = function(player)
		tp_player_near_flag(player)
	end,
	get_chest_access = function(pname)
		local rank = rankings:get(pname)
		local player = minetest.get_player_by_name(pname)
		local pro_chest = player and player:get_meta():get_int("ctf_rankings:pro_chest:"..
				(ctf_modebase.current_mode or "")) >= 1
		local deny_pro = "You need to have more than 1.4 kills per death, "..
		                 "5 captures, and at least 8,000 score to access the pro section."
		if rank then
			local captures_needed = math.max(0, 5 - (rank.flag_captures or 0))
			local score_needed = math.floor(math.max(0, 8000 - (rank.score or 0)))
			local current_kd = math.floor((rank.kills or 0) / (rank.deaths or 1) * 10)
			current_kd = current_kd / 10
			deny_pro = deny_pro .. " You still need " .. captures_needed
					   .. " captures, " .. score_needed ..
					   " score, and your kills per death is " ..
					   current_kd .. "."
		end

		-- Remember to update /make_pro in ranking_commands.lua if you change anything here
		if pro_chest or rank then
			if
				pro_chest
				or
				(rank.score or 0) >= 8000 and
				(rank.kills or 0) / (rank.deaths or 1) >= 1.4 and
				(rank.flag_captures or 0) >= 5
			then
				return true, true
			end

			if (rank.score or 0) >= 10 then
				return true, deny_pro
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
			local mod, match = item:get_name():match("([^:]+):sword_(%a+)")

			if mod and (mod == "default" or mod == "ctf_melee") and match then
				return table.indexof(item_levels, match)
			end
		end,
	}
}

end
