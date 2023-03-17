local rankings = ctf_rankings.init()
local recent_rankings = ctf_modebase.recent_rankings(rankings)
local features = ctf_modebase(rankings, recent_rankings)

local old_bounty_reward_func = ctf_modebase.bounties.bounty_reward_func
local old_get_next_bounty = ctf_modebase.bounties.get_next_bounty
local old_get_skin = ctf_cosmetics.get_skin
local custom_item_levels = table.copy(features.initial_stuff_item_levels)

ctf_modebase.register_mode("flagwars", {
	treasures = {
		["default:ladder_wood"] = {
			max_count = 20,
			rarity = 0.3,
			max_stacks = 5
		},
		["default:torch"] = {
			max_count = 10,
			rarity = 0.3,
			max_stacks = 5,
		},
		["default:cobble"] = {
			max_count = 20,
			min_count = 2,
			max_stacks = 2,
			rarity = 0.15,
		},
		["default:wood"] = {
			max_count = 20,
			min_count = 2,
			max_stacks = 2,
			rarity = 0.15,
		},
	},
	crafts = {},
	physics = {
		sneak_glitch = true,
		new_move = false,
	},
	team_chest_items = {
		"default:cobble 40",
		"default:wood 40",
		"ctf_map:damage_cobble 20",
		"ctf_map:rinforcedc_cobble 20",
		"default:torch 10",
		"ctf_teams:door_steel 1",
	},
	rankings = rankings,
	recent_rankings = recent_rankings,
	summary_ranks = {
		_sort = "score",
		"score",
		"flag_captures",
		"flag_attempts",
		"kills",
		"kill_assits",
		"bounty_kills",
		"deaths",
		"hp_healed",
	},
	build_timer = 90,
	is_bound_item = function(_, name)
		return false
	end,
	stuff_provider = function(player)
		local initial_stuff = {
			"default:sword_stone",
			"default:torch 10",
			"default:cobble 10",
		}

		return initial_stuff
	end,
	initial_stuff_item_levels = custom_item_levels,
	is_restricted_item = function(player, name)
		return false
	end,
	on_mode_start = function()
		ctf_modebase.bounties.bounty_reward_func = ctf_modebase.bounty_algo.kd.bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = ctf_modebase.bounty_algo.kd.get_next_bounty
		ctf_cosmetics.get_skin = function(player)
			if not ctf_teams.get(player) then
				return old_get_skin(player)
			end

			return old_get_skin(player)
		end
	end,
	on_mode_end = function()
		ctf_modebase.bounties.bounty.bounty_reward_func = old_bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = old_get_next_bounty
		ctf_cosmetics.get_skin = old_get_skin
	end,
	on_new_match = features.on_new_match,
	on_match_end = features.on_match_end,
	team_allocator = features.team_allocator,
	on_allocplayer = features.on_allocplayer,
	on_leaveplayer = features.on_leaveplayer,
	on_dieplayer = features.on_dieplayer,
	on_respawn_player = features.on_respawnplayer,
	can_take_flag = features.can_take_flag,
	on_flag_take = function(player)
		ctf_modebase.capture_flag(player)
	end,
	on_flag_drop = function() end,
	on_flag_capture = features.on_flag_capture,
	on_flag_rightclick = function() end,
	get_chest_access = features.get_chest_access,
	can_punchplayer = features.can_punchplayer,
	on_punchplayer = features.on_punchplayer,
	on_healplayer = features.on_healplayer,
	calculate_knockback = function()
		return 0
	end,
})
