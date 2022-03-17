local COOLDOWN = ctf_core.init_cooldowns()

local DISALLOW_MOD_ABMS = {"default", "fire", "flowers", "tnt"}

local disabled_ores = {
	["default:stone_with_copper"] = "default:stone"          ,
	["default:stone_with_gold"  ] = "default:stone"          ,
	["default:stone_with_tin"   ] = "default:stone_with_iron",
}

for from, to in pairs(disabled_ores) do
	minetest.register_alias_force(from, to)
end

minetest.register_on_mods_loaded(function()

	-- Remove Unneeded ABMs

	local remove_list = {}

	for key, abm in pairs(minetest.registered_abms) do
		for _, mod in pairs(DISALLOW_MOD_ABMS) do
			if abm.mod_origin == mod then
				table.insert(remove_list, key)
				break
			end
		end
	end

	local removed = 0
	for _, key in pairs(remove_list) do
		table.remove(minetest.registered_abms, key - removed)
		removed = removed + 1
	end

	-- Unset falling group for all nodes

	for name, def in pairs(minetest.registered_nodes) do
		if def.groups then
			def.groups.falling_node = nil
			minetest.override_item(name, {groups = def.groups})
		end

		if name:find("fire:") and def.on_timer then
			def.on_timer = nil
		end
	end

	-- Set item type and tiers for give_initial_stuff
	local tiers = {"wood", "stone", "steel", "mese", "diamond"}
	local tool_categories = {"pickaxe", "shovel", "axe"}
	local other_categories = {sword = "melee"}
	for name, def in pairs(minetest.registered_tools) do
		local new_category = nil

		for _, tcat in pairs(tool_categories) do
			if def.groups[tcat] then
				new_category = tcat
				def.groups.tool = 1
				break
			end
		end

		for group, ocat in pairs(other_categories) do
			if def.groups[group] then
				new_category = ocat
				break
			end
		end

		if def.groups.tool or def.groups.sword then
			for tier, needle in pairs(tiers) do
				if name:match(needle) then
					def.groups.tier = tier

					if tier <= 2 then
						def.tool_capabilities.full_punch_interval = 1
						def.tool_capabilities.damage_groups.fleshy = def.tool_capabilities.damage_groups.fleshy + 1
					end

					break
				end
			end
		end

		minetest.override_item(name, {
			groups = def.groups,
			_g_category = new_category,
			tool_capabilities = def.tool_capabilities,
		})
	end

	local drop_self = {
		"default:leaves", "default:jungleleaves", "default:acacia_leaves",
		"default:aspen_leaves", "default:bush_leaves", "default:blueberry_bush_leaves",
		"default:acacia_bush_leaves"
	}

	for _, name in pairs(drop_self) do
		minetest.override_item(name, {drop = name})
	end
end)

minetest.override_item("default:apple", {
	on_use = function(itemstack, user, ...)
		if not COOLDOWN:get(user) then
			COOLDOWN:set(user, 0.3)

			return minetest.item_eat(3)(itemstack, user, ...)
		end
	end,
	after_place_node = function(pos, placer, itemstack)
		return nil
	end,
	on_place = function()
		return nil
	end
})

local function furnace_on_destruct(pos)
	local inv = minetest.get_inventory({ type = "node", pos = pos })
	if not inv then return end
	for _, list in pairs(inv:get_lists()) do
		for _, item in ipairs(list) do
			minetest.add_item(pos, item)
		end
	end
end

minetest.override_item("default:furnace", {
	can_dig = function() return true end,
	on_destruct = furnace_on_destruct,
})

minetest.override_item("default:furnace_active", {
	can_dig = function() return true end,
	on_destruct = furnace_on_destruct,
})
