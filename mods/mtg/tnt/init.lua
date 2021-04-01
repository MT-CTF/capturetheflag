tnt = {}

-- Fill a list with data for content IDs, after all nodes are registered
local cid_data = {}
minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_nodes) do
		cid_data[minetest.get_content_id(name)] = {
			name = name,
			drops = def.drops,
			flammable = def.groups.flammable,
			on_blast = def.on_blast,
		}
	end
end)

local function rand_pos(center, pos, radius)
	local def
	local reg_nodes = minetest.registered_nodes
	local i = 0
	repeat
		-- Give up and use the center if this takes too long
		if i > 4 then
			pos.x, pos.z = center.x, center.z
			break
		end
		pos.x = center.x + math.random(-radius, radius)
		pos.z = center.z + math.random(-radius, radius)
		def = reg_nodes[minetest.get_node(pos).name]
		i = i + 1
	until def and not def.walkable
end

local function eject_drops(drops, pos, radius)
	local drop_pos = vector.new(pos)
	for _, item in pairs(drops) do
		local count = math.min(item:get_count(), item:get_stack_max())
		while count > 0 do
			local take = math.max(1,math.min(radius * radius, count, item:get_stack_max()))
			rand_pos(pos, drop_pos, radius)
			local dropitem = ItemStack(item)
			dropitem:set_count(take)
			local obj = minetest.add_item(drop_pos, dropitem)
			if obj then
				obj:get_luaentity().collect = true
				obj:set_acceleration({x = 0, y = -10, z = 0})
				obj:set_velocity({x = math.random(-3, 3),
						y = math.random(0, 10),
						z = math.random(-3, 3)})
			end
			count = count - take
		end
	end
end

local function add_drop(drops, item)
	item = ItemStack(item)
	local name = item:get_name()
	local drop = drops[name]
	if drop == nil then
		drops[name] = item
	else
		drop:set_count(drop:get_count() + item:get_count())
	end
end

local function destroy(drops, npos, cid, c_air, on_blast_queue, owner)
	local def = cid_data[cid]

	if not def then
		return c_air
	elseif def.on_blast then
		on_blast_queue[#on_blast_queue + 1] = {
			pos = vector.new(npos),
			on_blast = def.on_blast
		}
		return cid
	else
		local node_drops = minetest.get_node_drops(def.name, "")
		for _, item in pairs(node_drops) do
			add_drop(drops, item)
		end
		return c_air
	end
end

local function entity_physics(pos, radius, drops, owner)
	local objs = minetest.get_objects_inside_radius(pos, radius)
	for _, obj in pairs(objs) do
		local obj_pos = obj:get_pos()
		local dist = math.max(1, vector.distance(pos, obj_pos))

		local damage = (4 / dist) * radius
		if obj:is_player() then
			-- Knock the player back 1 node, and slightly upwards
			local dir = vector.normalize(vector.subtract(obj_pos, pos))
			local moveoff = vector.multiply(dir, dist + 1.0)
			local newpos = vector.add(pos, moveoff)
			newpos.y = newpos.y + 0.2
			-- Only move the player if there is room. Otherwise double the damage given.
			if minetest.get_node(newpos).name == minetest.get_node({x = newpos.x, y = newpos.y+1, z = newpos.z}).name and string.match(minetest.get_node({x = newpos.x, y = newpos.y+1, z = newpos.z}).name, "air") then
				obj:set_pos(newpos)
			else
				damage = damage * 2
			end
			-- Don't hurt the player after it's already dead
			if obj:get_hp() > 0 then
				if owner and not string.match(owner:get_player_name(), obj:get_player_name()) then
					obj:punch(owner, damage, {damage_groups = {fleshy = damage, tnt = 1}})
				else
					obj:set_hp(obj:get_hp() - damage)
				end
			end
		end
	end
end

function tnt.burn(pos, nodename)
	local name = nodename or minetest.get_node(pos).name
	local def = minetest.registered_nodes[name]
	if not def then
		return
	elseif def.on_ignite then
		def.on_ignite(pos)
	elseif minetest.get_item_group(name, "tnt") > 0 then
		minetest.swap_node(pos, {name = name .. "_burning"})
		minetest.sound_play("tnt_ignite", {pos = pos}, true)
		minetest.get_node_timer(pos):start(1)
	end
