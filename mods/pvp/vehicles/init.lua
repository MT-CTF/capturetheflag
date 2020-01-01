local S = minetest.get_translator("vehicles")

vehicles = {}

dofile(minetest.get_modpath("vehicles").."/api.lua")

--very laggy and buggy flight
-- minetest.register_globalstep(function(dtime)
	-- for _, player in ipairs(minetest.get_connected_players()) do
		-- local dir = player:get_look_dir();
		-- local pos = player:getpos();
		-- local ctrl = player:get_player_control();
		-- local pos1 = {x=pos.x+dir.x*1,y=pos.y+dir.y*1,z=pos.z+dir.z*1}
		-- if ctrl.up == true then
		-- player:moveto(pos1, false)
		-- else
		-- end
	-- end
-- end)

local step = 1.1

local enable_built_in = true

if enable_built_in then
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
		if player == nil then
			self.object:remove()
			return
		end
		local dir = player:get_look_dir();
		if dir == nil then
			self.object:remove()
			return
		end
		local vec = {x=dir.x*16,y=dir.y*16,z=dir.z*16}
		local yaw = player:get_look_yaw();
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

minetest.register_entity("vehicles:water", {
	visual = "sprite",
	textures = {"vehicles_trans.png"},
	velocity = 15,
	acceleration = -5,
	damage = 2,
	collisionbox = {0, 0, 0, 0, 0, 0},
	on_activate = function(self)
		self.object:setacceleration({x=0, y=-1, z=0})
	end,
	on_step = function(self, obj, pos)
		minetest.after(5, function()
			self.object:remove()
		end)
		local pos = self.object:getpos()
	minetest.add_particlespawner({
		amount = 1,
		time = 1,
		minpos = {x=pos.x, y=pos.y, z=pos.z},
		maxpos = {x=pos.x, y=pos.y, z=pos.z},
		minvel = {x=0, y=0, z=0},
		maxvel = {x=0, y=-0.2, z=0},
		minacc = {x=0, y=-1, z=0},
		maxacc = {x=0, y=-1, z=0},
		minexptime = 1,
		maxexptime = 1,
		minsize = 4,
		maxsize = 5,
		collisiondetection = false,
		vertical = false,
		texture = "vehicles_water.png",
	})
	local node = minetest.env:get_node(pos).name
	if node == "fire:basic_flame" then
	minetest.remove_node(pos)
	end
	end
})

minetest.register_entity("vehicles:bullet", {
	visual = "mesh",
	mesh = "bullet.b3d",
	textures = {"vehicles_bullet.png"},
	velocity = 15,
	acceleration = -5,
	damage = 2,
	collisionbox = {0, 0, 0, 0, 0, 0},
	on_activate = function(self)
		local pos = self.object:getpos()
		minetest.sound_play("shot", 
		{gain = 0.4, max_hear_distance = 3, loop = false})
	end,
	on_step = function(self, obj, pos)
		minetest.after(10, function()
			self.object:remove()
		end)
		local pos = self.object:getpos()
		local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 2)	
			for k, obj in pairs(objs) do
				if obj:get_luaentity() ~= nil then
					if obj:get_luaentity().name ~= "vehicles:bullet" and obj ~= self.vehicle and obj:get_luaentity().name ~= "__builtin:item" then
						obj:punch(self.launcher, 1.0, {
							full_punch_interval=1.0,
							damage_groups={fleshy=5},
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
								if n ~= "vehicles:bullet" and n ~= "air" then
									self.object:remove()
									return
								end
							end
						end
					end
	end,
})

minetest.register_entity("vehicles:tank", {
	visual = "mesh",
	mesh = "tank.b3d",
	textures = {"vehicles_tank.png"},
	velocity = 15,
	acceleration = -5,
	owner = "",
	stepheight = 1.5,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -0.9, 1, 1.5, 0.9},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=25, z=-3}, true, {x=0, y=6, z=-2})
		end
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
		speed = 6,
		decell = 0.5, 
		shoots = true, 
		arrow = "vehicles:missile_2",
		reload_time = 1,
		shoot_y = 2,
		moving_anim = {x=3, y=8},
		stand_anim = {x=1, y=1},
		})
	end,
})

vehicles.register_spawner("vehicles:tank", S("Tank"), "vehicles_tank_inv.png")

minetest.register_entity("vehicles:tank2", {
	visual = "mesh",
	mesh = "tank.b3d",
	textures = {"vehicles_tank2.png"},
	velocity = 15,
	acceleration = -5,
	owner = "",
	stepheight = 1.5,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -0.9, 1, 1.5, 0.9},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=25, z=-3}, true, {x=0, y=6, z=-2})
		end
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
		speed = 6,
		decell = 0.5, 
		shoots = true, 
		arrow = "vehicles:missile_2",
		reload_time = 1,
		shoot_y = 2,
		moving_anim = {x=3, y=8},
		stand_anim = {x=1, y=1},
		})
	end,
})

vehicles.register_spawner("vehicles:tank2", S("Desert Tank"), "vehicles_tank2_inv.png")

minetest.register_entity("vehicles:turret", {
	visual = "mesh",
	mesh = "turret_gun.b3d",
	textures = {"vehicles_turret.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = 1.5,
	hp_max = 50,
	groups = {fleshy=3, level=5},
	physical = true,
	collisionbox = {-0.6, 0, -0.6, 0.6, 0.9, 0.6},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, true, {x=0, y=2, z=4})
		end
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
	self.object:setvelocity({x=0, y=-1, z=0})
	if self.driver then
		vehicles.object_drive(self, dtime, {
			fixed = true,
			shoot_y = 1.5,
			arrow = "vehicles:bullet",
			shoots = true,
			reload_time = 0.2,
		})
		return false
		end
		return true
	end,
})

vehicles.register_spawner("vehicles:turret", S("Gun turret"), "vehicles_turret_inv.png")

