SHOOTER_CROSSBOW_USES = 50
SHOOTER_ARROW_TOOL_CAPS = {damage_groups={fleshy=2}}
SHOOTER_ARROW_LIFETIME = 180 -- 3 minutes

minetest.register_alias("shooter:arrow", "shooter:arrow_white")
minetest.register_alias("shooter:crossbow_loaded", "shooter:crossbow_loaded_white")

local dye_basecolors = (dye and dye.basecolors) or
		{"white", "grey", "black", "red", "yellow", "green", "cyan", "blue", "magenta"}

local function get_animation_frame(dir)
	local angle = math.atan(dir.y)
	local frame = 90 - math.floor(angle * 360 / math.pi)
	if frame < 1 then
		frame = 1
	elseif frame > 180 then
		frame = 180
	end
	return frame
end

local function get_target_pos(p1, p2, dir, offset)
	local d = vector.distance(p1, p2) - offset
	local td = vector.multiply(dir, {x=d, y=d, z=d})
	return vector.add(p1, td)
end

-- name is the overlay texture name, colour is used to select the wool texture
local function get_texture(name, colour)
	return "shooter_"..name..".png^wool_"..colour..".png^shooter_"..name..".png^[makealpha:255,126,126"
end

minetest.register_entity("shooter:arrow_entity", {
	physical = false,
	visual = "mesh",
	mesh = "shooter_arrow.b3d",
	visual_size = {x=1, y=1},
	textures = {
		get_texture("arrow_uv", "white"),
	},
	color = "white",
	timer = 0,
	lifetime = SHOOTER_ARROW_LIFETIME,
	player = nil,
	state = "init",
	node_pos = nil,
	collisionbox = {0,0,0, 0,0,0},
	stop = function(self, pos)
		local acceleration = {x=0, y=-10, z=0}
		if self.state == "stuck" then
			pos = pos or self.object:getpos()
			acceleration = {x=0, y=0, z=0}
		end
		if pos then
			self.object:moveto(pos)
		end
		self.object:set_properties({
			physical = true,
			collisionbox = {-1/8,-1/8,-1/8, 1/8,1/8,1/8},
		})
		self.object:setvelocity({x=0, y=0, z=0})
		self.object:setacceleration(acceleration)
	end,
	strike = function(self, object)
		local puncher = self.player
		if puncher and shooter:is_valid_object(object) then
			if puncher ~= object then
				local dir = puncher:get_look_dir()
				local p1 = puncher:getpos()
				local p2 = object:getpos()
				local tpos = get_target_pos(p1, p2, dir, 0)
				shooter:spawn_particles(tpos, SHOOTER_EXPLOSION_TEXTURE)
				object:punch(puncher, nil, SHOOTER_ARROW_TOOL_CAPS, dir)
			end
		end
		self:stop(object:getpos())
	end,
	on_activate = function(self, staticdata)
		self.object:set_armor_groups({immortal=1})
		if staticdata == "expired" then
			self.object:remove()
		end
	end,
	on_punch = function(self, puncher)
		if puncher then
			if puncher:is_player() then
				local stack = "shooter:arrow_"..self.color
				local inv = puncher:get_inventory()
				if inv:room_for_item("main", stack) then
					inv:add_item("main", stack)
					self.object:remove()
				end
			end
		end
	end,
	on_step = function(self, dtime)
		if self.state == "init" then
			return
		end
		self.timer = self.timer + dtime
		self.lifetime = self.lifetime - dtime
		if self.lifetime < 0 then
			self.object:remove()
			return
		elseif self.state == "dropped" then
			return
		elseif self.state == "stuck" then
			if self.timer > 1 then
				if self.node_pos then
					local node = minetest.get_node(self.node_pos)
					if node.name then
						local item = minetest.registered_items[node.name]
						if item then
							if not item.walkable then
								self.state = "dropped"
								self:stop()
								return
							end
						end
					end
				end
				self.timer = 0
			end
			return
		end
		if self.timer > 0.2 then
			local pos = self.object:getpos()
			local dir = vector.normalize(self.object:getvelocity())
			local frame = get_animation_frame(dir)
			self.object:set_animation({x=frame, y=frame}, 0)
			local objects = minetest.get_objects_inside_radius(pos, 5)
			for _,obj in ipairs(objects) do
				if shooter:is_valid_object(obj) and obj ~= self.player then
					local collisionbox = {-0.25,-1.0,-0.25, 0.25,0.8,0.25}
					local offset = SHOOTER_PLAYER_OFFSET
					if not obj:is_player() then
						offset = SHOOTER_ENTITY_OFFSET
						local ent = obj:get_luaentity()
						if ent then
							local def = minetest.registered_entities[ent.name]
							collisionbox = def.collisionbox or collisionbox
						end
					end
					local opos = vector.add(obj:getpos(), offset)
					local ray = {pos=pos, dir=dir}
					local plane = {pos=opos, normal={x=-1, y=0, z=-1}}
					local ipos = shooter:get_intersect_pos(ray, plane, collisionbox)
					if ipos then
						self:strike(obj)
					end
				end
			end
			local p = vector.add(pos, vector.multiply(dir, {x=5, y=5, z=5}))
			local _, npos = minetest.line_of_sight(pos, p, 1)
			if npos then
				local node = minetest.get_node(npos)
				local tpos = get_target_pos(pos, npos, dir, 0.66)
				self.node_pos = npos
				self.state = "stuck"
				self:stop(tpos)
				shooter:play_node_sound(node, npos)
			end
			self.timer = 0
		end
	end,
	get_staticdata = function(self)
		return "expired"
	end,
})

