minetest.register_entity("shooter:grenade_entity", {
	physical = false,
	timer = 0,
	visual = "cube",
	visual_size = {x=1/8, y=1/8},
	textures = {
		"shooter_grenade.png",
		"shooter_grenade.png",
		"shooter_grenade.png",
		"shooter_grenade.png",
		"shooter_grenade.png",
		"shooter_grenade.png",
	},
	player = nil,
	player_name = nil,
	collisionbox = {0,0,0, 0,0,0},
	on_activate = function(self, staticdata)
		if staticdata == "expired" then
			self.object:remove()
		end
	end,
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer > 0.1 then
			local pos = self.object:getpos()
			local above = {x=pos.x, y=pos.y + 1, z=pos.z}
			if minetest.get_node(pos).name ~= "air" then
				self.object:remove()
				shooter:blast(above, 2, 25, 5, self.player)
			end
			self.timer = 0
		end
	end,
	get_staticdata = function(self)
		return "expired"
	end,
})

minetest.register_tool("shooter:grenade", {
	description = "Grenade",
	inventory_image = "shooter_hand_grenade.png",
	on_use = function(itemstack, user, pointed_thing)
		if not minetest.settings:get_bool("creative_mode") then
			itemstack:take_item()
		end
		if pointed_thing.type ~= "nothing" then
			local pointed = minetest.get_pointed_thing_position(pointed_thing)
			if vector.distance(user:get_pos(), pointed) < 10 then
				shooter:blast(pointed, 2, 25, 5)
				return
			end
		end
		local pos = user:get_pos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_horizontal()
		if pos and dir then
			pos.y = pos.y + 1.5
			local obj = minetest.add_entity(pos, "shooter:grenade_entity")
			if obj then
				obj:set_velocity({x = dir.x * 20, y = dir.y * 20, z = dir.z * 20})
				obj:set_acceleration({x=dir.x * -3, y=-10, z=dir.z * -3})
				obj:set_yaw(yaw + math.pi)
				local ent = obj:get_luaentity()
				if ent then
					ent.player = ent.player or user
					ent.player_name = user:get_player_name()
				end
			end
		end
		return itemstack
	end,
})

if SHOOTER_ENABLE_CRAFTING == true then
	minetest.register_craft({
		output = "shooter:grenade",
		recipe = {
			{"tnt:gunpowder", "default:steel_ingot"},
		},
	})
end