minetest.register_entity("vehicles:assaultsuit", {
	visual = "mesh",
	mesh = "assaultsuit.b3d",
	textures = {"vehicles_assaultsuit.png"},
	velocity = 15,
	acceleration = -5,
	owner = "",
	stepheight = 1.5,
	hp_max = 200,
	physical = true,
	collisionbox = {-0.8, 0, -0.8, 0.8, 3, 0.8},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=20, z=8})
		end
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
		speed = 8,
		decell = 0.5, 
		shoots = true,
		arrow = "vehicles:bullet",
		reload_time = 0.2,
		shoots2 = true,
		arrow2 = "vehicles:missile_2",
		reload_time2 = 1,
		moving_anim = {x=120, y=140},
		stand_anim = {x=1, y=1},
		jump_type = "hover",
		jump_anim = {x=60, y=70},
		shoot_anim = {x=40, y=51},
		shoot_anim2 = {x=40, y=51},
		shoot_y = 3.5,
		shoot_y2 = 4,
		},
		function() self.standing = false end,
		function()
			if not self.standing then
				self.object:set_animation({x=1, y=1}, 20, 0)
				self.standing = true
			end
		end)
	end,
})

vehicles.register_spawner("vehicles:assaultsuit", "Assault Suit", "vehicles_assaultsuit_inv.png")

minetest.register_entity("vehicles:firetruck", {
	visual = "mesh",
	mesh = "firetruck.b3d",
	textures = {"vehicles_firetruck.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = 1.5,
	hp_max = 200,
	physical = true,
	collisionbox = {-1.1, 0, -1.1, 1.1, 1.9, 1.1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=5}, false, {x=0, y=2, z=5})
		end
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 10,
			decell = 0.5,
			shoots = true,
			arrow = "vehicles:water",
			infinite_arrow = true,
			reload_time = 0.2,
			driving_sound = "engine",
			sound_duration = 11,
			handling = {initial=1.3, braking=2},
		})
	end,
})

vehicles.register_spawner("vehicles:firetruck", S("Fire truck"), "vehicles_firetruck_inv.png")

minetest.register_entity("vehicles:tractor", {
	visual = "mesh",
	mesh = "tractor.b3d",
	textures = {"vehicles_tractor.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = 1.5,
	hp_max = 200,
	physical = true,
	collisionbox = {-0.8, 0, -0.8, 0.8, 1.4, 0.8},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=14, z=-10}, true, {x=0, y=2, z=-5})
		end
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 8,
			decell = 0.5,
			driving_sound = "engine",
			sound_duration = 11,
			destroy_node = "farming:wheat_8",
			moving_anim = {x=3, y=18},
			stand_anim = {x=1, y=1},
			handling = {initial=1.3, braking=2},
		})
	end,
})

vehicles.register_spawner("vehicles:tractor", S("Tractor"), "vehicles_tractor_inv.png")

minetest.register_entity("vehicles:geep", {
	visual = "mesh",
	mesh = "geep.b3d",
	textures = {"vehicles_geep.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = 1.5,
	hp_max = 200,
	physical = true,
	collisionbox = {-1.1, 0, -1.1, 1.1, 1, 1.1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif self.driver and clicker ~= self.driver and not self.rider then
		clicker:set_attach(self.object, "", {x=0, y=5, z=-5}, false, {x=0, y=0, z=-2})
		self.rider = true
		elseif self.driver and clicker ~=self.driver and self.rider then
		clicker:set_detach()
		self.rider = false
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=-2, y=15, z=-1}, true, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
		self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 14, 
			decell = 0.6,
			boost = true,
			boost_duration = 6,
			boost_effect = "vehicles_nitro.png",
			sound_duration = 11,
			driving_sound = "engine",
			brakes = true,
		},
		function()
		local pos = self.object:getpos()
		minetest.add_particlespawner(
			4, --amount
			1, --time
			{x=pos.x, y=pos.y, z=pos.z}, --minpos
			{x=pos.x, y=pos.y, z=pos.z}, --maxpos
			{x=0, y=0, z=0}, --minvel
			{x=0, y=0, z=0}, --maxvel
			{x=-0,y=-0,z=-0}, --minacc
			{x=0,y=0,z=0}, --maxacc
			0.5, --minexptime
			1, --maxexptime
			10, --minsize
			15, --maxsize
			false, --collisiondetection
			"vehicles_dust.png" --texture
		)
		end)
	end,
})

vehicles.register_spawner("vehicles:geep", S("Geep"), "vehicles_geep_inv.png")

minetest.register_entity("vehicles:ambulance", {
	visual = "mesh",
	mesh = "ambulance.b3d",
	textures = {"vehicles_ambulance.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = 1.5,
	hp_max = 200,
	physical = true,
	collisionbox = {-1.4, 0, -1.4, 1.4, 2, 1.4},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif self.driver and clicker ~= self.driver and not self.rider then
		clicker:set_attach(self.object, clicker, {x=0, y=5, z=4}, false, {x=0, y=7, z=10})
		self.rider = true
		clicker:set_hp(20)
		elseif self.driver and clicker ~= self.driver and self.rider then
		clicker:set_detach()
		self.rider = false
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=7, z=14})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
		self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 13, 
			decell = 0.6,
			moving_anim = {x=1, y=3},
			stand_anim = {x=1, y=1},
			driving_sound = "engine",
			sound_duration = 11,
			handling = {initial=1.3, braking=2},
			brakes = true,
		},
		function()
			if not self.siren_ready then
				minetest.sound_play("ambulance", 
				{pos=self.object:getpos(), gain = 0.1, max_hear_distance = 3, loop = false})
				self.siren_ready = true
				minetest.after(4, function()
					self.siren_ready = false
				end)
			end
		end)
	end,
})

vehicles.register_spawner("vehicles:ambulance", S("Ambulance"), "vehicles_ambulance_inv.png")

