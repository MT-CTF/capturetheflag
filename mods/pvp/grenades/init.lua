grenades = {
	grenade_deaccel = 9
}

function grenades.throw_grenade(name, startspeed, player)
	local dir = player:get_look_dir()
	local pos = player:get_pos()
	local obj = minetest.add_entity({x = pos.x + dir.x, y = pos.y + 1.5 + dir.y, z = pos.z + dir.z}, name)

	obj:set_velocity(vector.multiply(dir, startspeed))
	obj:set_acceleration({x = 0, y = -9.8, z = 0})

	obj:get_luaentity().thrower_name = player:get_player_name()

	return obj:get_luaentity()
end

function grenades.register_grenade(name, def)
	if not def.clock then
		def.clock = 4
	end

	local grenade_entity = {
		initial_properties = {
			physical = true,
			collide_with_objects = false,
			visual = "sprite",
			visual_size = {x = 0.5, y = 0.5, z = 0.5},
			textures = {def.image},
			collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.15, 0.2},
			pointable = false,
			static_save = false,
		},
		sliding = 1,
		particle = 0,
		timer = 0,
		on_step = function(self, dtime)
			local obj = self.object
			local vel = obj:get_velocity()
			local pos = obj:get_pos()
			local norm_vel -- Normalized velocity

			self.timer = self.timer + dtime

			if not self.last_vel then
				self.last_vel = vel
			end

			-- Check for a collision on the x/y/z axis

			if not vector.equals(self.last_vel, vel) and vector.distance(self.last_vel, vel) > 4 then
				if def.on_collide and def.on_collide(obj, self.thrower_name) then
					if self.thrower_name then
						minetest.log("action", "[Grenades] A grenade thrown by " .. self.thrower_name ..
						" explodes at " .. minetest.pos_to_string(vector.round(pos)))
						def.on_explode(pos, self.thrower_name)
					end

					obj:remove()
				end

				if math.abs(self.last_vel.x - vel.x) > 5 then -- Check for a large reduction in velocity
					vel.x = self.last_vel.x * -0.3 -- Invert velocity and reduce it a bit
				end

				if math.abs(self.last_vel.y - vel.y) > 5 then -- Check for a large reduction in velocity
					vel.y = self.last_vel.y * -0.2 -- Invert velocity and reduce it a bit
				end

				if math.abs(self.last_vel.z - vel.z) > 5 then -- Check for a large reduction in velocity
					vel.z = self.last_vel.z * -0.3 -- Invert velocity and reduce it a bit
				end

				obj:set_velocity(vel)
			end

			self.last_vel = vel

			if self.sliding == 1 and vel.y == 0 then -- Check if grenade is sliding
				self.sliding = 2 -- Multiplies drag by 2
			elseif self.sliding > 1 and vel.y ~= 0 then
				self.sliding = 1 -- Doesn't affect drag
			end

			if self.sliding > 1 then -- Is the grenade sliding?
				if vector.distance(vector.new(), vel) <= 1 and not vector.equals(vel, vector.new()) then -- Grenade is barely moving, make sure it stays that way
					obj:set_velocity(vector.new())
					obj:set_acceleration(vector.new(0, -9.8, 0))
				end
			else
				norm_vel = vector.normalize(vel)

				obj:set_acceleration({
					x = -norm_vel.x * grenades.grenade_deaccel * self.sliding,
					y = -9.8,
					z = -norm_vel.z * grenades.grenade_deaccel * self.sliding,
				})
			end


			-- Grenade Particles

			if def.particle and self.particle >= def.particle.interval then
				self.particle = 0

				minetest.add_particle({
					pos = obj:get_pos(),
					velocity = vector.divide(vel, 2),
					acceleration = vector.divide(obj:get_acceleration() or vector.new(1, 1, 1), -5),
					expirationtime = def.particle.life,
					size = def.particle.size,
					collisiondetection = false,
					collision_removal = false,
					vertical = false,
					texture = def.particle.image,
					glow = def.particle.glow
				})
			elseif def.particle and self.particle < def.particle.interval then
				self.particle = self.particle + dtime
			end

			-- Explode when clock is up

			if self.timer > def.clock or not self.thrower_name then
				if self.thrower_name then
					minetest.log("action", "[Grenades] A grenade thrown by " .. self.thrower_name ..
					" explodes at " .. minetest.pos_to_string(vector.round(pos)))
					def.on_explode(pos, self.thrower_name)
				end

				obj:remove()
			end
		end
	}

	minetest.register_entity(name, grenade_entity)

	local newdef = {}

	newdef.description = def.description
	newdef.stack_max = 1
	newdef.range = 0
	newdef.inventory_image = def.image
	newdef.on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			grenades.throw_grenade(name, 20, user)

			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item(1)
			end
		end

		return itemstack
	end

	minetest.register_craftitem(name, newdef)
end

dofile(minetest.get_modpath("grenades") .. "/grenades.lua")