end

local function tnt_explode(pos, radius, owner)
	pos = vector.round(pos)
	-- Look for & light other TNT nodes
	local vm1 = VoxelManip()
	local p1 = vector.subtract(pos, 2)
	local p2 = vector.add(pos, 2)
	local minp, maxp = vm1:read_from_map(p1, p2)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm1:get_data()
	local c_tnt = minetest.get_content_id("tnt:tnt")
	local c_tnt_burning = minetest.get_content_id("tnt:tnt_burning")
	local c_air = minetest.get_content_id("air")
	local other_tnt = {}

	for z = pos.z - radius, pos.z + radius do
		for y = pos.y - radius, pos.y + radius do
			for x = pos.x - radius, pos.x + radius do
				local vi = a:index(x, y, z)
				local cid = data[vi]
				if cid == c_tnt then
					data[vi] = c_tnt_burning
					table.insert(other_tnt, {x=x,y=y,z=z})
				end
			end
		end
	end

	vm1:set_data(data)
	vm1:write_to_map()

	for _, tnt_pos in pairs(other_tnt) do
		minetest.registered_nodes["tnt:tnt_burning"].on_construct(tnt_pos)
		local timer = minetest.get_node_timer(tnt_pos)
		timer:set(0.1, 0)
	end

	-- perform the explosion
	local vm = VoxelManip()
	local pr = PseudoRandom(os.time())
	p1 = vector.subtract(pos, radius)
	p2 = vector.add(pos, radius)
	minp, maxp = vm:read_from_map(p1, p2)
	a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	data = vm:get_data()

	local drops = {}
	local on_blast_queue = {}
	local on_construct_queue = {}
	local blocked_axis = {}
	local axis_quarters = {
		{ 1, 1, 1},
		{ 1, 1,-1},
		{ 1,-1, 1},
		{ 1,-1,-1},
		{-1, 1, 1},
		{-1, 1,-1},
		{-1,-1, 1},
		{-1,-1,-1}
	}

	-- Set an axis limit to prevent destroying through unbreakable blocks
	local axiz = {1,-1}
	local dims = {"x","y","z"}
	local axis_dirs = {{1,0,0},{0,1,0},{0,0,1}}

	-- three dimentions
	for c_dir, dim_dir in pairs(axis_dirs) do
		-- Positive and negitive
		for _, dim in pairs(axiz) do
			-- Go till the path is blocked
			for variable = 1 * dim, radius * dim, 1 * dim do
				local index = a:index(pos.x+ variable*dim_dir[1], pos.y+ variable*dim_dir[2], pos.z+ variable*dim_dir[3])
				if string.match(minetest.get_name_from_content_id(data[index]), "ctf_") then
					local blocked_dir = dims[c_dir]
					if variable < 0 then
						blocked_dir = "-"..blocked_dir
					else
						blocked_dir = "+"..blocked_dir
					end
					blocked_axis[blocked_dir] = variable
					break
				end
			end
		end
	end

	for _, i in pairs(axis_quarters) do
		local x_limit = radius * i[1]
		local y_limit = radius * i[2]
		local z_limit = radius * i[3]

		if x_limit > 0 and blocked_axis["+x"] then
			x_limit = blocked_axis["+x"]
		elseif x_limit < 0 and blocked_axis["-x"] then
			x_limit = blocked_axis["-x"]
		end
		if y_limit > 0 and blocked_axis["+y"] then
			y_limit = blocked_axis["+y"]
		elseif y_limit < 0 and blocked_axis["-y"] then
			y_limit = blocked_axis["-y"]
		end
		if z_limit > 0 and blocked_axis["+z"] then
			z_limit = blocked_axis["+z"]
		elseif z_limit < 0 and blocked_axis["-z"] then
			z_limit = blocked_axis["-z"]
		end
		for x = 0, x_limit, 1 * i[1] do
			for y = 0, y_limit, 1 * i[2] do
				for z = 0, z_limit, 1 * i[3] do
					local p = {x=pos.x+x, y=pos.y+y, z=pos.z+z}
					local r = vector.length(vector.new(x, y, z))
					if (radius * radius) / (r * r) >= (pr:next(80, 125) / 100) then
						local vi = a:index(p.x, p.y, p.z)
						local cid = data[vi]
						if not string.match(minetest.get_name_from_content_id(cid), "ctf_") and
							not string.match(minetest.get_name_from_content_id(cid), "tnt:") or
							string.match(minetest.get_name_from_content_id(cid), "ctf_map:reinforced_cobble") then
							if cid ~= c_air then
								data[vi] = destroy(drops, p, cid, c_air, on_blast_queue, owner)
							end
						elseif string.match(minetest.get_name_from_content_id(cid), "ctf_traps") then
							local tnt_owner = minetest.get_player_by_name(owner)
							if tnt_owner:get_hp() > 0 then
								minetest.registered_nodes["ctf_traps:damage_cobble"].on_dig(p, {name="ctf_traps:damage_cobble"}, tnt_owner)
								data[vi] = c_air
							end
						end
					end
				end
			end
		end
	end
	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
	vm:update_liquids()

	for _, queued_data in pairs(on_blast_queue) do
		local dist = math.max(1, vector.distance(queued_data.pos, pos))
		local intensity = (radius * radius) / (dist * dist)
		local node_drops = queued_data.on_blast(queued_data.pos, intensity)
		if node_drops then
			for _, item in pairs(node_drops) do
				add_drop(drops, item)
			end
		end
	end

	for _, queued_data in pairs(on_construct_queue) do
		queued_data.fn(queued_data.pos)
	end

	minetest.log("action","TNT owned by "..owner.." detonated at "..minetest.pos_to_string(pos).." with radius "..radius)

	return drops, radius
