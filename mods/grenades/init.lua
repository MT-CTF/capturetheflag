grenades = {}

local function throw_grenade(name, player)
	local dir = player:get_look_dir()
	local pos = player:get_pos()
	local obj = minetest.add_entity({x = pos.x + dir.x, y = pos.y + 1.6, z = pos.z + dir.z}, name)

	obj:set_velocity({x = dir.x * 40, y = dir.y * 40, z = dir.z * 40})
	obj:set_acceleration({x = dir.x * -12, y = -41, z = dir.z * -12})

	return(obj:get_luaentity())
end

function grenades.register_grenade(name, def)
	if not def.timeout then
		def.timeout = 5
	end

	local grenade_entity = {
		physical = false,
		collide_with_objects = true,
		timer = 0,
		visual = "sprite",
		visual_size = {x = 1, y = 1, z = 1},
		textures = {def.image},
		collisionbox = {1, 1, 1, 1, 1, 1},
		on_step = function(self, dtime)
			local obj = self.object
			local pos = obj:get_pos()
			local node = minetest.get_node(vector.add(pos, vector.normalize(obj:get_velocity())))

			if self.particle == nil then
				self.particle = 0
			end

			if self.timer then
				self.timer = self.timer + dtime
			else
				self.timer = dtime
			end

			if def.particle and self.particle >= 4 then
				self.particle = 0

				minetest.add_particle({
					pos = obj:get_pos(),
					velocity = vector.divide(obj:get_velocity(), 2),
					acceleration = vector.divide(obj:get_acceleration(), -5),
					expirationtime = def.particle.life,
					size = def.particle.size,
					collisiondetection = true,
					collision_removal = true,
					vertical = false,
					texture = def.particle.image,
					glow = def.particle.glow
				})
			elseif def.particle and self.particle < def.particle.interval then
				self.particle = self.particle + 1
			end

			if self.timer > def.timeout or node.name ~= "air" then
				minetest.log("[Grenades] A grenade thrown by "..self.thrower_name.." is exploding at "..minetest.pos_to_string(pos))
				def.on_explode(pos, self.thrower_name)

				obj:remove()
			end
		end
	}

	minetest.register_entity("grenades:grenade_"..name, grenade_entity)

	local newdef = {}

	newdef.description = def.description
	newdef.stack_max = 1
	newdef.range = 4
	newdef.inventory_image = def.image
	newdef.on_use = function(itemstack, user, pointed_thing)
		local player_name = user:get_player_name()

		if pointed_thing.type ~= "node" then
			local grenade = throw_grenade("grenades:grenade_"..name, user)
			grenade.timer = 0
			grenade.thrower_name = player_name

			if not minetest.settings:get_bool("creative_mode") then
				itemstack = ""
			end
		end

		return itemstack
	end

	if def.placeable == true then

		newdef.tiles = {def.image}
		newdef.selection_box = {
			type = "fixed",
			fixed = {-0.3, -0.5, -0.3, 0.3, 0.4, 0.3},
		}
		newdef.groups = {oddly_breakable_by_hand = 2}
		newdef.paramtype = "light"
		newdef.sunlight_propagates = true
		newdef.walkable = false
		newdef.drawtype = "plantlike"

		minetest.register_node("grenades:grenade_"..name, newdef)
	else
		minetest.register_craftitem("grenades:grenade_"..name, newdef)
	end
end

dofile(minetest.get_modpath("grenades").."/grenades.lua")
