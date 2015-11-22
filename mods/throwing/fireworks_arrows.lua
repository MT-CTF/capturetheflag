local function throwing_register_fireworks(color, desc)
	minetest.register_craftitem("throwing:arrow_fireworks_" .. color, {
		description = desc .. "fireworks arrow",
		inventory_image = "throwing_arrow_fireworks_" .. color .. ".png",
	})
	
	minetest.register_node("throwing:arrow_fireworks_" .. color .. "_box", {
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				-- Shaft
				{-6.5/17, -1.5/17, -1.5/17, 6.5/17, 1.5/17, 1.5/17},
				--Spitze
				{-4.5/17, 2.5/17, 2.5/17, -3.5/17, -2.5/17, -2.5/17},
				{-8.5/17, 0.5/17, 0.5/17, -6.5/17, -0.5/17, -0.5/17},
				--Federn
				{6.5/17, 1.5/17, 1.5/17, 7.5/17, 2.5/17, 2.5/17},
				{7.5/17, -2.5/17, 2.5/17, 6.5/17, -1.5/17, 1.5/17},
				{7.5/17, 2.5/17, -2.5/17, 6.5/17, 1.5/17, -1.5/17},
				{6.5/17, -1.5/17, -1.5/17, 7.5/17, -2.5/17, -2.5/17},
				
				{7.5/17, 2.5/17, 2.5/17, 8.5/17, 3.5/17, 3.5/17},
				{8.5/17, -3.5/17, 3.5/17, 7.5/17, -2.5/17, 2.5/17},
				{8.5/17, 3.5/17, -3.5/17, 7.5/17, 2.5/17, -2.5/17},
				{7.5/17, -2.5/17, -2.5/17, 8.5/17, -3.5/17, -3.5/17},
			}
		},
		tiles = {"throwing_arrow_fireworks_" .. color .. ".png", "throwing_arrow_fireworks_" .. color .. ".png", "throwing_arrow_fireworks_" .. color .. "_back.png", "throwing_arrow_fireworks_" .. color .. "_front.png", "throwing_arrow_fireworks_" .. color .. "_2.png", "throwing_arrow_fireworks_" .. color .. ".png"},
		groups = {not_in_creative_inventory=1},
	})
	
	local THROWING_ARROW_ENTITY={
		physical = false,
		timer=0,
		visual = "wielditem",
		visual_size = {x=0.1, y=0.1},
		textures = {"throwing:arrow_fireworks_" .. color .. "_box"},
		lastpos={},
		collisionbox = {0,0,0,0,0,0},
	}
	
	local radius = 0.5
	
	local function add_effects(pos, radius)
		minetest.add_particlespawner({
			amount = 256,
			time = 0.2,
			minpos = vector.subtract(pos, radius / 2),
			maxpos = vector.add(pos, radius / 2),
			minvel = {x=-5, y=-5, z=-5},
			maxvel = {x=5,  y=5,  z=5},
			minacc = {x=0, y=-8, z=0},
			--~ maxacc = {x=-20, y=-50, z=-50},
			minexptime = 2.5,
			maxexptime = 3,
			minsize = 1,
			maxsize = 2.5,
			texture = "throwing_sparkle_" .. color .. ".png",
		})
	end
	
	
	local function boom(pos)
		minetest.sound_play("throwing_firework_boom", {pos=pos, gain=1, max_hear_distance=2*64})
		if minetest.get_node(pos).name == 'air' or minetest.get_node(pos).name == 'throwing:firework_trail' then
			minetest.add_node(pos, {name="throwing:firework_boom"})
			minetest.get_node_timer(pos):start(0.2)
		end
		add_effects(pos, radius)
	end
	
	-- Back to the arrow
	
	THROWING_ARROW_ENTITY.on_step = function(self, dtime)
		self.timer=self.timer+dtime
		local pos = self.object:getpos()
		local node = minetest.get_node(pos)
		if self.timer < 0.07 then
			minetest.sound_play("throwing_firework_launch", {pos=pos, gain=0.8, max_hear_distance=2*64})
		end
		minetest.add_particlespawner({
			amount = 16,
			time = 0.1,
			minpos = pos,
			maxpos = pos,
			minvel = {x=-5, y=-5, z=-5},
			maxvel = {x=5,  y=5,  z=5},
			minacc = vector.new(),
			maxacc = vector.new(),
			minexptime = 0.3,
			maxexptime = 0.5,
			minsize = 0.5,
			maxsize = 1,
			texture = "throwing_sparkle.png",
		})
		if self.timer>0.2 then
			local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 2)
			for k, obj in pairs(objs) do
				if obj:get_luaentity() ~= nil then
					if obj:get_luaentity().name ~= "throwing:arrow_fireworks_" .. color .. "_entity" and obj:get_luaentity().name ~= "__builtin:item" then
						local damage = 2
						obj:punch(self.object, 1.0, {
							full_punch_interval=1.0,
							damage_groups={fleshy=damage},
						}, nil)
						self.object:remove()
						boom(pos)
					end
				end
			end
		end
		if self.timer > 2 then
			self.object:remove()
			boom(self.lastpos)
		end
		if self.lastpos.x~=nil then
			if node.name ~= "air" and node.name ~= "throwing:firework_trail" then
				self.object:remove()
				boom(self.lastpos)
			end
		end
		if node.name == 'air' then
			minetest.add_node(pos, {name="throwing:firework_trail"})
			minetest.get_node_timer(pos):start(0.1)
		end
		self.lastpos={x=pos.x, y=pos.y, z=pos.z}
	end
	
	minetest.register_entity("throwing:arrow_fireworks_" .. color .. "_entity", THROWING_ARROW_ENTITY)
	
	minetest.register_craft({
		output = 'throwing:arrow_fireworks_' .. color .. ' 8',
		recipe = {
			{'default:stick', 'tnt:gunpowder', 'dye:' .. color},
		}
	})
	
	minetest.register_craft({
		output = 'throwing:arrow_fireworks_' .. color .. ' 8',
		recipe = {
			{'dye:' .. color, 'tnt:gunpowder', 'default:stick'},
		}
	})
end

--~ Arrows

if not DISABLE_FIREWORKS_BLUE_ARROW then
	throwing_register_fireworks('blue', 'Blue')
end

if not DISABLE_FIREWORKS_RED_ARROW then
	throwing_register_fireworks('red', 'Red')
end

--~ Nodes

minetest.register_node("throwing:firework_trail", {
	drawtype = "airlike",
	light_source = 9,
	walkable = false,
	drop = "",
	groups = {dig_immediate=3},
	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
	end,
})

minetest.register_node("throwing:firework_boom", {
	drawtype = "plantlike",
	tiles = {"throwing_sparkle.png"},
	light_source = default.LIGHT_MAX,
	walkable = false,
	drop = "",
	groups = {dig_immediate=3},
	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
	end,
	after_destruct = function(pos, oldnode)
		minetest.set_node(pos, {name="throwing:firework_light"})
		minetest.get_node_timer(pos):start(3)
	end,
})

minetest.register_node("throwing:firework_light", {
	drawtype = "airlike",
	light_source = default.LIGHT_MAX,
	walkable = false,
	drop = "",
	groups = {dig_immediate=3},
	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
	end,
})
