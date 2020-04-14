ctf_treasure = {}

function ctf_treasure.get_default_treasures()
	return {
		{ "default:ladder",          0.3, 5, {  1, 20 } },
		{ "default:torch",           0.3, 5, {  1, 20 } },
		{ "default:cobble",          0.4, 5, { 45, 99 } },
		{ "default:wood",            0.3, 5, { 30, 60 } },
		{ "doors:door_steel",        0.3, 5, {  1,  3 } },
		{ "ctf_traps:damage_cobble", 0.3, 4, { 10, 20 } },

		{ "default:pick_steel",   0.5, 5, { 1, 10 } },
		{ "default:shovel_stone", 0.6, 5, { 1, 10 } },
		{ "default:shovel_steel", 0.3, 5, { 1, 10 } },
		{ "default:axe_steel",    0.4, 5, { 1, 10 } },
		{ "default:axe_stone",    0.5, 5, { 1, 10 } },

		{ "shooter:shotgun",     0.04, 2, 1 },
		{ "shooter:grenade",     0.08, 2, 1 },
		{ "shooter:machine_gun", 0.02, 2, 1 },
		{ "shooter:crossbow",    0.5,  2, { 1,  5 } },
		{ "shooter:pistol",      0.4,  2, { 1,  5 } },

		{ "shooter:ammo",        0.3,  2, { 1, 10 } },
		{ "shooter:arrow_white", 0.5,  2, { 2, 18 } },

		{ "sniper_rifles:rifle_762",     0.1, 2, 1 },
		{ "sniper_rifles:rifle_magnum", 0.01, 2, 1 },

		{ "medkits:medkit",       0.8, 5, 2 },
	}
end
