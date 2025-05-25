ctf_melee = {
	registered_swords = {},
}

local sword_mats = {
	stone = {
		description = core.registered_tools["default:sword_stone"].description,
		inventory_image = core.registered_tools["default:sword_stone"].inventory_image,
		damage_groups = {fleshy = 4},
		full_punch_interval = 1.0
	},
	steel = {
		description = core.registered_tools["default:sword_steel"].description,
		inventory_image = core.registered_tools["default:sword_steel"].inventory_image,
		damage_groups = {fleshy = 6},
		full_punch_interval = 0.8,
	},
	mese = {
		description = core.registered_tools["default:sword_mese"].description,
		inventory_image = core.registered_tools["default:sword_mese"].inventory_image,
		damage_groups = {fleshy = 7},
		full_punch_interval = 0.7,
	},
	diamond = {
		description = core.registered_tools["default:sword_diamond"].description,
		inventory_image = core.registered_tools["default:sword_diamond"].inventory_image,
		damage_groups = {fleshy = 8},
		full_punch_interval = 0.6,
	}
}

function ctf_melee.simple_register_sword(name, def)
	local base_def = {
		description = def.description,
		inventory_image = def.inventory_image,
		inventory_overlay = def.inventory_overlay,
		wield_image = def.wield_image,
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
		base_def.on_place = function(itemstack, user, pointed, ...)
			local pointed_def = false
			local node

			if pointed and pointed.under then
				node = core.get_node(pointed.under)
				pointed_def = core.registered_nodes[node.name]
			end

			if pointed_def and pointed_def.on_rightclick then
				return core.item_place(itemstack, user, pointed)
			else
				return def.rightclick_func(itemstack, user, pointed, ...)
			end
		end

		base_def.on_secondary_use = def.rightclick_func
	end

	core.register_tool(name, base_def)
	ctf_melee.registered_swords[name] = base_def
end

for mat, def in pairs(sword_mats) do
	ctf_melee.simple_register_sword("ctf_melee:sword_"..mat, def)

	core.register_alias_force("default:sword_"..mat, "ctf_melee:sword_"..mat)
end
