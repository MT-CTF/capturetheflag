local S = minetest.get_translator("vehicles")

vehicles = {}

dofile(minetest.get_modpath("vehicles").."/api.lua")

minetest.register_entity("vehicles:missile", {
	visual = "mesh",
	mesh = "missile.b3d",
	textures = {"vehicles_missile.png"},
	velocity = 15,
	acceleration = -5,
	damage = 2,
	collisionbox = {-1, -0.5, -1, 1, 0.5, 1},
	on_rightclick = function(self, clicker)
	clicker:set_attach(self.object, "", {x=0,y=0,z=0}, {x=0,y=1,z=0})
	end,
	on_step = function(self, obj, pos)
	minetest.after(10, function()
	self.object:remove()
	end)
	local player = self.launcher
	if player == nil or player:get_player_name() == "" then
		self.object:remove()
		return
	end
	local dir = player:get_look_dir()
	local vec = {x=dir.x*16,y=dir.y*16,z=dir.z*16}
	local yaw = player:get_look_yaw()
	self.object:setyaw(yaw+math.pi/2)
	self.object:setvelocity(vec)
	local pos = self.object:getpos()
	local vec = self.object:getvelocity()
	minetest.add_particlespawner({
		amount = 1,
		time = 0.5,
		minpos = {x=pos.x-0.2, y=pos.y, z=pos.z-0.2},
		maxpos = {x=pos.x+0.2, y=pos.y, z=pos.z+0.2},
		minvel = {x=-vec.x/2, y=-vec.y/2, z=-vec.z/2},
		maxvel = {x=-vec.x, y=-vec.y, z=-vec.z},
		minacc = {x=0, y=-1, z=0},
		maxacc = {x=0, y=-1, z=0},
		minexptime = 0.2,
		maxexptime = 0.6,
		minsize = 3,
		maxsize = 4,
		collisiondetection = false,
		texture = "vehicles_smoke.png",
	})
	local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 2)
	for k, obj in pairs(objs) do
		if obj:get_luaentity() ~= nil then
			if obj:get_luaentity().name ~= "vehicles:missile" and obj ~= self.vehicle and obj ~= self.launcher and obj:get_luaentity().name ~= "__builtin:item" then
				obj:punch(self.object, 1.0, {
					full_punch_interval=1.0,
					damage_groups={fleshy=12},
				}, nil)
				local pos = self.object:getpos()
				tnt.boom(pos, {damage_radius=5,radius=5,ignore_protection=false})
				self.object:remove()
			end
		end
	end

	for dx=-1,1 do
		for dy=-1,1 do
			for dz=-1,1 do
				local p = {x=pos.x+dx, y=pos.y, z=pos.z+dz}
				local t = {x=pos.x+dx, y=pos.y+dy, z=pos.z+dz}
				local n = minetest.env:get_node(p).name
				if n ~= "vehicles:missile" and n ~= "vehicles:jet" and n ~= "air" then
					local pos = self.object:getpos()
					tnt.boom(pos, {damage_radius=5,radius=5,ignore_protection=false})
					self.object:remove()
					return
				end
			end
		end
	end
	end,
})


minetest.register_craftitem("vehicles:missile_2_item", {
	description = S("Missile"),
	inventory_image = "vehicles_missile_inv.png"
})

minetest.register_craftitem("vehicles:bullet_item", {
	description = S("Bullet"),
	inventory_image = "vehicles_bullet_inv.png"
})


