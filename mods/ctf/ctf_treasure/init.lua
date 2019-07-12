ctf_treasure = {}

function ctf_treasure.get_default_treasures()
	return {
		{"default:ladder",0.3,5,{1,20}},
		{"default:torch",0.3,5,{1,20}},
		{"default:cobble",0.4,5,{45,99}},
		{"default:wood",0.3,5,{30,60}},
		{"doors:door_steel",0.3,5,{1,3}},

		{"default:pick_steel",0.5,5,{1,10}},
		{"default:sword_stone",0.6,5,{1,10}},
		{"default:sword_steel",0.4,5,{1,4}},
		{"default:shovel_stone",0.6,5,{1,10}},
		{"default:shovel_steel",0.3,5,{1,10}},

		{"shooter:crossbow",0.5,2,{1,5}},
		{"shooter:pistol",0.4,2,{1,5}},
		{"shooter:rifle",0.1,2,{1,2}},
		{"shooter:shotgun",0.04,2,1},
		{"shooter:grenade",0.08,2,1},
		{"shooter:machine_gun",0.02,2,1},
		{"shooter:ammo",0.3,2,{1,10}},
		{"shooter:arrow_white",0.5,2,{2,18}},

		{"ctf_bandages:bandage",0.8,2,{2,4}},
		{"medkits:medkit",0.8,5,2}
	}
end
