local rankings = ctf_rankings.init()
local recent_rankings = ctf_modebase.recent_rankings(rankings)
local features = ctf_modebase.features(rankings, recent_rankings)

local classes = ctf_core.include_files(
	"paxel.lua",
	"classes.lua"
)

local old_bounty_reward_func = ctf_modebase.bounties.bounty_reward_func
local old_get_next_bounty = ctf_modebase.bounties.get_next_bounty
local old_get_skin = ctf_cosmetics.get_skin
local custom_item_levels = table.copy(features.initial_stuff_item_levels)

local function prioritize_medic_paxel(tooltype)
	return function(item)
		local iname = item:get_name()

		if iname == "ctf_mode_classes:support_paxel" then
			return
				features.initial_stuff_item_levels[tooltype](
					ItemStack(string.format("default:%s_steel", tooltype))
				) + 0.1,
				true
		else
			return features.initial_stuff_item_levels[tooltype](item)
		end
	end
end

custom_item_levels.pick   = prioritize_medic_paxel("pick"  )
custom_item_levels.axe    = prioritize_medic_paxel("axe"   )
custom_item_levels.shovel = prioritize_medic_paxel("shovel")

ctf_modebase.register_mode("classes", {
	treasures = {
		["default:ladder_wood" ] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:torch"       ] = {                max_count = 20, rarity = 0.3, max_stacks = 5},

		["default:cobble"      ] = {min_count = 50, max_count = 99, rarity = 0.3, max_stacks = 2},
		["default:wood"        ] = {min_count = 50, max_count = 99, rarity = 0.2, max_stacks = 2},

		["ctf_teams:door_steel"] = {rarity = 0.2, max_stacks = 3},

		["default:pick_steel"  ] = {rarity = 0.4, max_stacks = 3},
		["default:shovel_steel"] = {rarity = 0.4, max_stacks = 2},
		["default:axe_steel"   ] = {rarity = 0.4, max_stacks = 2},

		["ctf_ranged:pistol_loaded"        ] = {rarity = 0.2 , max_stacks = 2},
		["ctf_ranged:shotgun_loaded"       ] = {rarity = 0.05                },
		["ctf_ranged:smg_loaded"           ] = {rarity = 0.05                },
		["ctf_ranged:sniper_magnum_loaded" ] = {rarity = 0.05                },

		["ctf_map:unwalkable_dirt"  ] = {min_count = 5, max_count = 26, max_stacks = 1, rarity = 0.1},
		["ctf_map:unwalkable_stone" ] = {min_count = 5, max_count = 26, max_stacks = 1, rarity = 0.1},
		["ctf_map:unwalkable_cobble"] = {min_count = 5, max_count = 26, max_stacks = 1, rarity = 0.1},
		["ctf_map:spike"            ] = {min_count = 1, max_count =  5, max_stacks = 2, rarity = 0.2},
		["ctf_map:damage_cobble"    ] = {min_count = 5, max_count = 20, max_stacks = 2, rarity = 0.2},
		["ctf_map:reinforced_cobble"] = {min_count = 5, max_count = 25, max_stacks = 2, rarity = 0.2},

		["ctf_ranged:ammo"    ] = {min_count = 3, max_count = 10, rarity = 0.3  , max_stacks = 2},
		["ctf_healing:medkit" ] = {                               rarity = 0.08 , max_stacks = 2},

		["grenades:frag" ] = {rarity = 0.1, max_stacks = 1},
		["grenades:smoke"] = {rarity = 0.2, max_stacks = 2},
		["grenades:poison"] = {rarity = 0.1, max_stacks = 2},
	},
	crafts = {
		"ctf_ranged:ammo", "default:axe_mese", "default:axe_diamond", "default:shovel_mese", "default:shovel_diamond",
		"ctf_map:damage_cobble", "ctf_map:spike", "ctf_map:reinforced_cobble 2",
	},
	physics = {sneak_glitch = true, new_move = false},
	blacklisted_nodes = {"default:apple"},
	team_chest_items = {
		"default:cobble 80", "default:wood 80", "ctf_map:damage_cobble 20", "ctf_map:reinforced_cobble 20",
		"default:torch 30", "ctf_teams:door_steel 2",
	},
	rankings = rankings,
	recent_rankings = recent_rankings,
	summary_ranks = {
		_sort = "score",
		"score",
		"flag_captures", "flag_attempts",
		"kills", "kill_assists", "bounty_kills",
		"deaths",
		"hp_healed"
	},
	build_timer = 90,
	is_bound_item = function(_, name)
		if name:match("ctf_mode_classes:") or name:match("ctf_melee:") or name == "ctf_healing:bandage" then
			return true
		end
	end,
	stuff_provider = function(player)
		local initial_stuff = table.copy(classes.get(player).items or {})
		table.insert_all(initial_stuff, {"default:pick_stone", "default:torch 15", "default:stick 5"})
		return initial_stuff
	end,
	initial_stuff_item_levels = custom_item_levels,
	is_restricted_item = classes.is_restricted_item,
	on_mode_start = function()
		ctf_modebase.bounties.bounty_reward_func = ctf_modebase.bounty_algo.kd.bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = ctf_modebase.bounty_algo.kd.get_next_bounty

		ctf_cosmetics.get_skin = function(player)
			if not ctf_teams.get(player) then
				return old_get_skin(player)
			end

			return old_get_skin(player) .. classes.get_skin_overlay(player)
		end
	end,
	on_mode_end = function()
		ctf_modebase.bounties.bounty_reward_func = old_bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = old_get_next_bounty
		ctf_cosmetics.get_skin = old_get_skin

		classes.finish()
	end,
	on_new_match = function()
		features.on_new_match()

		classes.reset_class_cooldowns()
	end,
	on_match_end = features.on_match_end,
	team_allocator = features.team_allocator,
	on_allocplayer = function(player, new_team)
		classes.update(player)
		features.on_allocplayer(player, new_team)
	end,
	on_leaveplayer = features.on_leaveplayer,
	on_dieplayer = features.on_dieplayer,
	on_respawnplayer = function(player, ...)
		features.on_respawnplayer(player, ...)

		classes.reset_class_cooldowns(player)
	end,
	can_take_flag = features.can_take_flag,
	on_flag_take = features.on_flag_take,
	on_flag_drop = features.on_flag_drop,
	on_flag_capture = features.on_flag_capture,
	on_flag_rightclick = function(clicker)
		classes.show_class_formspec(clicker)
	end,
	get_chest_access = features.get_chest_access,
	on_punchplayer = features.on_punchplayer,
	can_punchplayer = features.can_punchplayer,
	on_healplayer = features.on_healplayer,
	calculate_knockback = function(player, hitter, time_from_last_punch, tool_capabilities, dir, distance, damage)
		if features.can_punchplayer(player, hitter) then
			return 2 * (tool_capabilities.damage_groups.knockback or 1)
		else
			return 0
		end
	end,
})