minetest.register_entity("vehicles:missile_2", {
	visual = "mesh",
	mesh = "missile.b3d",
	textures = {"vehicles_missile.png"},
	velocity = 15,
	acceleration = -5,
	damage = 2,
	collisionbox = {0, 0, 0, 0, 0, 0},
	on_step = function(self, obj, pos)
	minetest.after(10, function()
	self.object:remove()
	end)
	local velo = self.object:getvelocity()
	if velo.y <= 1.2 and velo.y >= -1.2 then
		self.object:set_animation({x=1, y=1}, 5, 0)
	elseif velo.y <= -1.2 then
		self.object:set_animation({x=4, y=4}, 5, 0)
	elseif velo.y >= 1.2 then
		self.object:set_animation({x=2, y=2}, 5, 0)
	end
	local pos = self.object:getpos()
	minetest.add_particlespawner({
		amount = 2,
		time = 0.5,
		minpos = {x=pos.x-0.2, y=pos.y, z=pos.z-0.2},
		maxpos = {x=pos.x+0.2, y=pos.y, z=pos.z+0.2},
		minvel = {x=-velo.x/2, y=-velo.y/2, z=-velo.z/2},
		maxvel = {x=-velo.x, y=-velo.y, z=-velo.z},
		minacc = {x=0, y=-1, z=0},
		maxacc = {x=0, y=-1, z=0},
		minexptime = 0.2,
		maxexptime = 0.6,
		minsize = 3,
		maxsize = 4,
		collisiondetection = false,
		texture = "vehicles_smoke.png",
	})
	local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 2)
	for k, obj in pairs(objs) do
		if obj:get_luaentity() ~= nil then
			if obj:get_luaentity().name ~= "vehicles:missile_2" and obj ~= self.vehicle and obj:get_luaentity().name ~= "__builtin:item" then
				obj:punch(self.launcher, 1.0, {
					full_punch_interval=1.0,
					damage_groups={fleshy=12},
				}, nil)
				self.object:remove()
			end
		end
	end

	for dx=-1,1 do
		for dy=-1,1 do
			for dz=-1,1 do
				local p = {x=pos.x+dx, y=pos.y, z=pos.z+dz}
				local t = {x=pos.x+dx, y=pos.y+dy, z=pos.z+dz}
				local n = minetest.env:get_node(p).name
				if n ~= "vehicles:missile_2" and n ~= "vehicles:tank" and n ~= "vehicles:jet" and n ~= "air" then
					local pos = self.object:getpos()
					minetest.add_particlespawner({
						amount = 30,
						time = 0.5,
						minpos = {x=pos.x-0.5, y=pos.y-0.5, z=pos.z-0.5},
						maxpos = {x=pos.x+0.5, y=pos.y+0.5, z=pos.z+0.5},
						minvel = {x=-1, y=-1, z=-1},
						maxvel = {x=1, y=1, z=1},
						minacc = {x=0, y=0.2, z=0},
						maxacc = {x=0, y=0.6, z=0},
						minexptime = 0.5,
						maxexptime = 1,
						minsize = 10,
						maxsize = 20,
						collisiondetection = false,
						texture = "vehicles_explosion.png"
					})
					tnt.boom(pos, {damage_radius=5,radius=5,ignore_protection=false})
					self.object:remove()
					return
				end
			end
		end
	end
	end,
})

minetest.register_entity("vehicles:helicopter", {
	visual = "mesh",
	mesh = "helicopter.b3d",
	textures = {"vehicles_helicopter.png"},
	velocity = 15,
	acceleration = -5,
	hp_max = 100,
	animation_speed = 5,
	physical = true,
	animations = {
		gear = {x=1, y=1},
		nogear = {x=10, y=10},
	},
	collisionbox = {-1.2, 0, -1.2, 1.2, 2, 1.2},
	on_rightclick = function(self, clicker)
	if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
	elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=4, z=1}, false, {x=0, y=2, z=13})
	end
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
	return vehicles.on_step(self, dtime, {
		speed = 10,
		decell = 0.95,
		moving_anim = {x=1, y=20},
		stand_anim = {x=1, y=1},
		fly = true,
		fly_mode = "rise",
		animation_speed = 35,
	})
	end,
})

vehicles.register_spawner("vehicles:helicopter", S("Helicopter"), "vehicles_helicopter_inv.png")

