local function wrap_callback(name, callback, func)
	assert(type(name) == "string")
	assert(type(callback) == "string")

	local old_callback = minetest.registered_items[name][callback]
	assert(old_callback)

	local overrides = {}
	overrides[callback] = function(...)
		return func(old_callback, ...)
	end

	minetest.override_item(name, overrides)
end

wrap_callback("shooter_hook:grapple_hook", "on_use", function(old, itemstack, ...)
	itemstack:add_wear(65536 / 16)
	return old(itemstack, ...)
end)

wrap_callback("shooter_hook:grapple_gun_loaded", "on_use", function(old, itemstack, ...)
	itemstack:add_wear(65536 / 8)
	return old(itemstack, ...)
end)

wrap_callback("shooter_hook:grapple_gun", "on_use", function(old, itemstack, user)
	local inv = user:get_inventory()
	if inv:contains_item("main", "shooter_hook:grapple_hook") then
		minetest.sound_play("shooter_reload", {object=user})
		local stack = inv:remove_item("main", "shooter_hook:grapple_hook")
		itemstack = "shooter_hook:grapple_gun_loaded 1 "..stack:get_wear()
	else
		minetest.sound_play("shooter_click", {object=user})
	end
	return itemstack
end)


local config = shooter.config
local v3d = vector

shooter.blast = function(pos, radius, fleshy, distance, user)
	if not user then
		return
	end
	pos = v3d.round(pos)
	local name = user:get_player_name()
	local p1 = v3d.subtract(pos, radius)
	local p2 = v3d.add(pos, radius)
	minetest.sound_play("shooter_explode", {
		pos = pos,
		gain = 10,
		max_hear_distance = 100
	})
	if config.allow_nodes and config.enable_blasting then
		if not config.enable_protection or
				not minetest.is_protected(pos, name) then
			minetest.set_node(pos, {name="shooter:boom"})
		end
	end
	if config.enable_particle_fx == true then
		minetest.add_particlespawner({
			amount = 50,
			time = 0.1,
			minpos = p1,
			maxpos = p2,
			minvel = {x=0, y=0, z=0},
			maxvel = {x=0, y=0, z=0},
			minacc = {x=-0.5, y=5, z=-0.5},
			maxacc = {x=0.5, y=5, z=0.5},
			minexptime = 0.1,
			maxexptime = 1,
			minsize = 8,
			maxsize = 15,
			collisiondetection = false,
			texture = "shooter_smoke.png",
		})
	end
	local objects = minetest.get_objects_inside_radius(pos, distance)
	for _,obj in ipairs(objects) do
		if shooter.is_valid_object(obj) then
			local obj_pos = obj:get_pos()
			local dist = v3d.distance(obj_pos, pos)

			-- PATCH
			local damage = fleshy * (0.707106 ^ dist) * 3
			-- END PATCH

			if dist ~= 0 then
				obj_pos.y = obj_pos.y + 1
				local blast_pos = {x=pos.x, y=pos.y + 4, z=pos.z}
				if shooter.is_valid_object(obj) and
						minetest.line_of_sight(obj_pos, blast_pos, 1) then
					shooter.punch_object(obj, {
						full_punch_interval = 1.0,
						damage_groups = {fleshy=damage},
					}, nil, true)
				end
			end
		end
	end
	if config.allow_nodes and config.enable_blasting then
		local pr = PseudoRandom(os.time())
		local vm = VoxelManip()
		local min, max = vm:read_from_map(p1, p2)
		local area = VoxelArea:new({MinEdge=min, MaxEdge=max})
		local data = vm:get_data()
		local c_air = minetest.get_content_id("air")
		for z = -radius, radius do
			for y = -radius, radius do
				local vp = {x=pos.x - radius, y=pos.y + y, z=pos.z + z}
				local vi = area:index(vp.x, vp.y, vp.z)
				for x = -radius, radius do
					if (x * x) + (y * y) + (z * z) <=
							(radius * radius) + pr:next(-radius, radius) then
						if config.enable_protection then
							if not minetest.is_protected(vp, name) then
								data[vi] = c_air
							end
						else
							data[vi] = c_air
						end
					end
					vi = vi + 1
				end
			end
		end
		vm:set_data(data)
		vm:update_liquids()
		vm:write_to_map()
	end
end


minetest.registered_entities["shooter_crossbow:arrow_entity"].collide_with_objects = false
