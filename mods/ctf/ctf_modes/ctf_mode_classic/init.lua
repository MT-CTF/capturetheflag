mode_classic = {
	SUMMARY_RANKS = {
		_sort = "score",
		"score",
		"flag_captures", "flag_attempts",
		"kills", "kill_assists", "bounty_kills",
		"deaths",
		"hp_healed"
	}
}

local flag_huds, rankings, build_timer, crafts = ctf_core.include_files(
	"flag_huds.lua",
	"rankings.lua",
	"build_timer.lua",
	"crafts.lua"
)

local function BOUNTY_REWARD_FUNC(pname, pteam)
	local match_rank = rankings.recent()[pname] or {}
	local kd = (match_rank.kills or 1) / (match_rank.deaths or 1)

	return {bounty_kills = 1, score = math.max(0, math.min(500, kd * 50))}
end

local FLAG_CAPTURE_TIMER = 60 * 3

local function calculate_killscore(player)
	local pname = PlayerName(player)
	local match_rank = rankings.recent()[pname] or {}
	local kd = (match_rank.kills or 1) / (match_rank.deaths or 1)
	local bounty_reward = ctf_modebase.bounties:player_has(pname)

	return math.round(kd * 5) + (bounty_reward and bounty_reward.score or 0)
end

function mode_classic.tp_player_near_flag(player)
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

function mode_classic.celebrate_team(teamname)
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

