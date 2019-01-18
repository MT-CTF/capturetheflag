-- mods/default/functions.lua

--
-- Sounds
--

function default.node_sound_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "", gain = 1.0}
	table.dug = table.dug or
			{name = "default_dug_node", gain = 0.25}
	table.place = table.place or
			{name = "default_place_node_hard", gain = 1.0}
	return table
end

function default.node_sound_stone_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_hard_footstep", gain = 0.3}
	table.dug = table.dug or
			{name = "default_hard_footstep", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_dirt_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_dirt_footstep", gain = 0.4}
	table.dug = table.dug or
			{name = "default_dirt_footstep", gain = 1.0}
	table.place = table.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_sand_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_sand_footstep", gain = 0.12}
	table.dug = table.dug or
			{name = "default_sand_footstep", gain = 0.24}
	table.place = table.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_gravel_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_gravel_footstep", gain = 0.4}
	table.dug = table.dug or
			{name = "default_gravel_footstep", gain = 1.0}
	table.place = table.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_wood_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_wood_footstep", gain = 0.3}
	table.dug = table.dug or
			{name = "default_wood_footstep", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_leaves_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_grass_footstep", gain = 0.45}
	table.dug = table.dug or
			{name = "default_grass_footstep", gain = 0.7}
	table.place = table.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_glass_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_glass_footstep", gain = 0.3}
	table.dig = table.dig or
			{name = "default_glass_footstep", gain = 0.5}
	table.dug = table.dug or
			{name = "default_break_glass", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_metal_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_metal_footstep", gain = 0.4}
	table.dig = table.dig or
			{name = "default_dig_metal", gain = 0.5}
	table.dug = table.dug or
			{name = "default_dug_metal", gain = 0.5}
	table.place = table.place or
			{name = "default_place_node_metal", gain = 0.5}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_water_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_water_footstep", gain = 0.2}
	default.node_sound_defaults(table)
	return table
end

--
-- optimized helper to put all items in an inventory into a drops list
--

function default.get_inventory_drops(pos, inventory, drops)
	local inv = minetest.get_meta(pos):get_inventory()
	local n = #drops
	for i = 1, inv:get_size(inventory) do
		local stack = inv:get_stack(inventory, i)
		if stack:get_count() > 0 then
			drops[n+1] = stack:to_table()
			n = n + 1
		end
	end
end

--
-- dig upwards
--

function default.dig_up(pos, node, digger)
	if digger == nil then return end
	local np = {x = pos.x, y = pos.y + 1, z = pos.z}
	local nn = minetest.get_node(np)
	if nn.name == node.name then
		minetest.node_dig(np, nn, digger)
	end
end


--
-- Fence registration helper
--

function default.register_fence(name, def)
	minetest.register_craft({
		output = name .. " 4",
		recipe = {
			{ def.material, 'group:stick', def.material },
			{ def.material, 'group:stick', def.material },
		}
	})

	local fence_texture = "default_fence_overlay.png^" .. def.texture ..
			"^default_fence_overlay.png^[makealpha:255,126,126"
	-- Allow almost everything to be overridden
	local default_fields = {
		paramtype = "light",
		drawtype = "nodebox",
		node_box = {
			type = "connected",
			fixed = {{-1/8, -1/2, -1/8, 1/8, 1/2, 1/8}},
			-- connect_top =
			-- connect_bottom =
			connect_front = {{-1/16,3/16,-1/2,1/16,5/16,-1/8},
				{-1/16,-5/16,-1/2,1/16,-3/16,-1/8}},
			connect_left = {{-1/2,3/16,-1/16,-1/8,5/16,1/16},
				{-1/2,-5/16,-1/16,-1/8,-3/16,1/16}},
			connect_back = {{-1/16,3/16,1/8,1/16,5/16,1/2},
				{-1/16,-5/16,1/8,1/16,-3/16,1/2}},
			connect_right = {{1/8,3/16,-1/16,1/2,5/16,1/16},
				{1/8,-5/16,-1/16,1/2,-3/16,1/16}},
		},
		connects_to = {"group:fence", "group:wood", "group:tree"},
		inventory_image = fence_texture,
		wield_image = fence_texture,
		tiles = {def.texture},
		sunlight_propagates = true,
		is_ground_content = false,
		groups = {},
	}
	for k, v in pairs(default_fields) do
		if not def[k] then
			def[k] = v
		end
	end

	-- Always add to the fence group, even if no group provided
	def.groups.fence = 1

	def.texture = nil
	def.material = nil

	minetest.register_node(name, def)
end

--
-- Checks if specified volume intersects a protected volume
--

function default.intersects_protection(minp, maxp, player_name, interval)
	-- 'interval' is the largest allowed interval for the 3D lattice of checks

	-- Compute the optimal float step 'd' for each axis so that all corners and
	-- borders are checked. 'd' will be smaller or equal to 'interval'.
	-- Subtracting 1e-4 ensures that the max co-ordinate will be reached by the
	-- for loop (which might otherwise not be the case due to rounding errors).
	local d = {}
	for _, c in pairs({"x", "y", "z"}) do
		if maxp[c] > minp[c] then
			d[c] = (maxp[c] - minp[c]) / math.ceil((maxp[c] - minp[c]) / interval) - 1e-4
		elseif maxp[c] == minp[c] then
			d[c] = 1 -- Any value larger than 0 to avoid division by zero
		else -- maxp[c] < minp[c], print error and treat as protection intersected
			minetest.log("error", "maxp < minp in 'default.intersects_protection()'")
			return true
		end
	end

	for zf = minp.z, maxp.z, d.z do
		local z = math.floor(zf + 0.5)
		for yf = minp.y, maxp.y, d.y do
			local y = math.floor(yf + 0.5)
			for xf = minp.x, maxp.x, d.x do
				local x = math.floor(xf + 0.5)
				if minetest.is_protected({x = x, y = y, z = z}, player_name) then
					return true
				end
			end
		end
	end

	return false
end


--
-- NOTICE: This method is not an official part of the API yet!
-- This method may change in future.
--

function default.can_interact_with_node(player, pos)
	if player then
		if minetest.check_player_privs(player, "protection_bypass") then
			return true
		end
	else
		return false
	end

	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	if not owner or owner == "" or owner == player:get_player_name() then
		return true
	end

	-- is player wielding the right key?
	local item = player:get_wielded_item()
	if item:get_name() == "default:key" then
		local key_meta = item:get_meta()

		if key_meta:get_string("secret") == "" then
			local key_oldmeta = item:get_metadata()
			if key_oldmeta == "" or not minetest.parse_json(key_oldmeta) then
				return false
			end

			key_meta:set_string("secret", minetest.parse_json(key_oldmeta).secret)
			item:set_metadata("")
		end

		return meta:get_string("key_lock_secret") == key_meta:get_string("secret")
	end

	return false
end
