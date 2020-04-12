-- Basic 7.62mm rifle
shooter:register_weapon("sniper_rifles:rifle_762", {
	description = "Sniper rifle (7.62mm)",
	inventory_image = "sniper_rifles_rifle_762.png",
	rounds = 30,
	fov_mult = 4,
	spec = {
		range     = 300,
		step      = 30,
		tool_caps = { full_punch_interval = 1.5, damage_groups = { fleshy = 12 } },
		sound     = { name = "sniper_rifles_rifle", gain = 0.8 },
		particle  = "shooter_bullet.png",
		groups    = {
			cracky = 3, snappy = 2, crumbly = 2, choppy = 2,
			fleshy = 1, oddly_breakable_by_hand = 1
		}
	}
})

-- Magnum rifle
shooter:register_weapon("sniper_rifles:rifle_magnum", {
	description = "Sniper rifle (Magnum)",
	inventory_image = "sniper_rifles_rifle_magnum.png",
	rounds = 20,
	fov_mult = 8,
	spec = {
		range     = 400,
		step      = 30,
		tool_caps = { full_punch_interval = 2, damage_groups = { fleshy = 16 } },
		sound     = { name = "sniper_rifles_rifle", gain = 0.8 },
		particle  = "shooter_bullet.png",
		groups    = {
			cracky = 2, snappy = 1, crumbly = 1, choppy = 1,
			fleshy = 1, oddly_breakable_by_hand = 1
		}
	}
})