end

function tnt.boom(pos, def)
	def = def or {}
	def.radius = def.radius or 1
	def.damage_radius = def.radius * 2
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if not def.explode_center then
		minetest.set_node(pos, {name = "air"})
	end
	local sound = "tnt_explode"
	minetest.sound_play(sound, {pos = pos, gain = 2.5, max_hear_distance = math.min(def.radius * 20, 128)}, true)
	local drops, radius = tnt_explode(pos, def.radius, owner)
	local damage_radius = (radius / math.max(1, def.radius)) * def.damage_radius
	entity_physics(pos, damage_radius, drops, minetest.get_player_by_name(owner))
	if not def.disable_drops then
		eject_drops(drops, pos, radius)
	end
	minetest.log("action", "A TNT explosion occurred at "..minetest.pos_to_string(pos).." with radius "..radius)
end

minetest.register_node("tnt:gunpowder", {
	description = "Gun Powder",
	drawtype = "raillike",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	tiles = {
		"tnt_gunpowder_straight.png",
		"tnt_gunpowder_curved.png",
		"tnt_gunpowder_t_junction.png",
		"tnt_gunpowder_crossing.png"
	},
	inventory_image = "tnt_gunpowder_inventory.png",
	wield_image = "tnt_gunpowder_inventory.png",
	selection_box = {
		type = "fixed",
		fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
	},
	groups = {dig_immediate = 2, attached_node = 1, flammable = 5,
		connect_to_raillike = minetest.raillike_group("gunpowder")},
	sounds = default.node_sound_leaves_defaults(),

	on_punch = function(pos, node, puncher)
		if puncher:get_wielded_item():get_name() == "default:torch" then
			minetest.set_node(pos, {name = "tnt:gunpowder_burning"})
			minetest.log("action", puncher:get_player_name().." ignites tnt:gunpowder at "..minetest.pos_to_string(pos))
		end
	end,
	on_blast = function(pos, intensity)
		minetest.set_node(pos, {name = "tnt:gunpowder_burning"})
	end,
	on_burn = function(pos)
		minetest.set_node(pos, {name = "tnt:gunpowder_burning"})
	end,
	on_ignite = function(pos, igniter)
		minetest.set_node(pos, {name = "tnt:gunpowder_burning"})
	end
})

