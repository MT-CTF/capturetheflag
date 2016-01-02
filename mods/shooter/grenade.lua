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
	collisionbox = {0,0,0, 0,0,0},
	on_activate = function(self, staticdata)
		if staticdata == "expired" then
			self.object:remove()
		end
	end,
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer > 0.2 then
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
		if not minetest.setting_getbool("creative_mode") then
			itemstack = ""
		end
		if pointed_thing.type ~= "nothing" then
			local pointed = minetest.get_pointed_thing_position(pointed_thing)
			if vector.distance(user:getpos(), pointed) < 8 then
				shooter:blast(pointed, 1, 25, 5)
				return
			end
		end
		local pos = user:getpos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_yaw()
		if pos and dir then
			pos.y = pos.y + 1.5
			local obj = minetest.add_entity(pos, "shooter:grenade_entity")
			if obj then
				obj:setvelocity({x=dir.x * 15, y=dir.y * 15, z=dir.z * 15})
				obj:setacceleration({x=dir.x * -3, y=-10, z=dir.z * -3})
				obj:setyaw(yaw + math.pi)
				local ent = obj:get_luaentity()
				if ent then
					ent.player = ent.player or user
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