for _, color in pairs(dye_basecolors) do
	minetest.register_craftitem("shooter:arrow_"..color, {
		description = color:gsub("%a", string.upper, 1).." Arrow",
		inventory_image = get_texture("arrow_inv", color),
	})
	minetest.register_tool("shooter:crossbow_loaded_"..color, {
		description = "Crossbow",
		inventory_image = get_texture("crossbow_loaded", color),
		groups = {not_in_creative_inventory=1},
		on_use = function(itemstack, user, pointed_thing)
			minetest.sound_play("shooter_click", {object=user})
			if not minetest.setting_getbool("creative_mode") then
				itemstack:add_wear(65535/SHOOTER_CROSSBOW_USES)
			end
			itemstack = "shooter:crossbow 1 "..itemstack:get_wear()
			local pos = user:getpos()
			local dir = user:get_look_dir()
			local yaw = user:get_look_yaw()
			if pos and dir and yaw then
				pos.y = pos.y + 1.5
				local obj = minetest.add_entity(pos, "shooter:arrow_entity")
				local ent = nil
				if obj then
					ent = obj:get_luaentity()
				end
				if ent then
					ent.player = ent.player or user
					ent.state = "flight"
					ent.color = color
					obj:set_properties({
						textures = {get_texture("arrow_uv", color)}
					})
					minetest.sound_play("shooter_throw", {object=obj}) 
					local frame = get_animation_frame(dir)
					obj:setyaw(yaw + math.pi)
					obj:set_animation({x=frame, y=frame}, 0)
					obj:setvelocity({x=dir.x * 14, y=dir.y * 14, z=dir.z * 14})
					if pointed_thing.type ~= "nothing" then
						local ppos = minetest.get_pointed_thing_position(pointed_thing, false)
						local _, npos = minetest.line_of_sight(pos, ppos, 1)
						if npos then
							ppos = npos
							pointed_thing.type = "node"
						end
						if pointed_thing.type == "object" then
							ent:strike(pointed_thing.ref)
							return itemstack
						elseif pointed_thing.type == "node" then
							local node = minetest.get_node(ppos)
							local tpos = get_target_pos(pos, ppos, dir, 0.66)
							minetest.after(0.2, function(object, pos, npos)
								ent.node_pos = npos
								ent.state = "stuck"
								ent:stop(pos)
								shooter:play_node_sound(node, npos)
							end, obj, tpos, ppos)
							return itemstack
						end
					end
					obj:setacceleration({x=dir.x * -3, y=-5, z=dir.z * -3})
				end
			end
			return itemstack
		end,
	})
end

minetest.register_tool("shooter:crossbow", {
	description = "Crossbow",
	inventory_image = "shooter_crossbow.png",
	on_use = function(itemstack, user, pointed_thing)
		local inv = user:get_inventory()
		local stack = inv:get_stack("main", user:get_wield_index() + 1)
		local color = string.match(stack:get_name(), "shooter:arrow_(%a+)")
		if color then
			minetest.sound_play("shooter_reload", {object=user})
			if not minetest.setting_getbool("creative_mode") then
				inv:remove_item("main", "shooter:arrow_"..color.." 1")
			end
			return "shooter:crossbow_loaded_"..color.." 1 "..itemstack:get_wear()
		end
		for _, color in pairs(dye_basecolors) do
			if inv:contains_item("main", "shooter:arrow_"..color) then
				minetest.sound_play("shooter_reload", {object=user})
				if not minetest.setting_getbool("creative_mode") then
					inv:remove_item("main", "shooter:arrow_"..color.." 1")
				end
				return "shooter:crossbow_loaded_"..color.." 1 "..itemstack:get_wear()
			end
		end
		minetest.sound_play("shooter_click", {object=user})
	end,
})

if SHOOTER_ENABLE_CRAFTING == true then
	minetest.register_craft({
		output = "shooter:crossbow",
		recipe = {
			{"default:stick", "default:stick", "default:stick"},
			{"default:stick", "default:stick", ""},
			{"default:stick", "", "default:bronze_ingot"},
		},
	})
	minetest.register_craft({
		output = "shooter:arrow_white",
		recipe = {
			{"default:steel_ingot", "", ""},
			{"", "default:stick", "default:paper"},
			{"", "default:paper", "default:stick"},
		},
	})
	for _, color in pairs(dye_basecolors) do
		if color ~= "white" then
			minetest.register_craft({
				output = "shooter:arrow_"..color,
				recipe = {
					{"", "dye:"..color, "shooter:arrow_white"},
				},
			})
		end
	end
end