local function insert_team_totals(match_rankings, total)
	if not match_rankings then return {} end

	local ranks = table.copy(match_rankings)

	for team, rank_values in pairs(total) do
		rank_values._special_row = true
		rank_values._row_color = ctf_teams.team[team].color

		-- There will be problems with this if player names can contain spaces
		ranks[HumanReadable("team "..team)] = rank_values
	end

	return ranks
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
				bounty.score = nil

				for name, amount in pairs(bounty) do
					rewards[name] = amount
				end

				ctf_modebase.bounties:remove(player)
			end

			rankings.add(killer, rewards)

			-- share kill score with healers
			ctf_combat_mode.manage_extra(killer, function(pname, type)
				if type == "healer" then
					rankings.add(pname, {score = killscore})
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

local flag_captured = false
local next_team = "red"
ctf_modebase.register_mode("classic", {
	map_whitelist = {
		"bridge", "caverns", "coast", "iceage", "two_hills", "plains", "desert_spikes",
		"river_valley",
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

		["ctf_melee:sword_steel"  ] = {rarity = 0.2  , max_stacks = 2},
		["ctf_melee:sword_mese"   ] = {rarity = 0.01 , max_stacks = 1},
		["ctf_melee:sword_diamond"] = {rarity = 0.001, max_stacks = 1},

		["ctf_ranged:pistol_loaded" ] = {rarity = 0.2 , max_stacks = 2},
		["ctf_ranged:rifle_loaded"  ] = {rarity = 0.2                 },
		["ctf_ranged:shotgun_loaded"] = {rarity = 0.05                },
		["ctf_ranged:smg_loaded"    ] = {rarity = 0.05                },

		["ctf_ranged:ammo"     ] = {min_count = 3, max_count = 10, rarity = 0.3 , max_stacks = 2},
		["default:apple"       ] = {min_count = 5, max_count = 20, rarity = 0.1 , max_stacks = 2},
		["ctf_healing:bandage" ] = {                               rarity = 0.2 , max_stacks = 1},

		["grenades:frag" ] = {rarity = 0.1, max_stacks = 1},
		["grenades:smoke"] = {rarity = 0.2, max_stacks = 2},
	},
	crafts = crafts,
	physics = {sneak_glitch = true, new_move = false},
	commands = {"ctf_start", "rank", "r"},
	on_mode_start = function()
		ctf_modebase.bounties.get_next_bounty = function(team_members)
			local best_kd = {amount = 0}
			local recent = rankings.recent()

			for _, pname in pairs(team_members) do
				local kd = (recent[pname].kills or 1) / (recent[pname].deaths or 1)

				if kd > best_kd.amount then
					best_kd.amount = kd
					best_kd.name = pname
				end
			end

			return best_kd.name
		end
	end,
	on_new_match = function(mapdef)
		rankings.next_match()

		flag_huds.clear_capturers()

		flag_captured = false

		build_timer.start(mapdef)

		give_initial_stuff.register_stuff_provider(function()
			return {"default:sword_stone", "default:pick_stone", "default:torch 15", "default:stick 5"}
		end)

		ctf_map.place_chests(mapdef)
	end,
	allocate_player = function(player)
		player = player:get_player_name()

		local total = rankings.total()
		local bscore = (total.blue and total.blue.score) or 0
		local rscore = (total.red and total.red.score) or 0

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

		player:set_properties({
			textures = {ctf_cosmetics.get_colored_skin(player, tcolor)}
		})

		player:hud_set_hotbar_image("gui_hotbar.png^[colorize:" .. tcolor .. ":128")
		player:hud_set_hotbar_selected_image("gui_hotbar_selected.png^[multiply:" .. tcolor)

		rankings.set_team(player, teamname)

		ctf_playertag.set(player, ctf_playertag.TYPE_ENTITY)

		player:set_hp(player:get_properties().hp_max)

		mode_classic.tp_player_near_flag(player)

		give_initial_stuff(player)

		flag_huds.on_allocplayer(player)

		ctf_modebase.bounties:update_team_bounties(teamname, BOUNTY_REWARD_FUNC)
	end,
	on_leaveplayer = function(player)
		local pname = player:get_player_name()
		local pteam = ctf_teams.get(pname)
		local recent = rankings.recent()[pname]
		local count = 0

		for _ in pairs(recent or {}) do
			count = count + 1
		end

		if not recent or count <= 1 then
			rankings.reset_recent(pname)
		end

		if end_combat_mode(player) then
			rankings.add(player, {deaths = 1})
		end

		flag_huds.untrack_capturer(pname)

		ctf_modebase.bounties:remove(pname)

		if pteam then
			ctf_modebase.bounties:update_team_bounties(pteam, BOUNTY_REWARD_FUNC, pname)
		end
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
			if not build_timer.in_progress() then
				rankings.add(player, {deaths = 1})
			end
		end
	end,
	on_respawnplayer = function(player)
		if not build_timer.in_progress() then
			if ctf_modebase.delay_respawn(player, 7, 4) then
				return true
			end
		else
			if ctf_modebase.delay_respawn(player, 3) then
				return true
			end
		end

		give_initial_stuff(player)

		return mode_classic.tp_player_near_flag(player)
	end,
	on_flag_take = function(player, teamname)
		if build_timer.in_progress() then
			mode_classic.tp_player_near_flag(player)

			return "You can't take the enemy flag during build time!"
		end

		local pteam = ctf_teams.get(player)
		local tcolor = pteam and ctf_teams.team[pteam].color or "#FFF"
		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_BUILTIN, tcolor)

		mode_classic.celebrate_team(ctf_teams.get(player))

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
		mode_classic.celebrate_team(pteam)

		flag_captured = true

		flag_huds.update()

		flag_huds.clear_capturers()

		rankings.add(player, {score = 30, flag_captures = 1})

		for _, pname in pairs(minetest.get_connected_players()) do
			pname = pname:get_player_name()

			ctf_modebase.show_summary_gui(
				pname,
				insert_team_totals(rankings.recent(), rankings.total()),
				mode_classic.SUMMARY_RANKS,
				{
					title = HumanReadable(pteam).." Team Wins!",
					special_row_title = "Total Team Score",
					buttons = {previous = true}
				}
			)
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
	summary_func = function(name, param)
		if not param or param == "" then
			return true, insert_team_totals(
				rankings.recent(),
				rankings.total()
			), mode_classic.SUMMARY_RANKS, {
				title = "Match Summary",
				special_row_title = "Total Team Stats",
				buttons = {previous = true}
			}
		elseif param:match("p") then
			return true, insert_team_totals(
				rankings.previous_recent(),
				rankings.previous_total()
			), mode_classic.SUMMARY_RANKS, {
				title = "Previous Match Summary",
				special_row_title = "Total Team Stats",
				buttons = {next = true}
			}
		else
			return false, "Don't understand param "..dump(param)
		end
	end,
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
		elseif build_timer.in_progress() then
			minetest.chat_send_player(hname, "The match hasn't started yet!")
			return true
		end

		if player ~= hitter then
			ctf_combat_mode.set(player, 15, {[hitter:get_player_name()] = "hitter"})
		end

		ctf_kill_list.on_punchplayer(player, hitter, ...)
	end,
	on_healplayer = function(player, patient, amount)
		ctf_combat_mode.set(patient, 15, {[player:get_player_name()] = "healer"})

		rankings.add(player, {hp_healed = amount}, true)
	end,
	calculate_knockback = function()
		return 0
	end,
})
