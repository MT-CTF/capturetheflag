ctf_classes.default_class = "knight"

ctf_classes.register("knight", {
	description = "Knight",
	pros = { "+50% Health Points" },
	cons = { "-10% speed" },
	color = "#ccc",
	properties = {
		max_hp = 30,
		speed = 0.90,

		initial_stuff = {
			"default:sword_steel",
		},

		allowed_guns = {
			"shooter_guns:pistol",
			"shooter_guns:machine_gun",
			"shooter_guns:shotgun",
		},
	},
})

ctf_classes.register("shooter", {
	description = "Sharp Shooter",
	pros = { "+50% range", "+20% faster shooting" },
	cons = {},
	color = "#c60",
	properties = {
		allow_grapples = true,

		initial_stuff = {
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
	pros = { "x2 regen for nearby friendlies", "+10% speed" },
	cons = {},
	color = "#0af",
	properties = {
		nearby_hpregen = true,
		speed = 1.1,

		initial_stuff = {
			"ctf_bandages:bandage 50",
		},

		allowed_guns = {
			"shooter_guns:pistol",
			"shooter_guns:machine_gun",
			"shooter_guns:shotgun",
		},
	},
})

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
