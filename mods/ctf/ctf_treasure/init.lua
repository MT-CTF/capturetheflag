ctf_treasure = {}

function ctf_treasure.register_default_treasures()
	treasurer.register_treasure("default:ladder",0.3,5,{1,20})
	treasurer.register_treasure("default:torch",0.3,5,{1,20})
	treasurer.register_treasure("default:cobble",0.4,5,{45,99})
	treasurer.register_treasure("default:apple",0.3,5,{1,8})
	treasurer.register_treasure("default:wood",0.3,5,{30,60})
	treasurer.register_treasure("doors:door_steel",0.3,5,{1,3})

	treasurer.register_treasure("default:pick_steel",0.5,5,{1,10})
	treasurer.register_treasure("default:sword_stone",0.6,5,{1,10})
	treasurer.register_treasure("default:sword_steel",0.4,5,{1,4})
	treasurer.register_treasure("default:shovel_stone",0.6,5,{1,10})
	treasurer.register_treasure("default:shovel_steel",0.3,5,{1,10})

	treasurer.register_treasure("shooter:crossbow",0.5,2,{1,5})
	treasurer.register_treasure("shooter:pistol",0.4,2,{1,5})
	treasurer.register_treasure("shooter:rifle",0.1,2,{1,2})
	treasurer.register_treasure("shooter:shotgun",0.04,2,1)
	treasurer.register_treasure("shooter:grenade",0.08,2,1)
	treasurer.register_treasure("shooter:machine_gun",0.02,2,1)
	treasurer.register_treasure("shooter:ammo",0.3,2,{1,10})
	treasurer.register_treasure("shooter:arrow_white",0.5,2,{2,18})
end
