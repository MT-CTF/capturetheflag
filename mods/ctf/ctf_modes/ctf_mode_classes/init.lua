local rankings = ctf_rankings.init()
local recent_rankings = ctf_modebase.recent_rankings(rankings)
local features = ctf_modebase.features(rankings, recent_rankings)

local crafts, classes = ctf_core.include_files(
	"crafts.lua",
	"classes.lua"
)

local old_bounty_reward_func = ctf_modebase.bounties.bounty_reward_func
local old_get_next_bounty = ctf_modebase.bounties.get_next_bounty
local old_get_colored_skin = ctf_cosmetics.get_colored_skin
ctf_modebase.register_mode("classes", {
	treasures = {
		["default:ladder_wood" ] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:torch"       ] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:cobble"      ] = {min_count = 45, max_count = 99, rarity = 0.4, max_stacks = 5},
		["default:wood"        ] = {min_count = 10, max_count = 60, rarity = 0.5, max_stacks = 4},

		["ctf_teams:door_steel"] = {rarity = 0.2, max_stacks = 3},

		["default:pick_steel"  ] = {rarity = 0.4, max_stacks = 3},
		["default:shovel_steel"] = {rarity = 0.4, max_stacks = 2},
		["default:axe_steel"   ] = {rarity = 0.4, max_stacks = 2},

		["ctf_ranged:pistol_loaded" ] = {rarity = 0.2 , max_stacks = 2},
		["ctf_ranged:shotgun_loaded"] = {rarity = 0.05                },
		["ctf_ranged:smg_loaded"    ] = {rarity = 0.05                },

		["ctf_ranged:ammo"    ] = {min_count = 3, max_count = 10, rarity = 0.3  , max_stacks = 2},
		["ctf_healing:medkit" ] = {                               rarity = 0.08 , max_stacks = 2},

		["grenades:frag" ] = {rarity = 0.1, max_stacks = 1},
		["grenades:smoke"] = {rarity = 0.2, max_stacks = 2},
	},
	crafts = crafts,
	physics = {sneak_glitch = true, new_move = false},
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
	build_timer = 60 * 1.5,

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
	is_restricted_item = classes.is_restricted_item,
	on_mode_start = function()
		ctf_modebase.bounties.bounty_reward_func = ctf_modebase.bounty_algo.kd.bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = ctf_modebase.bounty_algo.kd.get_next_bounty

		ctf_cosmetics.get_colored_skin = function(player, color)
			return old_get_colored_skin(player, color) .. "^ctf_mode_classes_" .. classes.get_name(player) .. "_overlay.png"
		end
	end,
	on_mode_end = function()
		ctf_modebase.bounties.bounty_reward_func = old_bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = old_get_next_bounty
		ctf_cosmetics.get_colored_skin = old_get_colored_skin

		classes.finish()
	end,
	on_new_match = features.on_new_match,
	on_match_end = features.on_match_end,
	team_allocator = features.team_allocator,
	on_allocplayer = function(player, new_team)
		classes.update(player)
		features.on_allocplayer(player, new_team)
	end,
	on_leaveplayer = features.on_leaveplayer,
	on_dieplayer = features.on_dieplayer,
	on_respawnplayer = features.on_respawnplayer,
	can_take_flag = features.can_take_flag,
	on_flag_take = features.on_flag_take,
	on_flag_drop = features.on_flag_drop,
	on_flag_capture = features.on_flag_capture,
	on_flag_rightclick = function(clicker)
		classes.show_class_formspec(clicker)
	end,
	get_chest_access = features.get_chest_access,
	on_punchplayer = features.on_punchplayer,
	on_healplayer = features.on_healplayer,
	calculate_knockback = function()
		return 0
	end,
})
