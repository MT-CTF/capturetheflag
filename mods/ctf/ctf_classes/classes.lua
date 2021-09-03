ctf_classes.default_class = "knight"

ctf_classes.register("knight", {
	description = "Knight",
	pros = { "Skilled with swords", "+50% health points" },
	cons = { "-10% speed" },
	color = "#ccc",
	properties = {
		max_hp = 30,
		speed = 0.90,
		melee_bonus = 1,

		initial_stuff = {
			"ctf_classes:sword_bronze",
		},

		allowed_guns = {
			"shooter_guns:pistol",
			"shooter_guns:shotgun",
		},
	},
})

ctf_classes.register("shooter", {
	description = "Sharp Shooter",
	pros = { "Skilled with ranged weapons", "Can craft and use sniper rifles"},
	cons = {"-25% health points"},
	color = "#c60",
	properties = {
		allow_grapples = true,
		max_hp = 16,

		initial_stuff = {
			"shooter_guns:rifle_loaded",
			"shooter_hook:grapple_gun_loaded",
			"shooter:ammo 2"
		},

		item_blacklist = {
			"shooter_guns:rifle_loaded",
			"shooter_hook:grapple_gun_loaded",
		},

		additional_item_blacklist = {
			"shooter_hook:grapple_gun",
			"shooter_hook:grapple_hook",
			"shooter_guns:rifle",
		},

		allowed_guns = {
			"shooter_guns:pistol",
			"shooter_guns:rifle",
			"shooter_guns:machine_gun",
			"shooter_guns:shotgun",
			"sniper_rifles:rifle_762",
			"sniper_rifles:rifle_magnum"
		},

		crafting = {
			"sniper_rifles:rifle_762",
			"sniper_rifles:rifle_magnum"
		},

		shooter_multipliers = {
			range = 1.5,
			tool_caps = {
				full_punch_interval = 0.8,
			},
		},
	},
})

ctf_classes.register("medic", {
	description = "Medic",
	pros = { "Building supplies + Paxel", "x2 regen for nearby teammates", "+10% speed" },
	cons = {},
	color = "#0af",
	properties = {
		nearby_hpregen = true,
		speed = 1.1,

		initial_stuff = {
			"ctf_bandages:bandage",
			"ctf_classes:paxel_bronze",
			"default:cobble 99"
		},

		item_whitelist = {
			"default:cobble"
		},

		allowed_guns = {
			"shooter_guns:pistol",
		},

		crafting = {
			"default:axe_mese",
			"default:axe_diamond",
			"default:shovel_mese",
			"default:shovel_diamond",
		}
	},
})

--[[
ctf_classes.register("sniper", {
	description = "Sniper",
	pros = { "+25% range", "+25% faster shooting" },
	cons = {"-50% health points"},
	color = "#96a",
	properties = {
		-- Disallow snipers from capturing flags - they're intended to be support
		can_capture = false,
		max_hp = 10,

		initial_stuff = {
			"sniper_rifles:rifle_762_loaded",
			"grenades:smoke 2",
			"shooter:ammo 3"
		},

		item_blacklist = {
			"sniper_rifles:rifle_762_loaded",
			"shooter_grenade:grenade",
		},

		additional_item_blacklist = {
			"sniper_rifles:rifle_762",
			"sniper_rifles:rifle_magnum",
			"sniper_rifles:rifle_magnum_loaded",
		},

		allowed_guns = {
			"shooter_guns:pistol",
			"shooter_guns:machine_gun",
			"sniper_rifles:rifle_762",
			"sniper_rifles:rifle_magnum"
		},

		crafting = {
			"sniper_rifles:rifle_762",
			"sniper_rifles:rifle_magnum"
		},

		shooter_multipliers = {
			range = 1.25,
			tool_caps = {
				full_punch_interval = 0.75,
			},
		},
	}
})
]]--

--[[ctf_classes.register("rocketeer", {
	description = "Rocketeer",
	pros = { "Can craft rockets" },
	cons = {},
	color = "#fa0",
	properties = {
		initial_stuff = {
			"shooter_rocket:rocket_gun_loaded",
			"shooter_rocket:rocket 4",
		},

		additional_item_blacklist = {
			"shooter_rocket:rocket_gun",
		},

		allowed_guns = {
			"shooter_guns:pistol",
			"shooter_guns:machine_gun",
			"shooter_guns:shotgun",
		},

		crafting = {
			"shooter_rocket:rocket"
		},
	},
})]]
