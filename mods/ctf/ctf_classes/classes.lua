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
			"shooter:pistol",
			"shooter:smg",
			"shooter:shotgun",
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
			"shooter:rifle",
			"shooter:grapple_gun_loaded",
		},

		additional_item_blacklist = {
			"shooter:grapple_gun",
			"shooter:grapple_hook",
		},

		allowed_guns = {
			"shooter:pistol",
			"shooter:rifle",
			"shooter:smg",
			"shooter:shotgun",
		},

		shooter_multipliers = {
			range = 1.5,
			full_punch_interval = 0.8,
		},
	},
})

ctf_classes.register("medic", {
	description = "Medic",
	pros = { "x2 regen for nearby friendlies" },
	cons = {},
	color = "#0af",
	properties = {
		nearby_hpregen = true,

		initial_stuff = {
			"ctf_bandages:bandage 20",
		},

		allowed_guns = {
			"shooter:pistol",
			"shooter:smg",
			"shooter:shotgun",
		},
	},
})

ctf_classes.register("rocketeer", {
	description = "Rocketeer",
	pros = { "Can craft rockets" },
	cons = {},
	color = "#fa0",
	properties = {
		initial_stuff = {
			"shooter:rocket_gun_loaded",
			"shooter:rocket 4",
		},

		additional_item_blacklist = {
			"shooter:rocket_gun",
		},

		allowed_guns = {
			"shooter:pistol",
			"shooter:smg",
			"shooter:shotgun",
		},
	},
})