minetest.register_entity("vehicles:ute", {
	visual = "mesh",
	mesh = "ute.b3d",
	textures = {"vehicles_ute.png"},
	velocity = 17,
	acceleration = -5,
	stepheight = 1.5,
	hp_max = 200,
	physical = true,
	collisionbox = {-1.4, 0, -1.4, 1.4, 1, 1.4},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif self.driver and clicker ~= self.driver and not self.rider then
		clicker:set_attach(self.object, clicker, {x=0, y=5, z=-5}, false, {x=0, y=0, z=-2})
		self.rider = true
		elseif self.driver and clicker ~=self.driver and self.rider then
		clicker:set_detach()
		self.rider = false
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
		self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 17, 
			decell = 0.95,
			boost = true,
			boost_duration = 6,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		},
		function()
			local pos = self.object:getpos()
			minetest.add_particlespawner(
				15, --amount
				1, --time
				{x=pos.x, y=pos.y, z=pos.z}, --minpos
				{x=pos.x, y=pos.y, z=pos.z}, --maxpos
				{x=0, y=0, z=0}, --minvel
				{x=0, y=0, z=0}, --maxvel
				{x=-0,y=-0,z=-0}, --minacc
				{x=0,y=0,z=0}, --maxacc
				0.5, --minexptime
				1, --maxexptime
				10, --minsize
				15, --maxsize
				false, --collisiondetection
				"vehicles_dust.png" --texture
			)
		end)
	end,
})

vehicles.register_spawner("vehicles:ute", S("Ute (dirty)"), "vehicles_ute_inv.png")

minetest.register_entity("vehicles:ute2", {
	visual = "mesh",
	mesh = "ute.b3d",
	textures = {"vehicles_ute2.png"},
	velocity = 17,
	acceleration = -5,
	stepheight = 1.5,
	hp_max = 200,
	physical = true,
	collisionbox = {-1.4, 0, -1.4, 1.4, 1, 1.4},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif self.driver and clicker ~= self.driver and not self.rider then
		clicker:set_attach(self.object, clicker, {x=0, y=5, z=-5}, {x=0, y=0, z=0})
		self.rider = true
		elseif self.driver and clicker ~=self.driver and self.rider then
		clicker:set_detach()
		self.rider = false
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
	self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 17, 
			decell = 0.95,
			boost = true,
			boost_duration = 6,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:ute2", S("Ute (clean)"), "vehicles_ute_inv.png")

minetest.register_entity("vehicles:astonmaaton", {
	visual = "mesh",
	mesh = "astonmaaton.b3d",
	textures = {"vehicles_astonmaaton.png"},
	velocity = 19,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
	self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 19, 
			decell = 0.99,
			boost = true,
			boost_duration = 5,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:astonmaaton", S("Aston Maaton (white)"), "vehicles_astonmaaton_inv.png")

minetest.register_entity("vehicles:nizzan", {
	visual = "mesh",
	mesh = "nizzan.b3d",
	textures = {"vehicles_nizzan.png"},
	velocity = 20,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
		self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 18, 
			decell = 0.99,
			boost = true,
			boost_duration = 5,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		},
		function()
			local pos = self.object:getpos()
			minetest.add_particlespawner(
				15, --amount
				1, --time
				{x=pos.x, y=pos.y, z=pos.z}, --minpos
				{x=pos.x, y=pos.y, z=pos.z}, --maxpos
				{x=0, y=0, z=0}, --minvel
				{x=0, y=0, z=0}, --maxvel
				{x=-0,y=-0,z=-0}, --minacc
				{x=0,y=0,z=0}, --maxacc
				0.5, --minexptime
				1, --maxexptime
				10, --minsize
				15, --maxsize
				false, --collisiondetection
				"vehicles_dust.png" --texture
			)
		end)
	end,
})

vehicles.register_spawner("vehicles:nizzan", S("Nizzan (brown)"), "vehicles_nizzan_inv.png")

minetest.register_entity("vehicles:nizzan2", {
	visual = "mesh",
	mesh = "nizzan.b3d",
	textures = {"vehicles_nizzan2.png"},
	velocity = 20,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_activate = function(self)
		self.nitro = true
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 18, 
			decell = 0.99,
			boost = true,
			boost_duration = 5,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		},
		function()
			local pos = self.object:getpos()
			minetest.add_particlespawner(
				15, --amount
				1, --time
				{x=pos.x, y=pos.y, z=pos.z}, --minpos
				{x=pos.x, y=pos.y, z=pos.z}, --maxpos
				{x=0, y=0, z=0}, --minvel
				{x=0, y=0, z=0}, --maxvel
				{x=-0,y=-0,z=-0}, --minacc
				{x=0,y=0,z=0}, --maxacc
				0.2, --minexptime
				0.5, --maxexptime
				20, --minsize
				25, --maxsize
				false, --collisiondetection
				"vehicles_dust.png" --texture
			)
		end)
	end,
})

vehicles.register_spawner("vehicles:nizzan2", S("Nizzan (green)"), "vehicles_nizzan_inv2.png")

