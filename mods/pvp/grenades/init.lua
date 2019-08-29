grenades = {}

local function throw_grenade(name, player)
	local dir = player:get_look_dir()
	local pos = player:get_pos()
	local obj = minetest.add_entity({x = pos.x + dir.x, y = pos.y + 1.5, z = pos.z + dir.z}, name)
	local self = obj:get_luaentity()

	local m = 33
	obj:set_velocity({x = dir.x * m, y = dir.y * m, z = dir.z * m})
	obj:set_acceleration({x = 0, y = -30, z = 0})
	self.dir = dir

	return(obj:get_luaentity())
end

function grenades.register_grenade(name, def)
	if not def.clock then
		def.clock = 4
	end

	local grenade_entity = {
		physical = true,
		collide_with_objects = true,
		timer = 0,
		visual = "sprite",
		visual_size = {x = 0.5, y = 0.5, z = 0.5},
		textures = {def.image},
		collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.15, 0.2},
		pointable = false,
		static_save = false,
		particle = 0,
		on_step = function(self, dtime)
			local obj = self.object
			local vel = obj:get_velocity()
			local pos = obj:get_pos()

			self.timer = self.timer + dtime

			if not self.last_vel then
				self.last_vel = vel
			end

			-- Collision Check

			if not vector.equals(self.last_vel, vel) and vector.distance(self.last_vel, vel) > 4 then
				if math.abs(self.last_vel.z) - 5 > math.abs(vel.z) then
					self.last_vel.z = self.last_vel.z * -0.5
				end

				if math.abs(self.last_vel.x) - 5 > math.abs(vel.x) then
					self.last_vel.x = self.last_vel.x * -0.5
				end

				if math.abs(self.last_vel.y) - 5 > math.abs(vel.y) then
					self.last_vel.y = self.last_vel.y * -0.3
				end

				obj:set_velocity(self.last_vel)
				vel = obj:get_velocity()
			end

			-- Can't use set_acceleration() because the grenade will shoot backwards once the velocity reaches 0
			vel.x = vel.x / 1.04
			vel.z = vel.z / 1.04

			obj:set_velocity(vel)
			self.last_vel = vel

			-- Grenade Particles

			if def.particle and self.particle >= 4 then
				self.particle = 0

				minetest.add_particle({
					pos = obj:get_pos(),
					velocity = vector.divide(vel, 2),
					acceleration = vector.divide(obj:get_acceleration(), -5),
					expirationtime = def.particle.life,
					size = def.particle.size,
					collisiondetection = false,
					collision_removal = false,
					vertical = false,
					texture = def.particle.image,
					glow = def.particle.glow
				})
			elseif def.particle and self.particle < def.particle.interval then
				self.particle = self.particle + 1
			end

			-- Explode when clock is up

			if self.timer > def.clock or not self.thrower_name then
				if self.thrower_name then
					minetest.log("[Grenades] A grenade thrown by "..self.thrower_name..
					" is exploding at "..minetest.pos_to_string(vector.round(pos)))
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
		local player_name = user:get_player_name()

		if pointed_thing.type ~= "node" then
			local grenade = throw_grenade(name, user)
			grenade.timer = 0
			grenade.thrower_name = player_name

			if not minetest.settings:get_bool("creative_mode") then
				itemstack = ""
			end
		end

		return itemstack
	end

	minetest.register_craftitem(name, newdef)
end

dofile(minetest.get_modpath("grenades").."/grenades.lua")
