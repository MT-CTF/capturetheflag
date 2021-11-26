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
	local other_categories = {sword = "melee", ranged = "ranged", healing = "healing"}
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
					break
				end
			end
		end

		minetest.override_item(name, {groups = def.groups, _g_category = new_category})
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
