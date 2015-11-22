minetest.register_craftitem("throwing:arrow_torch", {
	description = "Torch Arrow",
	inventory_image = "throwing_arrow_torch.png",
})

minetest.register_node("throwing:arrow_torch_box", {
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
	tiles = {"throwing_arrow_torch.png", "throwing_arrow_torch.png", "throwing_arrow_torch_back.png", "throwing_arrow_torch_front.png", "throwing_arrow_torch_2.png", "throwing_arrow_torch.png"},
	groups = {not_in_creative_inventory=1},
})

local THROWING_ARROW_ENTITY={
	physical = false,
	timer=0,
	visual = "wielditem",
	visual_size = {x=0.1, y=0.1},
	textures = {"throwing:arrow_torch_box"},
	lastpos={},
	collisionbox = {0,0,0,0,0,0},
	node = "",
}

THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)

	if self.timer>0.2 then
		local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 0.5)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= "throwing:arrow_torch_entity" and obj:get_luaentity().name ~= "__builtin:item" then
					local damage = 0.5
					obj:punch(self.object, 1.0, {
						full_punch_interval=1.0,
						damage_groups={fleshy=damage},
					}, nil)
					self.object:remove()
					local toughness = 0.9
					if math.random() < toughness then
						minetest.add_item(self.lastpos, 'throwing:arrow_torch')
					else
						minetest.add_item(self.lastpos, 'default:stick')
					end
				end
			end
		end
	end

	if self.lastpos.x~=nil then
		if node.name == 'air' then
			minetest.add_node(pos, {name="throwing:torch_trail"})
			minetest.get_node_timer(pos):start(0.1)
		elseif node.name ~= "air" and not string.find(node.name, "trail") then
			self.object:remove()
			if not string.find(node.name, "water") and not string.find(node.name, "lava") and not string.find(node.name, "torch") then
				local dir=vector.direction(self.lastpos, pos)
				local wall=minetest.dir_to_wallmounted(dir)
				minetest.add_node(self.lastpos, {name="default:torch", param2 = wall})
			else
				local toughness = 0.9
				if math.random() < toughness then
					minetest.add_item(self.lastpos, 'throwing:arrow_torch')
				else
					minetest.add_item(self.lastpos, 'default:stick')
				end
			end
		end
	end
	self.lastpos={x=pos.x, y=pos.y, z=pos.z}
end

minetest.register_entity("throwing:arrow_torch_entity", THROWING_ARROW_ENTITY)

minetest.register_craft({
	output = 'throwing:arrow_torch 4',
	recipe = {
		{'default:stick', 'default:stick', 'group:coal'},
	}
})

minetest.register_craft({
	output = 'throwing:arrow_torch 4',
	recipe = {
		{'group:coal', 'default:stick', 'default:stick'},
	}
})

minetest.register_node("throwing:torch_trail", {
	drawtype = "airlike",
	light_source = default.LIGHT_MAX-1,
	walkable = false,
	drop = "",
	groups = {dig_immediate=3},
	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
	end,
})
