ctf_gui.init()

mode_classes = {
	SUMMARY_RANKS = {
		_sort = "score",
		"score",
		"flag_captures", "flag_attempts",
		"kills", "kill_assists", "bounty_kills",
		"deaths",
		"hp_healed"
	}
}

local rankings = ctf_modebase.feature_presets.rankings("classes", mode_classes)
local summary = ctf_modebase.feature_presets.summary(mode_classes, rankings)
local flag_huds = ctf_modebase.feature_presets.flag_huds
local bounties = ctf_modebase.feature_presets.bounties(rankings)

local crafts, classes = ctf_core.include_files(
	"crafts.lua",
	"classes.lua"
)

local FLAG_CAPTURE_TIMER = 60 * 3

local function calculate_killscore(player)
	local pname = PlayerName(player)
	local match_rank = rankings.recent()[pname] or {}
	local kd = (match_rank.kills or 1) / (match_rank.deaths or 1)

	return math.round(kd * 5)
end

function mode_classes.tp_player_near_flag(player)
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

function mode_classes.dist_from_flag(player)
	local tname = ctf_teams.get(player)

	if not tname then return 0 end

	return vector.distance(ctf_map.current_map.teams[tname].flag_pos, PlayerObj(player):get_pos())
end

function mode_classes.celebrate_team(teamname)
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
			local bounty = ctf_modebase.bounties:player_has(player)

			if bounty then
				for name, amount in pairs(bounty) do
					rewards[name] = (rewards[name] or 0) + amount
				end

				ctf_modebase.bounties:remove(player)
			end

			rankings.add(killer, rewards)

			-- share kill score with healers
			ctf_combat_mode.manage_extra(killer, function(pname, type)
				if type == "healer" then
					rankings.add(pname, {score = rewards.score})
				end

				return type
			end)
		else
			-- Only take score for suicide if they're in combat for being healed
			if victim_combat_mode and #attackers >= 1 then
				rankings.add(player, {score = -math.ceil(killscore/2)})
			end

			ctf_kill_list.add_kill("", "ctf_modebase_skull.png", player) -- suicide
		end

		for _, pname in pairs(attackers) do
			if not killer or pname ~= killer:get_player_name() then
				rankings.add(pname, {kill_assists = 1, score = math.ceil(killscore / #attackers)})
			end
		end
	end

	ctf_combat_mode.remove(player)

	return true
end

local flag_captured = true
local next_team = "red"
local old_bounty_reward_func = ctf_modebase.bounties.bounty_reward_func
local old_get_next_bounty = ctf_modebase.bounties.get_next_bounty
local old_get_colored_skin = ctf_cosmetics.get_colored_skin
ctf_modebase.register_mode("classes", {
	map_whitelist = {
		"bridge", "caverns", "coast", "iceage", "two_hills", "plains", "desert_spikes",
		"river_valley", "plain_battle", --"moon",
	},
	treasures = {
		["default:ladder_wood"] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:torch" ] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:cobble"] = {min_count = 45, max_count = 99, rarity = 0.4, max_stacks = 5},
		["default:wood"  ] = {min_count = 10, max_count = 60, rarity = 0.5, max_stacks = 4},

		["ctf_teams:door_steel"] = {rarity = 0.2, max_stacks = 3},

		["default:pick_steel"  ] = {rarity = 0.4, max_stacks = 3},
		["default:shovel_steel"] = {rarity = 0.4, max_stacks = 2},
		["default:axe_steel"   ] = {rarity = 0.4, max_stacks = 2},

		["ctf_ranged:pistol_loaded" ] = {rarity = 0.2 , max_stacks = 2},
		["ctf_ranged:rifle_loaded"  ] = {rarity = 0.2                 },
		["ctf_ranged:shotgun_loaded"] = {rarity = 0.05                },

		["ctf_ranged:ammo"     ] = {min_count = 3, max_count = 10, rarity = 0.3 , max_stacks = 2},
		["default:apple"       ] = {min_count = 5, max_count = 20, rarity = 0.1 , max_stacks = 2},

		["grenades:frag" ] = {rarity = 0.1, max_stacks = 1},
		["grenades:smoke"] = {rarity = 0.2, max_stacks = 2},
	},
	crafts = crafts,
	physics = {sneak_glitch = true, new_move = false},
	commands = {"ctf_start", "rank", "r"},
	is_bound_item = function(_, itemstack)
		local iname = itemstack:get_name()

		if itemstack:get_definition().groups.sword or
		iname:match("ctf_mode_classes:") or
		iname == "ctf_healing:bandage" then
			return true
		end
	end,
	on_mode_start = function()
		ctf_modebase.bounties.bounty_reward_func = bounties.bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = bounties.get_next_bounty

		ctf_cosmetics.get_colored_skin = function(player, color)
			local classname = classes.get_name(player)

			return old_get_colored_skin(player, color) .. (classname and "^ctf_mode_classes_"..classname.."_overlay.png" or "")
		end
	end,
	on_mode_end = function()
		ctf_modebase.bounties.bounty_reward_func = old_bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = old_get_next_bounty

		ctf_cosmetics.get_colored_skin = old_get_colored_skin

		flag_huds.clear_huds()

		classes.finish()
	end,
	on_new_match = function(mapdef)
		flag_captured = false

		classes.on_new_match()

		ctf_modebase.build_timer.start(mapdef, 60 * 1.5, function()
			summary.on_match_start()
			ctf_modebase.bounties:on_match_start()
		end)

		give_initial_stuff.register_stuff_provider(function(player)
			local initial_stuff = classes.get(player).items or {}

			table.insert_all(initial_stuff, {"default:pick_stone", "default:torch 15", "default:stick 5"})

			return(initial_stuff)
		end)

		ctf_map.place_chests(mapdef)
	end,
	on_match_end = function()
		summary.on_match_end()
		rankings.on_match_end()

		ctf_modebase.bounties:on_match_end()

		flag_huds.clear_capturers()
	end,
	allocate_player = function(player)
		player = player:get_player_name()

		local teams = rankings.teams()
		local bscore = (teams.blue and teams.blue.score) or 0
		local rscore = (teams.red and teams.red.score) or 0

		if math.abs(bscore - rscore) <= 100 then
			if not ctf_teams.remembered_player[player] then
				ctf_teams.set(player, next_team)
				next_team = next_team == "red" and "blue" or "red"
			else
				ctf_teams.set(player, ctf_teams.remembered_player[player])
			end
		elseif bscore > rscore then
			-- Only allocate player to remembered team if they aren't desperately needed in the other
			if ctf_teams.remembered_player[player] and bscore - rscore < 500 then
				ctf_teams.set(player, ctf_teams.remembered_player[player])
			else
				ctf_teams.set(player, "red")
			end
		else
			-- Only allocate player to remembered team if they aren't desperately needed in the other
			if ctf_teams.remembered_player[player] and rscore - bscore < 500 then
				ctf_teams.set(player, ctf_teams.remembered_player[player])
			else
				ctf_teams.set(player, "blue")
			end
		end
	end,
	on_allocplayer = function(player, teamname)
		local tcolor = ctf_teams.team[teamname].color
		player:hud_set_hotbar_image("gui_hotbar.png^[colorize:" .. tcolor .. ":128")
		player:hud_set_hotbar_selected_image("gui_hotbar_selected.png^[multiply:" .. tcolor)

		rankings.set_team(player, teamname)

		ctf_playertag.set(player, ctf_playertag.TYPE_ENTITY)

		classes.set(player)

		player:set_hp(player:get_properties().hp_max)

		mode_classes.tp_player_near_flag(player)

		flag_huds.on_allocplayer(player)

		ctf_modebase.bounties:on_player_join(player)
	end,
	on_leaveplayer = function(player)
		local pname = player:get_player_name()

		rankings.on_leaveplayer(pname)

		if end_combat_mode(player) then
			rankings.add(player, {deaths = 1})
		end

		flag_huds.untrack_capturer(pname)
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
				rankings.add(player, {deaths = 1})
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

		return mode_classes.tp_player_near_flag(player)
	end,
	on_flag_rightclick = function(clicker, pos, node)
		classes:show_class_formspec(clicker)
	end,
	on_flag_take = function(player, teamname)
		if ctf_modebase.build_timer.in_progress() then
			mode_classes.tp_player_near_flag(player)

			return "You can't take the enemy flag during build time!"
		end

		local pteam = ctf_teams.get(player)
		local tcolor = pteam and ctf_teams.team[pteam].color or "#FFF"
		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_BUILTIN, tcolor)

		mode_classes.celebrate_team(ctf_teams.get(player))

		rankings.add(player, {score = 20, flag_attempts = 1})

		flag_huds.update()

		flag_huds.track_capturer(player, FLAG_CAPTURE_TIMER)
	end,
	on_flag_drop = function(player, teamname)
		flag_huds.update()

		flag_huds.untrack_capturer(player)

		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_ENTITY)
	end,
	on_flag_capture = function(player, captured_team)
		local pteam = ctf_teams.get(player)
		local tcolor = ctf_teams.team[pteam].color

		mode_classes.celebrate_team(pteam)

		flag_captured = true

		flag_huds.update()

		flag_huds.clear_capturers()

		rankings.add(player, {score = 30, flag_captures = 1})

		summary.set_winner(string.format("Player %s captured",  minetest.colorize(tcolor, player)))

		for _, pname in pairs(minetest.get_connected_players()) do
			local match_rankings, special_rankings, rank_values, formdef = summary.summary_func()
			formdef.title = HumanReadable(pteam) .." Team Wins!"
			ctf_modebase.show_summary_gui(pname:get_player_name(), match_rankings, special_rankings, rank_values, formdef)
		end

		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_ENTITY)

		minetest.after(3, ctf_modebase.start_new_match)
	end,
	get_chest_access = function(pname)
		local rank = rankings.get(pname)
		local deny_pro = "You need to have more than 1.5 kills per death, "..
				"10 captures, and at least 10,000 score to access the pro section"

		-- Remember to update /makepro in rankings.lua if you change anything here
		if rank then
			if (rank.score or 0) >= 10000 and (rank.kills or 0) / (rank.deaths or 0) >= 1.5 and rank.flag_captures >= 10 then
				return true, true
			elseif (rank.score or 0) >= 10 then
				return true, deny_pro
			end
		end

		return "You need at least 10 score to access this chest", deny_pro
	end,
	summary_func = function(prev) return summary.summary_func(prev) end,
	on_punchplayer = function(player, hitter, ...)
		if flag_captured then return true end

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
		local stats = {hp_healed = amount}

		if ctf_combat_mode.get(patient) then
			ctf_combat_mode.set(patient, 15, {[player:get_player_name()] = "healer"})
		else
			stats.score = amount/2
		end

		rankings.add(player, stats, true)
	end,
	calculate_knockback = function()
		return 0
	end,
})
