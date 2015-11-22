minetest.register_craftitem("shooter:flare", {
	description = "Flare",
	inventory_image = "shooter_flare_inv.png",
})

minetest.register_node("shooter:flare_light", {
	drawtype = "glasslike",
	tiles = {"shooter_flare_light.png"},
	paramtype = "light",
	groups = {not_in_creative_inventory=1},
	drop = "",
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	light_source = LIGHT_MAX,
	pointable = false,
})

minetest.register_abm({
	nodenames = "shooter:flare_light",
	interval = 5,
	chance = 1,
	action = function(pos, node)
		local time = os.time()
		local meta = minetest.get_meta(pos)
		local init_time = meta:get_int("init_time") or 0
		if time > init_time + 30 then
			local id = meta:get_int("particle_id")
			if id then
				minetest.delete_particlespawner(id)
			end
			minetest.remove_node(pos)
		end
	end,
})

minetest.register_entity("shooter:flare_entity", {
	physical = true,
	timer = 0,
	visual = "cube",
	visual_size = {x=1/8, y=1/8},
	textures = {
		"shooter_flare.png",
		"shooter_flare.png",
		"shooter_flare.png",
		"shooter_flare.png",
		"shooter_flare.png",
		"shooter_flare.png",
	},
	player = nil,
	collisionbox = {-1/16,-1/16,-1/16, 1/16,1/16,1/16},
	on_activate = function(self, staticdata)
		if staticdata == "expired" then
			self.object:remove()
		end
	end,
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer > 0.2 then
			local pos = self.object:getpos()
			local below = {x=pos.x, y=pos.y - 1, z=pos.z}
			local node = minetest.get_node(below)
			if node.name ~= "air" then
				self.object:setvelocity({x=0, y=-10, z=0})
				self.object:setacceleration({x=0, y=0, z=0})
				if minetest.get_node(pos).name == "air" and
						node.name ~= "default:water_source" and
						node.name ~= "default:water_flowing" then
					minetest.place_node(pos, {name="shooter:flare_light"})
					local meta = minetest.get_meta(pos)
					meta:set_int("particle_id", id)
					meta:set_int("init_time", os.time())
					pos.y = pos.y - 0.1
					local id = minetest.add_particlespawner(
						1000, 30, pos, pos,
						{x=-1, y=1, z=-1}, {x=1, y=1, z=1},
						{x=2, y=-2, z=-2}, {x=2, y=-2, z=2},
						0.1, 0.75, 1, 8, false, "shooter_flare_particle.png"
					)
					local sound = minetest.sound_play("shooter_flare_burn", {
						object = self.player,
						loop = true,
					})
					minetest.after(30, function(sound)
						minetest.sound_stop(sound)
					end, sound)
				end
				self.object:remove()
			end
			self.timer = 0
		end
	end,
	get_staticdata = function(self)
		return "expired"
	end,
})

minetest.register_tool("shooter:flaregun", {
	description = "Flare Gun",
	inventory_image = "shooter_flaregun.png",
	on_use = function(itemstack, user, pointed_thing)
		local inv = user:get_inventory()
		if not inv:contains_item("main", "shooter:flare") then
			minetest.sound_play("shooter_click", {object=user})
			return itemstack
		end
		if not minetest.setting_getbool("creative_mode") then
			inv:remove_item("main", "shooter:flare 1")
			itemstack:add_wear(65535/100)
		end
		local pos = user:getpos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_yaw()
		if pos and dir and yaw then
			pos.y = pos.y + 1.5
			local obj = minetest.add_entity(pos, "shooter:flare_entity")
			if obj then
				minetest.sound_play("shooter_flare_fire", {object=obj})
				obj:setvelocity({x=dir.x * 16, y=dir.y * 16, z=dir.z * 16})
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
		output = "shooter:flare",
		recipe = {
			{"tnt:gunpowder", "wool:red"},
		},
	})
	minetest.register_craft({
		output = "shooter:flaregun",
		recipe = {
			{"wool:red", "wool:red", "wool:red"},
			{"", "", "default:steel_ingot"}
		},
	})
end

