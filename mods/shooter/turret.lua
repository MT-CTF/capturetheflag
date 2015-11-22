local function get_turret_entity(pos)
	local entity = nil
	local objects = minetest.get_objects_inside_radius(pos, 1)
	for _, obj in ipairs(objects) do
		local ent = obj:get_luaentity()
		if ent then
			if ent.name == "shooter:turret_entity" then
				-- Remove duplicates
				if entity then
					obj:remove()
				else
					entity = ent
				end
			end
		end
	end
	return entity
end

minetest.register_entity("shooter:tnt_entity", {
	physical = false,
	timer = 0,
	visual = "cube",
	visual_size = {x=1/4, y=1/4},
	textures = {
		"tnt_top.png",
		"tnt_bottom.png",
		"tnt_side.png",
		"tnt_side.png",
		"tnt_side.png",
		"tnt_side.png",
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
			if minetest.get_node(pos).name ~= "air" then
				self.object:remove()
				shooter:blast(pos, 4, 80, 10, self.player)
			end
			self.timer = 0
		end
	end,
	get_staticdata = function(self)
		return "expired"
	end,	
})

minetest.register_entity("shooter:turret_entity", {
	physical = true,
	visual = "mesh",
	mesh = "shooter_turret.b3d",
	visual_size = {x=1, y=1},
	collisionbox = {-0.3, 0.5,-0.3, 0.3,1,0.3},
	textures = {
		"shooter_turret_uv.png",
	},
	timer = 0,
	player = nil,
	pitch = 40,
	yaw = 0,
	firing = false,
	on_activate = function(self, staticdata)
		self.pos = self.object:getpos()
		self.yaw = self.object:getyaw()
		if minetest.get_node(self.pos).name ~= "shooter:turret" then
			self.object:remove()
			return
		end
		self.object:set_animation({x=self.pitch, y=self.pitch}, 0)
		self.object:set_armor_groups({fleshy=0})
		-- Remove duplicates
		get_turret_entity(self.pos)
	end,
	on_rightclick = function(self, clicker)
		if self.player == nil then
			clicker:set_attach(self.object, "", {x=0,y=5,z=-8}, {x=0,y=0,z=0})
			self.player = clicker
		else
			self.player:set_detach()
			local yaw = self.yaw + math.pi / 2
			local dir = vector.normalize({
				x = math.cos(yaw),
				y = 0,
				z = math.sin(yaw),
			})
			local pos = vector.subtract(self.player:getpos(), dir)
			minetest.after(0.2, function(player)
				player:setpos(pos)
			end, self.player)
			self.player = nil
		end
	end,
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer < 0.1 then
			return
		end	
		if self.player then
			local pitch = self.pitch
			local yaw = self.object:getyaw()
			local ctrl = self.player:get_player_control()
			local step = 2
			if ctrl then
				if ctrl.sneak then
					step = 1
					if ctrl.jump then
						if self.firing == false then
							self:fire()
							self.firing = true
						end
					else
						self.firing = false
					end
				end
				if ctrl.down then
					pitch = pitch + 1 * step
				elseif ctrl.up then
					pitch = pitch - 1 * step
				end
				if ctrl.left then
					yaw = yaw + 0.025 * step
				elseif ctrl.right then
					yaw = yaw - 0.025 * step
				end
				if pitch < 0 then
					pitch = 0
				elseif pitch > 90 then 
					pitch = 90
				end
				if self.pitch ~= pitch then
					self.object:set_animation({x=pitch, y=pitch}, 0)
					self.pitch = pitch
				end
				if self.yaw ~= yaw then
					self.object:setyaw(yaw)
					self.yaw = yaw
				end
			end
		end
		self.timer = 0
	end,
	fire = function(self)
		local meta = minetest.get_meta(self.pos)
		local inv = meta:get_inventory()
		if not inv then
			return
		end
		if not inv:contains_item("main", "tnt:tnt") then
			minetest.sound_play("shooter_click", {object=self.object})
			return
		end
		minetest.sound_play("shooter_shotgun", {object=self.object})
		if not minetest.setting_getbool("creative_mode") then
			inv:remove_item("main", "tnt:tnt")
		end
		local pitch = math.rad(self.pitch - 40)
		local len = math.cos(pitch)
		local dir = vector.normalize({
			x = len * math.sin(-self.yaw),
			y = math.sin(pitch),
			z = len * math.cos(self.yaw),
		})
		local pos = {x=self.pos.x, y=self.pos.y + 0.87, z=self.pos.z}
		pos = vector.add(pos, {x=dir.x * 1.5, y=dir.y * 1.5, z=dir.z * 1.5})
		local obj = minetest.add_entity(pos, "shooter:tnt_entity")
		if obj then
			local ent = obj:get_luaentity()
			if ent then
				minetest.sound_play("shooter_rocket_fire", {object=obj})
				ent.player = self.player
				obj:setyaw(self.yaw)
				obj:setvelocity({x=dir.x * 20, y=dir.y * 20, z=dir.z * 20})
				obj:setacceleration({x=dir.x * -3, y=-10, z=dir.z * -3})
			end
		end
		if SHOOTER_ENABLE_PARTICLE_FX == true then
			minetest.add_particlespawner(10, 0.1,
				{x=pos.x - 1, y=pos.y - 1, z=pos.z - 1},
				{x=pos.x + 1, y=pos.y + 1, z=pos.z + 1},
				{x=0, y=0, z=0}, {x=0, y=0, z=0},
				{x=-0.5, y=-0.5, z=-0.5}, {x=0.5, y=0.5, z=0.5},
				0.1, 1, 8, 15, false, "tnt_smoke.png"
			)
		end
	end
})

minetest.register_node("shooter:turret", {
	description = "Turret Gun",
	tiles = {"shooter_turret_base.png"},
	inventory_image = "shooter_turret_gun.png",
	wield_image = "shooter_turret_gun.png",
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=3},
	node_box = {
		type = "fixed",
		fixed = {
			{-1/8, 1/8, -1/8, 1/8, 1/2, 1/8},
			{-5/16, 0, -5/16, 5/16, 1/8, 5/16},
			{-3/8, -1/2, -3/8, -1/4, 0, -1/4},
			{1/4, -1/2, 1/4, 3/8, 0, 3/8},
			{1/4, -1/2, -3/8, 3/8, 0, -1/4},
			{-3/8, -1/2, 1/4, -1/4, 0, 3/8},
		},
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "size[8,9]"..
			"list[current_name;main;2,0;4,4;]"..
			"list[current_player;main;0,5;8,4;]"
		)
		meta:set_string("infotext", "Turret Gun")
		local inv = meta:get_inventory()
		inv:set_size("main", 16)
	end,
	after_place_node = function(pos, placer)
		local node = minetest.get_node({x=pos.x, y=pos.y + 1, z=pos.z})
		if node.name == "air" then
			if not get_turret_entity(pos) then
				minetest.add_entity(pos, "shooter:turret_entity")
			end
		end
	end,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	after_destruct = function(pos, oldnode)
		local ent = get_turret_entity(pos)
		if ent then
			ent.object:remove()
		end
	end,
	mesecons = {
		effector = {
			action_on = function(pos, node)
				local ent = get_turret_entity(pos)
				if ent then
					if ent.firing == false then
						ent:fire()
						ent.firing = true
					end
				end
			end,
			action_off = function(pos, node)
				local ent = get_turret_entity(pos)
				if ent then
					ent.firing = false
				end
			end,
		},
	},
})

if SHOOTER_ENABLE_CRAFTING == true then
	minetest.register_craft({
		output = "shooter:turret",
		recipe = {
			{"default:bronze_ingot", "default:bronze_ingot", "default:steel_ingot"},
			{"", "default:bronze_ingot", "default:steel_ingot"},
			{"", "default:diamond", ""},
		},
	})
end