minetest.register_entity("vehicles:lambogoni", {
	visual = "mesh",
	mesh = "lambogoni.b3d",
	textures = {"vehicles_lambogoni.png"},
	velocity = 19,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
		self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 19, 
			decell = 0.99,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:lambogoni", S("Lambogoni (grey)"), "vehicles_lambogoni_inv.png")

minetest.register_entity("vehicles:lambogoni2", {
	visual = "mesh",
	mesh = "lambogoni.b3d",
	textures = {"vehicles_lambogoni2.png"},
	velocity = 19,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
		self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 19, 
			decell = 0.99,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:lambogoni2", S("Lambogoni (yellow)"), "vehicles_lambogoni2_inv.png")

minetest.register_entity("vehicles:masda", {
	visual = "mesh",
	mesh = "masda.b3d",
	textures = {"vehicles_masda.png"},
	velocity = 21,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
		self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 21, 
			decell = 0.99,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:masda", S("Masda (pink)"), "vehicles_masda_inv.png")

minetest.register_entity("vehicles:masda2", {
	visual = "mesh",
	mesh = "masda.b3d",
	textures = {"vehicles_masda2.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_activate = function(self)
		self.nitro = true
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 21, 
			decell = 0.99,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:masda2", S("Masda (orange)"), "vehicles_masda_inv2.png")

minetest.register_entity("vehicles:policecar", {
	visual = "mesh",
	mesh = "policecar.b3d",
	textures = {"vehicles_policecar.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = step,
	hp_max = 190,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_activate = function(self)
		self.nitro = true
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 20, 
			decell = 0.99,
			boost = true,
			boost_duration = 8,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:policecar", S("Police Car (US)"), "vehicles_policecar_inv.png")

minetest.register_entity("vehicles:musting", {
	visual = "mesh",
	mesh = "musting.b3d",
	textures = {"vehicles_musting.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_activate = function(self)
		self.nitro = true
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 17, 
			decell = 0.99,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:musting", S("Musting (purple)"), "vehicles_musting_inv2.png")

minetest.register_entity("vehicles:musting2", {
	visual = "mesh",
	mesh = "musting.b3d",
	textures = {"vehicles_musting2.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
		self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 17, 
			decell = 0.99,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:musting2", S("Musting (white)"), "vehicles_musting_inv.png")

minetest.register_entity("vehicles:fourd", {
	visual = "mesh",
	mesh = "fourd.b3d",
	textures = {"vehicles_fourd.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_activate = function(self)
		self.nitro = true
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 15, 
			decell = 0.99,
			driving_sound = "engine",
			sound_duration = 11,
			moving_anim = {x=3, y=18},
			stand_anim = {x=1, y=1},
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:fourd", S("Fourd"), "vehicles_fourd_inv.png")

minetest.register_entity("vehicles:fewawi", {
	visual = "mesh",
	mesh = "fewawi.b3d",
	textures = {"vehicles_fewawi.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		local ctrl = clicker:get_player_control()
		if ctrl.sneak then
		if not self.lights then
		self.object:set_properties({textures = {"vehicles_fewawi_lights.png"},})
		self.lights = true
		else
		self.object:set_properties({textures = {"vehicles_fewawi.png"},})
		self.lights = false		
		end
		else
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
		self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 20, 
			decell = 0.99,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:fewawi", S("Fewawi (red)"), "vehicles_fewawi_inv.png")

minetest.register_entity("vehicles:fewawi2", {
	visual = "mesh",
	mesh = "fewawi.b3d",
	textures = {"vehicles_fewawi2.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		local ctrl = clicker:get_player_control()
		if ctrl.sneak then
		if not self.lights then
		self.object:set_properties({textures = {"vehicles_fewawi_lights2.png"},})
		self.lights = true
		else
		self.object:set_properties({textures = {"vehicles_fewawi2.png"},})
		self.lights = false
		end
		else
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
		self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 20, 
			decell = 0.99,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:fewawi2", S("Fewawi (blue)"), "vehicles_fewawi_inv2.png")

minetest.register_entity("vehicles:pooshe", {
	visual = "mesh",
	mesh = "pooshe.b3d",
	textures = {"vehicles_pooshe.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_activate = function(self)
		self.nitro = true
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 15, 
			decell = 0.99,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:pooshe", S("Pooshe (red)"), "vehicles_pooshe_inv.png")

minetest.register_entity("vehicles:pooshe2", {
	visual = "mesh",
	mesh = "pooshe.b3d",
	textures = {"vehicles_pooshe2.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		minetest.sound_play("engine_start", 
		{to_player=self.driver:get_player_name(), gain = 4, max_hear_distance = 3, loop = false})
		self.sound_ready = false
		minetest.after(14, function()
		self.sound_ready = true
		end)
		end
	end,
	on_punch = vehicles.on_punch,
	on_activate = function(self)
		self.nitro = true
	end,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 20, 
			decell = 0.99,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			driving_sound = "engine",
			sound_duration = 11,
			brakes = true,
		})
	end,
})

vehicles.register_spawner("vehicles:pooshe2", S("Pooshe (yellow)"), "vehicles_pooshe_inv2.png")

minetest.register_entity("vehicles:lightcycle", {
	visual = "mesh",
	mesh = "lightcycle.b3d",
	textures = {"vehicles_lightcycle.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		self.sound_ready = true
		end
	end,
	on_activate = function(self)
		self.nitro = true
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 20, 
			decell = 0.85,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			place_node = "vehicles:light_barrier",
			place_trigger = true,
			death_node = "vehicles:light_barrier2",
			handling = {initial=3, braking=2.2}
		})
	end,
})

vehicles.register_spawner("vehicles:lightcycle", S("Lightcycle"), "vehicles_lightcycle_inv.png")

minetest.register_entity("vehicles:lightcycle2", {
	visual = "mesh",
	mesh = "lightcycle.b3d",
	textures = {"vehicles_lightcycle2.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = step,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		self.sound_ready = true
		end
	end,
	on_activate = function(self)
		self.nitro = true
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 20, 
			decell = 0.85,
			boost = true,
			boost_duration = 4,
			boost_effect = "vehicles_nitro.png",
			place_node = "vehicles:light_barrier2",
			place_trigger = true,
			death_node = "vehicles:light_barrier",
			handling = {initial=3, braking=2.2}
		})
	end,
})

vehicles.register_spawner("vehicles:lightcycle2", S("Lightcycle 2"), "vehicles_lightcycle_inv2.png")

minetest.register_entity("vehicles:boat", {
	visual = "mesh",
	mesh = "boat.b3d",
	textures = {"vehicles_boat.png"},
	velocity = 15,
	acceleration = -5,
	stepheight = 0,
	hp_max = 200,
	physical = true,
	collisionbox = {-1, 0.2, -1, 1.3, 1, 1},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=5, z=4}, false, {x=0, y=2, z=4})
		end
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 10, 
			decell = 0.85,
			is_watercraft = true,
			gravity = 0,
			boost = true,
			boost_duration = 10,
			boost_effect = "vehicles_splash.png",
			brakes = true,
			braking_effect = "vehicles_splash.png",
			handling = {initial=1.8, braking=2.3}
		})
	end,
})

vehicles.register_spawner("vehicles:boat", S("Speedboat"), "vehicles_boat_inv.png", true)

minetest.register_entity("vehicles:jet", {
	visual = "mesh",
	mesh = "jet.b3d",
	textures = {"vehicles_jet.png"},
	velocity = 15,
	acceleration = -5,
	hp_max = 200,
	animation_speed = 5,
	physical = true,
	animations = {
      gear = {x=1, y=1},
      nogear = {x=10, y=10},
	},
	collisionbox = {-1, -0.9, -0.9, 1, 0.9, 0.9},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=4, z=3}, false, {x=0, y=4, z=3})
		end
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 20, 
			decell = 0.95,
			shoots = true,
			arrow = "vehicles:missile_2",
			reload_time = 1,
			moving_anim = {x=10, y=10},
			stand_anim = {x=1, y=1},
			fly = true,
			fly_mode = "rise",
			braking_effect = "vehicles_trans.png",
		})
	end,
})

vehicles.register_spawner("vehicles:jet", S("Jet"), "vehicles_jet_inv.png")

minetest.register_entity("vehicles:apache", {
	visual = "mesh",
	mesh = "apache.b3d",
	textures = {"vehicles_helicopter2.png"},
	velocity = 15,
	acceleration = -5,
	hp_max = 200,
	animation_speed = 5,
	physical = true,
	collisionbox = {-1.8, 0, -1.8, 1.8, 1.5, 1.8},
	on_rightclick = function(self, clicker)
		if self.driver and clicker == self.driver then
		vehicles.object_detach(self, clicker, {x=1, y=0, z=1})
		elseif not self.driver then
		vehicles.object_attach(self, clicker, {x=0, y=20, z=17}, true, {x=0, y=10, z=14})
		end
	end,
	on_punch = vehicles.on_punch,
	on_step = function(self, dtime)
		return vehicles.on_step(self, dtime, {
			speed = 16, 
			decell = 0.95,
			shoots = true,
			arrow = "vehicles:missile_2",
			reload_time = 1,
			shoots2 = true,
			shoot_y = 3, 
			shoot_y2 = 1.5,
			arrow2 = "vehicles:bullet",
			reload_time2 = 0.1,
			moving_anim = {x=2, y=18},
			stand_anim = {x=25, y=25},
			fly = true,
			fly_mode = "rise",
			gravity = 0.2,
			animation_speed = 40,
		})
	end,
})

vehicles.register_spawner("vehicles:apache", S("Apache Helicopter"), "vehicles_helicopter2_inv.png")

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
			local dir = placer:get_look_dir();
			local playerpos = placer:getpos();
			local pname = placer:get_player_name();
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


--wings
--currently doesn't work
minetest.register_entity("vehicles:wing_glider", {
	visual = "mesh",
	mesh = "wings.b3d",
	textures = {"vehicles_wings.png"},
	velocity = 15,
	acceleration = -5,
	hp_max = 2,
	armor = 0,
	physical = false,
	collisionbox = {-0.5, -0.1, -0.5, 0.5, 0.1, 0.5},
	on_step = function(self, dtime)
	if self.driver then
		local dir = self.driver:get_look_dir();
		local velo = self.object:getvelocity();
		local speed = math.sqrt(math.pow(velo.x, 2)+math.pow(velo.z, 2))
		local vec = {x=dir.x*16,y=dir.y*16+1,z=dir.z*16}
		local yaw = self.driver:get_look_yaw();
		self.object:setyaw(yaw+math.pi/2)
		self.object:setvelocity(vec)
		self.driver:set_animation({x=162, y=167}, 0, 0)
		if not self.anim then
		self.object:set_animation({x=25, y=45}, 10, 0)
		self.anim = true
		end
		return false
		else
		self.object:remove()
		end
		return true
	end,
	on_punch = function(self, puncher)
		if not self.driver then
		local name = self.object:get_luaentity().name
		local pos = self.object:getpos()
		minetest.env:add_item(pos, name.."_spawner")
		self.object:remove()
		end
		if self.object:get_hp() == 0 then
		if self.driver then
		vehicles.object_detach(self, self.driver, {x=1, y=0, z=1})
		end
		self.object:remove()
		end
	end,
})

minetest.register_tool("vehicles:wings", {
	description = S("Wings"),
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
			local wings_ready = true
			local dir = placer:get_look_dir();
			local playerpos = placer:getpos();
			local objs = minetest.get_objects_inside_radius({x=playerpos.x,y=playerpos.y,z=playerpos.z}, 2)	
			for k, obj2 in pairs(objs) do
				if obj2:get_luaentity() ~= nil and obj2:get_luaentity().name == "vehicles:wing_glider" then
					local wing = obj2:get_luaentity()
					wing.driver = nil
					obj2:remove()
					vehicles.object_detach(obj2:get_luaentity(), placer, {x=1, y=0, z=1})
					placer:set_properties({
					visual_size = {x=1, y=1},
					})
					wings_ready = false
				end
			end
			
			if wings_ready then
			local obj = minetest.env:add_entity({x=playerpos.x+0+dir.x,y=playerpos.y+1+dir.y,z=playerpos.z+0+dir.z}, "vehicles:wing_glider")
					local entity = obj:get_luaentity()
					placer:set_attach(entity.object, "", {x=0,y=-5,z=0}, {x=0,y=-3,z=0})
					entity.driver = placer
					local dir = placer:get_look_dir()
					placer:set_properties({
					visual_size = {x=1, y=-1},
					})
					item:add_wear(500)
					return item
			end
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
			local dir = placer:get_look_dir();
			local playerpos = placer:getpos();
			local pname = placer:get_player_name();
			local inv = minetest.get_inventory({type="player", name=pname});
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

--crafting recipes and materials

minetest.register_craftitem("vehicles:wheel", {
	description = S("Wheel"),
	inventory_image = "vehicles_wheel.png",
})

minetest.register_craftitem("vehicles:engine", {
	description = S("Engine"),
	inventory_image = "vehicles_engine.png",
})

minetest.register_craftitem("vehicles:body", {
	description = S("Car Body"),
	inventory_image = "vehicles_car_body.png",
})

minetest.register_craftitem("vehicles:armor", {
	description = S("Armor plating"),
	inventory_image = "vehicles_armor.png",
})

minetest.register_craftitem("vehicles:gun", {
	description = S("Vehicle Gun"),
	inventory_image = "vehicles_gun.png",
})

minetest.register_craftitem("vehicles:propeller", {
	description = S("Propeller"),
	inventory_image = "vehicles_propeller.png",
})

minetest.register_craftitem("vehicles:jet_engine", {
	description = S("Jet Engine"),
	inventory_image = "vehicles_jet_engine.png",
})

minetest.register_craft({
	output = "vehicles:propeller",
	recipe = {
		{"default:steel_ingot", "", ""},
		{"", "group:stick", ""},
		{"", "", "default:steel_ingot"}
	}
})

minetest.register_craft({
	output = "vehicles:jet_engine",
	recipe = {
		{"", "default:steel_ingot", ""},
		{"default:steel_ingot", "vehicles:propeller", "default:steel_ingot"},
		{"", "default:steel_ingot", ""}
	}
})

minetest.register_craft({
	output = "vehicles:armor",
	recipe = {
		{"", "default:gold_lump", ""},
		{"", "default:iron_lump", ""},
		{"", "default:copper_lump", ""}
	}
})

minetest.register_craft({
	output = "vehicles:gun",
	recipe = {
		{"", "vehicles:armor", ""},
		{"vehicles:armor", "default:coal_lump", "vehicles:armor"},
		{"", "default:steel_ingot", ""}
	}
})

minetest.register_craft({
	output = "vehicles:wheel",
	recipe = {
		{"", "default:coal_lump", ""},
		{"default:coal_lump", "default:steel_ingot", "default:coal_lump"},
		{"", "default:coal_lump", ""}
	}
})

minetest.register_craft({
	output = "vehicles:engine",
	recipe = {
		{"default:copper_ingot", "", "default:copper_ingot"},
		{"default:steel_ingot", "default:mese_crystal", "default:steel_ingot"},
		{"", "default:steel_ingot", ""}
	}
})

minetest.register_craft({
	output = "vehicles:body",
	recipe = {
		{"", "default:glass", ""},
		{"default:glass", "default:steel_ingot", "default:glass"},
		{"", "", ""}
	}
})

minetest.register_craft({
	output = "vehicles:bullet_item 5",
	recipe = {
		{"default:coal_lump", "default:iron_lump",},
	}
})

minetest.register_craft({
	output = "vehicles:missile_2_item",
	recipe = {
		{"", "default:steel_ingot", ""},
		{"", "default:torch", ""},
		{"default:stick", "default:coal_lump", "default:stick"}
	}
})

minetest.register_craft({
	output = "vehicles:masda_spawner",
	recipe = {
		{"", "dye:magenta", ""},
		{"", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:masda2_spawner",
	recipe = {
		{"", "dye:orange", ""},
		{"", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:ute_spawner",
	recipe = {
		{"", "dye:brown", ""},
		{"default:steel_ingot", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:ute2_spawner",
	recipe = {
		{"", "dye:white", ""},
		{"default:steel_ingot", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:nizzan2_spawner",
	recipe = {
		{"", "dye:green", ""},
		{"", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:nizzan_spawner",
	recipe = {
		{"", "dye:brown", ""},
		{"", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:astonmaaton_spawner",
	recipe = {
		{"", "dye:white", ""},
		{"", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:pooshe_spawner",
	recipe = {
		{"", "dye:red", ""},
		{"", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:pooshe2_spawner",
	recipe = {
		{"", "dye:yellow", ""},
		{"", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:lambogoni_spawner",
	recipe = {
		{"", "dye:grey", ""},
		{"", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:lambogoni2_spawner",
	recipe = {
		{"", "dye:yellow", ""},
		{"", "vehicles:body", "dye:grey"},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:fewawi_spawner",
	recipe = {
		{"", "dye:red", ""},
		{"", "vehicles:body", "default:glass"},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:fewawi2_spawner",
	recipe = {
		{"", "dye:blue", ""},
		{"", "vehicles:body", "default:glass"},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:tractor_spawner",
	recipe = {
		{"", "", ""},
		{"vehicles:engine", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:wheel", "farming:hoe_steel"}
	}
})

minetest.register_craft({
	output = "vehicles:musting_spawner",
	recipe = {
		{"", "dye:violet", ""},
		{"", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:musting2_spawner",
	recipe = {
		{"", "dye:blue", ""},
		{"", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:policecar_spawner",
	recipe = {
		{"", "dye:blue", "dye:red"},
		{"", "vehicles:body", ""},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:tank_spawner",
	recipe = {
		{"", "vehicles:gun", ""},
		{"vehicles:armor", "vehicles:engine", "vehicles:armor"},
		{"vehicles:wheel", "vehicles:wheel", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:tank2_spawner",
	recipe = {
		{"default:desert_sand", "vehicles:gun", ""},
		{"vehicles:armor", "vehicles:engine", "vehicles:armor"},
		{"vehicles:wheel", "vehicles:wheel", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:turret_spawner",
	recipe = {
		{"", "vehicles:gun", ""},
		{"vehicles:armor", "vehicles:engine", "vehicles:armor"},
	}
})

minetest.register_craft({
	output = "vehicles:jet_spawner",
	recipe = {
		{"", "vehicles:gun", ""},
		{"vehicles:jet_engine", "default:steel_ingot", "vehicles:jet_engine"},
		{"", "default:steel_ingot", ""}
	}
})

minetest.register_craft({
	output = "vehicles:plane_spawner",
	recipe = {
		{"", "vehicles:propeller", ""},
		{"default:steel_ingot", "vehicles:engine", "default:steel_ingot"},
		{"", "default:steel_ingot", ""}
	}
})

minetest.register_craft({
	output = "vehicles:helicopter_spawner",
	recipe = {
		{"", "vehicles:propeller", ""},
		{"vehicles:propeller", "vehicles:engine", "default:glass"},
		{"", "default:steel_ingot", ""}
	}
})

minetest.register_craft({
	output = "vehicles:apache_spawner",
	recipe = {
		{"", "vehicles:propeller", ""},
		{"vehicles:propeller", "vehicles:engine", "default:glass"},
		{"", "vehicles:armor", "default:steel_ingot"}
	}
})

minetest.register_craft({
	output = "vehicles:lightcycle_spawner",
	recipe = {
		{"default:steel_ingot", "vehicles:engine", "dye:cyan"},
		{"vehicles:wheel", "default:steel_ingot", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:lightcycle2_spawner",
	recipe = {
		{"default:steel_ingot", "vehicles:engine", "dye:orange"},
		{"vehicles:wheel", "default:steel_ingot", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:boat_spawner",
	recipe = {
		{"", "", ""},
		{"default:steel_ingot", "vehicles:engine", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
	}
})

minetest.register_craft({
	output = "vehicles:firetruck_spawner",
	recipe = {
		{"", "dye:red", ""},
		{"vehicles:body", "vehicles:engine", "vehicles:body"},
		{"vehicles:wheel", "default:steel_ingot", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:geep_spawner",
	recipe = {
		{"", "", ""},
		{"", "vehicles:engine", ""},
		{"vehicles:wheel", "vehicles:armor", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:ambulance_spawner",
	recipe = {
		{"", "", ""},
		{"vehicles:body", "vehicles:body", "dye:white"},
		{"vehicles:wheel", "vehicles:engine", "vehicles:wheel"}
	}
})

minetest.register_craft({
	output = "vehicles:assaultsuit_spawner",
	recipe = {
		{"vehicles:gun", "default:glass", "vehicles:armor"},
		{"", "vehicles:engine", ""},
		{"vehicles:armor", "", "vehicles:armor"}
	}
})


minetest.register_craft({
	output = "vehicles:backpack",
	recipe = {
		{"group:grass", "group:grass", "group:grass"},
		{"group:stick", "", "group:stick"},
		{"", "group:wood", ""}
	}
})





--decorative nodes

if minetest.settings:get("vehicles_nodes") == nil then
minetest.settings:set("vehicles_nodes", "true")
end

if minetest.settings:get("vehicles_nodes") then
function vehicles.register_simplenode(name, desc, texture, light)
minetest.register_node("vehicles:"..name, {
	description = desc,
	tiles = {texture},
	groups = {cracky=1},
	paramtype2 = "facedir",
	light_source = light,
	sound = default.node_sound_stone_defaults(),
})
end--function vehicles.register_simplenode(name, desc, texture, light)

vehicles.register_simplenode("road", S("Road surface"), "vehicles_road.png", 0)
vehicles.register_simplenode("concrete", S("Concrete"), "vehicles_concrete.png", 0)
vehicles.register_simplenode("arrows", S("Turning Arrows(left)"), "vehicles_arrows.png", 10)
vehicles.register_simplenode("arrows_flp", S("Turning Arrows(right)"), "vehicles_arrows_flp.png", 10)
vehicles.register_simplenode("checker", S("Checkered surface"), "vehicles_checker.png", 0)
vehicles.register_simplenode("stripe", S("Road surface (stripe)"), "vehicles_road_stripe.png", 0)
vehicles.register_simplenode("stripe2", S("Road surface (double stripe)"), "vehicles_road_stripe2.png", 0)
vehicles.register_simplenode("stripe3", S("Road surface (white stripes)"), "vehicles_road_stripes3.png", 0)
vehicles.register_simplenode("stripe4", S("Road surface (yellow stripes)"), "vehicles_road_stripe4.png", 0)
vehicles.register_simplenode("window", S("Building glass"), "vehicles_window.png", 0)
vehicles.register_simplenode("stripes", S("Hazard stipes"), "vehicles_stripes.png", 10)

minetest.register_node("vehicles:lights", {
	description = S("Tunnel Lights"),
	tiles = {"vehicles_lights_top.png", "vehicles_lights_top.png", "vehicles_lights.png", "vehicles_lights.png", "vehicles_lights.png", "vehicles_lights.png"},
	groups = {cracky=1},
	paramtype2 = "facedir",
	light_source = 14,
})

if minetest.get_modpath("stairs") then
stairs.register_stair_and_slab("road_surface", "vehicles:road",
		{cracky = 1},
		{"vehicles_road.png"},
		S("Road Surface Stair"),
		S("Road Surface Slab"),
		default.node_sound_stone_defaults())
end

minetest.register_node("vehicles:neon_arrow", {
	description = S("neon arrows (left)"),
	drawtype = "signlike",
	visual_scale = 2.0,
	tiles = {{
		name = "vehicles_neon_arrow.png",
		animation = {type = "vertical_frames", aspect_w = 32, aspect_h = 32, length = 1.00},
	}},
	inventory_image = "vehicles_neon_arrow_inv.png",
	weild_image = "vehicles_neon_arrow_inv.png",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,	
	light_source = 14,
	walkable = false,
	is_ground_content = true,
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})

minetest.register_node("vehicles:neon_arrow_flp", {
	description = S("neon arrows (right)"),
	drawtype = "signlike",
	visual_scale = 2.0,
	tiles = {{
		name = "vehicles_neon_arrow.png^[transformFX",
		animation = {type = "vertical_frames", aspect_w = 32, aspect_h = 32, length = 1.00},
	}},
	inventory_image = "vehicles_neon_arrow_inv.png^[transformFX",
	weild_image = "vehicles_neon_arrow_inv.png^[transformFX",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,	
	light_source = 14,
	walkable = false,
	is_ground_content = true,
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})

minetest.register_node("vehicles:add_arrow", {
	description = S("arrows(left)"),
	drawtype = "signlike",
	visual_scale = 2.0,
	tiles = {"vehicles_arrows.png"},
	inventory_image = "vehicles_arrows.png",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,	
	light_source = 14,
	walkable = false,
	is_ground_content = true,
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})

minetest.register_node("vehicles:add_arrow_flp", {
	description = S("arrows(right)"),
	drawtype = "signlike",
	visual_scale = 2.0,
	tiles = {"vehicles_arrows_flp.png"},
	inventory_image = "vehicles_arrows_flp.png",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,	
	light_source = 14,
	walkable = false,
	is_ground_content = true,
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})

minetest.register_node("vehicles:scifi_ad", {
	description = S("scifi_nodes sign"),
	drawtype = "signlike",
	visual_scale = 3.0,
	tiles = {{
		name = "vehicles_scifinodes.png",
		animation = {type = "vertical_frames", aspect_w = 58, aspect_h = 58, length = 1.00},
	}},
	inventory_image = "vehicles_scifinodes_inv.png",
	weild_image = "vehicles_scifinodes_inv.png",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,	
	light_source = 14,
	walkable = false,
	is_ground_content = true,
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})

minetest.register_node("vehicles:mt_sign", {
	description = S("mt sign"),
	drawtype = "signlike",
	visual_scale = 3.0,
	tiles = {"vehicles_neonmt.png",},
	inventory_image = "vehicles_neonmt.png",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,	
	light_source = 14,
	walkable = false,
	is_ground_content = true,
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})

minetest.register_node("vehicles:pacman_sign", {
	description = S("pacman sign"),
	drawtype = "signlike",
	visual_scale = 2.0,
	tiles = {"vehicles_pacman.png",},
	inventory_image = "vehicles_pacman.png",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,	
	light_source = 14,
	walkable = false,
	is_ground_content = true,
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})

minetest.register_node("vehicles:whee_sign", {
	description = S("whee sign"),
	drawtype = "signlike",
	visual_scale = 3.0,
	tiles = {"vehicles_whee.png",},
	inventory_image = "vehicles_whee.png",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,	
	light_source = 14,
	walkable = false,
	is_ground_content = true,
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})

minetest.register_node("vehicles:checker_sign", {
	description = S("Checkered sign"),
	drawtype = "signlike",
	visual_scale = 3.0,
	tiles = {"vehicles_checker2.png",},
	inventory_image = "vehicles_checker2.png",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	light_source = 5,
	is_ground_content = true,
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})

minetest.register_node("vehicles:car_sign", {
	description = S("Car sign"),
	drawtype = "signlike",
	visual_scale = 3.0,
	tiles = {"vehicles_sign1.png",},
	inventory_image = "vehicles_sign1.png",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	light_source = 5,
	is_ground_content = true,
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})

minetest.register_node("vehicles:nyan_sign", {
	description = S("Nyancat sign"),
	drawtype = "signlike",
	visual_scale = 2.0,
	tiles = {"vehicles_sign2.png",},
	inventory_image = "vehicles_sign2.png",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	light_source = 5,
	is_ground_content = true,
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})

minetest.register_node("vehicles:flag", {
	description = S("Flag"),
	drawtype = "torchlike",
	visual_scale = 3.0,
	tiles = {"vehicles_flag.png",},
	inventory_image = "vehicles_flag.png",
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	light_source = 5,
	is_ground_content = true,
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
	},
	groups = {cracky=3,dig_immediate=3},
})


minetest.register_node("vehicles:tyres", {
	description = S("tyre stack"),
	tiles = {
		"vehicles_tyre.png",
		"vehicles_tyre.png",
		"vehicles_tyre_side.png",
		"vehicles_tyre_side.png",
		"vehicles_tyre_side.png",
		"vehicles_tyre_side.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -0.5, -0.4375, 0.4375, 0.5, 0.4375}, -- NodeBox1
			{-0.5, -0.4375, -0.4375, 0.5, -0.0625, 0.4375}, -- NodeBox2
			{-0.5, 0, -0.4375, 0.5, 0.4375, 0.4375}, -- NodeBox3
			{-0.4375, 0, -0.5, 0.4375, 0.4375, 0.5}, -- NodeBox4
			{-0.4375, -0.4375, -0.5, 0.4375, -0.0625, 0.5}, -- NodeBox5
		}
	},
	groups = {cracky=1, falling_node=1},
})

--nodeboxes from xpanes 
--[[
(MIT)
Copyright (C) 2014-2016 xyz
Copyright (C) 2014-2016 BlockMen
Copyright (C) 2016 Auke Kok <sofar@foo-projects.org>
Copyright (C) 2014-2016 Various Minetest developers
]]

minetest.register_node("vehicles:light_barrier", {
	description = S("Light Barrier"),
	tiles = {
	"vehicles_lightblock.png^[transformR90",
	"vehicles_lightblock.png^[transformR90",
	"vehicles_lightblock.png",
	},
	use_texture_alpha = true,
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
			type = "connected",
			fixed = {{-1/32, -1/2, -1/32, 1/32, 1/2, 1/32}},
			connect_front = {{-1/32, -1/2, -1/2, 1/32, 1/2, -1/32}},
			connect_left = {{-1/2, -1/2, -1/32, -1/32, 1/2, 1/32}},
			connect_back = {{-1/32, -1/2, 1/32, 1/32, 1/2, 1/2}},
			connect_right = {{1/32, -1/2, -1/32, 1/2, 1/2, 1/32}},
	},
	connects_to = {"vehicles:light_barrier",},
	sunlight_propagates = true,
	walkable = false,
	light_source = 9,
	groups = {cracky=3,dig_immediate=3,not_in_creative_inventory=1},
	on_construct = function(pos, node)
			minetest.get_node_timer(pos):start(4)
		return
	end,
	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
	end,
})

minetest.register_node("vehicles:light_barrier2", {
	description = S("Light Barrier 2"),
	tiles = {
	"vehicles_lightblock2.png^[transformR90",
	"vehicles_lightblock2.png^[transformR90",
	"vehicles_lightblock2.png",
	},
	use_texture_alpha = true,
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
			type = "connected",
			fixed = {{-1/32, -1/2, -1/32, 1/32, 1/2, 1/32}},
			connect_front = {{-1/32, -1/2, -1/2, 1/32, 1/2, -1/32}},
			connect_left = {{-1/2, -1/2, -1/32, -1/32, 1/2, 1/32}},
			connect_back = {{-1/32, -1/2, 1/32, 1/32, 1/2, 1/2}},
			connect_right = {{1/32, -1/2, -1/32, 1/2, 1/2, 1/32}},
	},
	connects_to = {"vehicles:light_barrier2",},
	sunlight_propagates = true,
	walkable = false,
	light_source = 9,
	groups = {cracky=3,dig_immediate=3,not_in_creative_inventory=1},
	on_construct = function(pos, node)
			minetest.get_node_timer(pos):start(4)
		return
	end,
	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
	end,
})


end--if minetest.setting_get("vehicles_nodes") then

end--if enable_built_in then
