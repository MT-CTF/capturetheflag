minetest.register_craftitem("throwing:arrow_shell", {
	description = "Shell arrow",
	inventory_image = "throwing_arrow_shell.png",
})

minetest.register_node("throwing:arrow_shell_box", {
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
	tiles = {"throwing_arrow_shell.png", "throwing_arrow_shell.png", "throwing_arrow_shell_back.png", "throwing_arrow_shell_front.png", "throwing_arrow_shell_2.png", "throwing_arrow_shell.png"},
	groups = {not_in_creative_inventory=1},
})

local THROWING_ARROW_ENTITY={
	physical = false,
	timer=0,
	visual = "wielditem",
	visual_size = {x=0.1, y=0.1},
	textures = {"throwing:arrow_shell_box"},
	lastpos={},
	collisionbox = {0,0,0,0,0,0},
}

local radius = 1

local function add_effects(pos, radius)
	minetest.add_particlespawner({
		amount = 8,
		time = 0.5,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x=-10, y=-10, z=-10},
		maxvel = {x=10,  y=10,  z=10},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 0.5,
		maxsize = 1,
		texture = "tnt_smoke.png",
	})
end


local function boom(pos)
	minetest.sound_play("shell_explode", {pos=pos, gain=1.5, max_hear_distance=2*64})
	minetest.set_node(pos, {name="tnt:boom"})
	minetest.get_node_timer(pos):start(0.1)
	add_effects(pos, radius)
end

-- Back to the arrow

THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)

	if self.timer>0.2 then
		local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 2)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= "throwing:arrow_shell_entity" and obj:get_luaentity().name ~= "__builtin:item" then
					local speed = vector.length(self.object:getvelocity())
					local damage = ((speed + 5)^1.2)/10 + 12
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

	if self.lastpos.x~=nil then
		if node.name ~= "air" and not (string.find(node.name, 'grass') and not string.find(node.name, 'dirt')) and not string.find(node.name, 'flowers:') and not string.find(node.name, 'farming:') then
			self.object:remove()
			boom(self.lastpos)
		end
	end
	self.lastpos={x=pos.x, y=pos.y, z=pos.z}
end

minetest.register_entity("throwing:arrow_shell_entity", THROWING_ARROW_ENTITY)

minetest.register_craft({
	output = 'throwing:arrow_shell 8',
	recipe = {
		{'default:stick', 'tnt:gunpowder', 'default:bronze_ingot'},
	}
})

minetest.register_craft({
	output = 'throwing:arrow_shell 8',
	recipe = {
		{'default:bronze_ingot', 'tnt:gunpowder', 'default:stick'},
	}
})
