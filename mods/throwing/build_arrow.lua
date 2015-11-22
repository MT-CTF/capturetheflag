minetest.register_craftitem("throwing:arrow_build", {
	description = "Build Arrow",
	inventory_image = "throwing_arrow_build.png",
})

minetest.register_node("throwing:arrow_build_box", {
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
	tiles = {"throwing_arrow_build.png", "throwing_arrow_build.png", "throwing_arrow_build_back.png", "throwing_arrow_build_front.png", "throwing_arrow_build_2.png", "throwing_arrow_build.png"},
	groups = {not_in_creative_inventory=1},
})

local THROWING_ARROW_ENTITY={
	physical = false,
	timer=0,
	visual = "wielditem",
	visual_size = {x=0.1, y=0.1},
	textures = {"throwing:arrow_build_box"},
	lastpos={},
	collisionbox = {0,0,0,0,0,0},
	node = "",
}

THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)
	if not self.inventory or not self.stack then
		self.object:remove()
	end

	if self.timer>0.2 then
		local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 1)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= "throwing:arrow_build_entity" and obj:get_luaentity().name ~= "__builtin:item" then
					self.object:remove()
					if self.inventory and self.stack and not minetest.setting_getbool("creative_mode") then
						self.inventory:remove_item("main", {name=self.stack:get_name()})
					end
					if self.stack then
						minetest.add_item(self.lastpos, {name=self.stack:get_name()})
					end
					local toughness = 0.95
					if math.random() < toughness then
						minetest.add_item(self.lastpos, 'throwing:arrow_build')
					else
						minetest.add_item(self.lastpos, 'default:stick')
					end
				end
			end
		end
	end

	if self.lastpos.x~=nil then
		if node.name ~= "air" then
			self.object:remove()
			if self.inventory and self.stack and not minetest.setting_getbool("creative_mode") then
					self.inventory:remove_item("main", {name=self.stack:get_name()})
			end
			if self.stack then
				if not string.find(node.name, "water") and not string.find(node.name, "lava") and not string.find(node.name, "torch") and self.stack:get_definition().type == "node" and self.stack:get_name() ~= "default:torch" then
					minetest.place_node(self.lastpos, {name=self.stack:get_name()})
				else
					minetest.add_item(self.lastpos, {name=self.stack:get_name()})
				end
			end
			minetest.add_item(self.lastpos, 'default:shovel_steel')
		end
	end
	self.lastpos={x=pos.x, y=pos.y, z=pos.z}
end

minetest.register_entity("throwing:arrow_build_entity", THROWING_ARROW_ENTITY)

minetest.register_craft({
	output = 'throwing:arrow_build',
	recipe = {
		{'default:stick', 'default:stick', 'default:shovel_steel'},
	}
})

minetest.register_craft({
	output = 'throwing:arrow_build',
	recipe = {
		{'default:shovel_steel', 'default:stick', 'default:stick'},
	}
})
