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

wrap_callback("shooter_hook:grapple_gun", "on_use", function(old, itemstack, user, pointed_thing)
	if pointed_thing.type == "object" then
		pointed_thing.ref:punch(user, 1.0, { full_punch_interval=1.0 }, nil)
		return user:get_wielded_item()
	end

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

shooter.blast = function(pos, radius, fleshy, distance, user, groups)
	if not user then
		return
	end

	groups = groups or { "flesy" }

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

			if dist ~= 0 then
				obj_pos.y = obj_pos.y + 1
				local blast_pos = {x=pos.x, y=pos.y + 4, z=pos.z}
				if shooter.is_valid_object(obj) and
						minetest.line_of_sight(obj_pos, blast_pos, 1) then

					-- PATCH
					local damage = (fleshy * 0.5 ^ dist) * 2 * config.damage_multiplier
					local damage_groups = {}
					for i=1, #groups do
						damage_groups[groups[i]] = damage
					end
					-- END PATCH

					shooter.punch_object(obj, {
						full_punch_interval = 1.0,
						damage_groups = damage_groups,
					}, nil, true, user)
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


minetest.registered_entities["shooter_hook:hook"].on_activate = function(self, staticdata)
	self.object:set_armor_groups({fleshy=0})
	if staticdata == "expired" then
		self.object:remove()
		return
	end
end

local function check_grapple(self, node, pos, above)
	local player = minetest.get_player_by_name(self.user)
	if not player then
		return
	end

	local counter = player:get_meta():get_int("death_counter")
	if self.counter ~= counter then
		return
	end

	-- Check for teleportation
	if minetest.get_item_group(node.name, "liquid") == 0 and
			minetest.get_node(pos).name == "air" and
			minetest.get_node(above).name == "air" then
		player:move_to(pos)
	else
		-- Failed to teleport, return to inventory
		self.itemstack = player:get_inventory():add_item("main", self.itemstack)
	end

	-- Drop remaining stack
	if not self.itemstack:is_empty() and minetest.get_item_group(node.name, "lava") == 0 then
		minetest.add_item(pos, self.itemstack)
	end
end

minetest.registered_entities["shooter_hook:hook"].on_step = function(self, dtime)
	if not self.user then
		return
	end

	if not self.counter then
		local player = minetest.get_player_by_name(self.user)
		if player then
			self.counter = player:get_meta():get_int("death_counter")
		else
			self.object:remove()
			return
		end
	end

	self.timer = self.timer + dtime
	if self.timer > 0.25 then
		local pos = self.object:get_pos()
		if minetest.get_node(pos).name ~= "air" then
			pos.y = pos.y + 1
		end

		local below = {x=pos.x, y=pos.y - 1, z=pos.z}
		local above = {x=pos.x, y=pos.y + 1, z=pos.z}
		local node = minetest.get_node(below)
		if node.name ~= "air" then
			self.object:set_velocity({x=0, y=-10, z=0})
			self.object:set_acceleration({x=0, y=0, z=0})

			check_grapple(self, node, pos, above)

			self.object:remove()
		end
		self.timer = 0
	end
end

minetest.register_on_dieplayer(function(player)
	local meta = player:get_meta()

	local counter = meta:get_int("death_counter")
	meta:set_int("death_counter", counter + 1)
end)


minetest.registered_entities["shooter_rocket:rocket_entity"].on_step = function(self, dtime)
	self.timer = self.timer + dtime
	if self.timer > 0.2 then
		local pos = self.object:get_pos()
		local above = {x=pos.x, y=pos.y + 1, z=pos.z}
		if minetest.get_node(pos).name ~= "air" then
			if self.user then
				local player = minetest.get_player_by_name(self.user)
				if player then
					shooter.blast(above, 4, 25, 8, player, { "fleshy", "rocket" })
				end
			end
			self.object:remove()
		end
		self.timer = 0
	end
end

minetest.registered_entities["shooter_grenade:grenade_entity"].on_step = function(self, dtime)
	self.timer = self.timer + dtime
	if self.timer > 0.2 then
		local pos = self.object:get_pos()
		local above = {x=pos.x, y=pos.y + 1, z=pos.z}
		if minetest.get_node(pos).name ~= "air" then
			if self.user then
				local player = minetest.get_player_by_name(self.user)
				if player then
					shooter.blast(above, 2, 30, 5, player, { "fleshy", "grenade" })
				end
			end
			self.object:remove()
		end
		self.timer = 0
	end
end