minetest.register_node("tnt:gunpowder_burning", {
	drawtype = "raillike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	light_source = 5,
	tiles = {{
		name = "tnt_gunpowder_burning_straight_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1,
		}
	},
	{
		name = "tnt_gunpowder_burning_curved_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1,
		}
	},
	{
		name = "tnt_gunpowder_burning_t_junction_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1,
		}
	},
	{
		name = "tnt_gunpowder_burning_crossing_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1,
		}
	}},
	selection_box = {
		type = "fixed",
		fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
	},
	drop = "",
	groups = {
		dig_immediate = 2,
		attached_node = 1,
		connect_to_raillike = minetest.raillike_group("gunpowder")
	},
	sounds = default.node_sound_leaves_defaults(),
	on_timer = function(pos, elapsed)
		for dx = -1, 1 do
			for dz = -1, 1 do
				if math.abs(dx) + math.abs(dz) == 1 then
					for dy = -1, 1 do
						tnt.burn({
							x = pos.x + dx,
							y = pos.y + dy,
							z = pos.z + dz,
						})
					end
				end
			end
		end
		minetest.remove_node(pos)
	end,
	-- unaffected by explosions
	on_blast = function() end,
	on_construct = function(pos)
		minetest.sound_play("tnt_gunpowder_burning", {pos = pos, max_hear_distance = 5, gain = 2}, true)
		minetest.get_node_timer(pos):start(0.1)
	end
})

function tnt.register_tnt(def)
	local name
	if not def.name:find(':') then
		name = "tnt:" .. def.name
	else
		name = def.name
		def.name = def.name:match(":([%w_]+)")
	end
	if not def.tiles then def.tiles = {} end
	local tnt_top = def.tiles.top or def.name .. "_top.png"
	local tnt_bottom = def.tiles.bottom or def.name .. "_bottom.png"
	local tnt_side = def.tiles.side or def.name .. "_side.png"
	local tnt_burning = def.tiles.burning or def.name .. "_top_burning_animated.png"
	def.damage_radius = def.radius * 2

	minetest.register_node(":" .. name, {
		description = def.description,
		tiles = {tnt_top, tnt_bottom, tnt_side},
		is_ground_content = false,
		groups = {dig_immediate = 2, mesecon = 2, tnt = 1, flammable = 5},
		sounds = default.node_sound_wood_defaults(),
		after_place_node = function(pos, placer)
			if placer:is_player() then
				local meta = minetest.get_meta(pos)
				meta:set_string("owner", placer:get_player_name())
			end
		end,
		on_punch = function(pos, node, puncher)
			if puncher:get_wielded_item():get_name() == "default:torch" then
				minetest.swap_node(pos, {name = name .. "_burning"})
				minetest.registered_nodes[name .. "_burning"].on_construct(pos)
				minetest.log("action", puncher:get_player_name() ..
					" ignites " .. node.name .. " at " ..
					minetest.pos_to_string(pos))
			end
		end,
		on_blast = function(pos, intensity)
			minetest.swap_node(pos, {name = name .. "_burning"})
			minetest.registered_nodes[name .. "_burning"].on_construct(pos)
		end,
		on_burn = function(pos)
			minetest.swap_node(pos, {name = name .. "_burning"})
			minetest.registered_nodes[name .. "_burning"].on_construct(pos)
		end,
		on_ignite = function(pos, igniter)
			minetest.swap_node(pos, {name = name .. "_burning"})
			minetest.registered_nodes[name .. "_burning"].on_construct(pos)
		end
	})

	minetest.register_node(":" .. name .. "_burning", {
		tiles = {
			{
				name = tnt_burning,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 1,
				}
			},
			tnt_bottom, tnt_side
			},
		light_source = 5,
		drop = "",
		sounds = default.node_sound_wood_defaults(),
		--groups = {falling_node = 1},
		on_timer = function(pos, elapsed)
			tnt.boom(pos, def)
		end,
		-- unaffected by explosions
		on_blast = function() end,
		on_construct = function(pos)
			minetest.sound_play("tnt_ignite", {pos = pos, max_hear_distance=def.damage_radius}, true)
			minetest.get_node_timer(pos):start(4)
			--minetest.check_for_falling(pos)
		end
	})
end

tnt.register_tnt({
	name = "tnt:tnt",
	description = "TNT",
	radius = 3
})