minetest.register_entity("vehicles:plane", {
	visual = "mesh",
	mesh = "plane.b3d",
	textures = {"vehicles_plane.png"},
	velocity = 15,
	acceleration = -5,
	hp_max = 200,
	animation_speed = 5,
	physical = true,
	collisionbox = {-1.1, 0, -1, 1, 1.9, 1.1},
	on_rightclick = function(self, clicker)
	if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
	elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=8, z=3}, false, {x=0, y=9, z=0})
	end
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		if self.anim and not self.driver then 
			self.object:set_animation({x=1, y=1}, 5, 0)
		end
		return vehicles.on_step(self, dtime, {
			speed = 14, 
			decell = 0.95,
			fly = true,
			fly_mode = "hold",
		},
		function()
			if not self.anim then
				self.object:set_animation({x=1, y=9}, 20, 0)
				self.anim = true
			end
		end,
		function()
			self.anim = false
		end)
	end,
})

vehicles.register_spawner("vehicles:plane", S("Plane"), "vehicles_plane_inv.png")

minetest.register_entity("vehicles:parachute", {
	visual = "mesh",
	mesh = "parachute.b3d",
	textures = {"vehicles_parachute.png"},
	velocity = 15,
	acceleration = -5,
	hp_max = 2,
	physical = true,
	collisionbox = {-0.5, -1, -0.5, 0.5, 1, 0.5},
	on_rightclick = function(self, clicker)
	if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
	elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=0, z=-1.5}, false, {x=0, y=-4, z=0})
	end
	end,
	on_step = function(self, dtime)
	if self.driver then
		vehicles.object_glide(self, dtime, 8, 0.92, -0.2, "", "")
		return false
	end
	return true
	end,
})

minetest.register_tool("vehicles:backpack", {
	description = S("Parachute"),
	inventory_image = "vehicles_backpack.png",
	wield_scale = {x = 1.5, y = 1.5, z = 1},
	tool_capabilities = {
		full_punch_interval = 0.7,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=2.0, [2]=1.00, [3]=0.35}, uses=30, maxlevel=3},
		},
		damage_groups = {fleshy=1},
	},
	on_use = function(item, placer, pointed_thing)
	local dir = placer:get_look_dir()
	local playerpos = placer:getpos()
	local pname = placer:get_player_name()
	local obj = minetest.env:add_entity({x=playerpos.x+0+dir.x,y=playerpos.y+1+dir.y,z=playerpos.z+0+dir.z}, "vehicles:parachute")
	local entity = obj:get_luaentity()
	if obj.driver and placer == obj.driver then
		vehicles.object_detach(entity, placer, {x=1, y=0, z=1})
	elseif not obj.driver then
		vehicles.object_attach(entity, placer, {x=0, y=0, z=0}, true, {x=0, y=2, z=0})
	end
	item:take_item()
	return item
	end,
})

minetest.register_tool("vehicles:rc", {
	description = S("Rc (use with missiles)"),
	inventory_image = "vehicles_rc.png",
	wield_scale = {x = 1.5, y = 1.5, z = 1},
	tool_capabilities = {
		full_punch_interval = 0.7,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=2.0, [2]=1.00, [3]=0.35}, uses=30, maxlevel=3},
		},
		damage_groups = {fleshy=1},
	},
	on_use = function(item, placer, pointed_thing)
	local dir = placer:get_look_dir()
	local playerpos = placer:getpos()
	local pname = placer:get_player_name()
	local inv = minetest.get_inventory({type="player", name=pname})
	if inv:contains_item("main", "vehicles:missile_2_item") then
		local remov = inv:remove_item("main", "vehicles:missile_2_item")
		local obj = minetest.env:add_entity({x=playerpos.x+0+dir.x,y=playerpos.y+1+dir.y,z=playerpos.z+0+dir.z}, "vehicles:missile")
		local object = obj:get_luaentity()
		object.launcher = placer
		object.vehicle = nil
		local vec = {x=dir.x*6,y=dir.y*6,z=dir.z*6}
		obj:setvelocity(vec)
		return item
	end
	end,
})

