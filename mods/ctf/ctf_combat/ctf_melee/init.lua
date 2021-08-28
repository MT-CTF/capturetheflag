ctf_melee = {
	registered_swords = {},
}

local sword_mats = {
	stone = {
		description = minetest.registered_tools["default:sword_stone"].description,
		inventory_image = minetest.registered_tools["default:sword_stone"].inventory_image,
		damage_groups = {fleshy = 4},
		full_punch_interval = 1.0
	},
	steel = {
		description = minetest.registered_tools["default:sword_steel"].description,
		inventory_image = minetest.registered_tools["default:sword_steel"].inventory_image,
		damage_groups = {fleshy = 6},
		full_punch_interval = 0.8,
	},
	mese = {
		description = minetest.registered_tools["default:sword_mese"].description,
		inventory_image = minetest.registered_tools["default:sword_mese"].inventory_image,
		damage_groups = {fleshy = 7},
		full_punch_interval = 0.7,
	},
	diamond = {
		description = minetest.registered_tools["default:sword_diamond"].description,
		inventory_image = minetest.registered_tools["default:sword_diamond"].inventory_image,
		damage_groups = {fleshy = 8},
		full_punch_interval = 0.6,
	}
}

function ctf_melee.simple_register_sword(name, def)
	local base_def = {
		description = def.description,
		inventory_image = def.inventory_image,
		tool_capabilities = {
			full_punch_interval = def.full_punch_interval,
			max_drop_level=1,
			groupcaps={
				snappy={times={[1]=2.5, [2]=1.20, [3]=0.35}, uses=0, maxlevel=3},
			},
			damage_groups = def.damage_groups,
			punch_attack_uses = 0,
		},
		sound = {breaks = "default_tool_breaks"},
		groups = def.groups or {},
	}

	base_def.groups.sword = 1

	if def.rightclick_func then
		base_def.on_place = def.rightclick_func

		base_def.on_secondary_use = function(itemstack, user, pointed_thing, ...)
			if pointed_thing then
				def.rightclick_func(itemstack, user, pointed_thing, ...)
			end
		end
	end

	minetest.register_tool(name, base_def)
	ctf_melee.registered_swords[name] = base_def
end

for mat, def in pairs(sword_mats) do
	ctf_melee.simple_register_sword("ctf_melee:sword_"..mat, def)

	minetest.register_alias_force("default:sword_"..mat, "ctf_melee:sword_"..mat)
end
