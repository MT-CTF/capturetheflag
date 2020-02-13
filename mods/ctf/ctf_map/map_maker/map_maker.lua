-- Load support for MT game translation.
local S = minetest.get_translator("ctf")

local storage = minetest.get_mod_storage()
local randint = math.random(100)
local defaults = {
	mapname = "ctf_" .. randint,
	mapauthor = nil,
	maptitle = "Untitled Map " .. randint,
	mapinitial = "",
	barrier_r = 110,
	barrier_rot = 0,
	center = { x = 0, y = 0, z = 0, r = 115, h = 140 },
	flags = {}
}

-- Reload mapmaker context from mod_storage if it exists
local context = {
	mapname = storage:get_string("mapname"),
	maptitle = storage:get_string("maptitle"),
	mapauthor = storage:get_string("mapauthor"),
	mapinitial = storage:get_string("mapinitial"),
	center = storage:get_string("center"),
	flags = storage:get_string("flags"),
	barrier_r = storage:get_int("barrier_r"),
	barrier_rot = storage:get_string("barrier_rot"),
	barriers_placed = storage:get_int("barriers_placed") == 1
}

if context.mapname == "" then
	context.mapname = defaults.mapname
end
if context.mapauthor == "" then
	context.mapauthor = defaults.mapauthor
end
if context.maptitle == "" then
	context.maptitle = defaults.maptitle
end
if context.barrier_r == 0 then
	context.barrier_r = defaults.barrier_r
end
if context.center == "" then
	context.center = defaults.center
else
	context.center = minetest.parse_json(storage:get_string("center"))
end
if context.flags == "" then
	context.flags = defaults.flags
else
	context.flags = minetest.parse_json(storage:get_string("flags"))
end

--------------------------------------------------------------------------------


minetest.register_on_joinplayer(function(player)
	minetest.after(1, function(name)
		minetest.chat_send_player(name,
			minetest.colorize("#BB33EE", "*** ctf_map is in map-maker mode ***"))
	end, player:get_player_name())

	local inv = player:get_inventory()
	if not inv:contains_item("main", "map_maker:adminpick") then
		inv:add_item("main", "map_maker:adminpick")
	end
end)

minetest.register_on_respawnplayer(function(player)
	local inv = player:get_inventory()
	if not inv:contains_item("main", "map_maker:adminpick") then
		inv:add_item("main", "map_maker:adminpick")
	end
end)

assert(minetest.get_modpath("worldedit") and
		minetest.get_modpath("worldedit_commands"),
		"worldedit and worldedit_commands are required!")

-- Register special pickaxe to break indestructible nodes
minetest.register_tool("map_maker:adminpick", {
	description = S("Admin pickaxe used to break indestructible nodes."),
	inventory_image = "map_maker_adminpick.png",
	range = 16,
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level = 3,
		groupcaps = {
			immortal = {times = {[1] = 0.5}, uses = 0, maxlevel = 3}
		},
		damage_groups = {fleshy = 10000}
	}
})

minetest.register_node(":ctf_map:flag", {
	description = S("Flag"),
	drawtype="nodebox",
	paramtype = "light",
	walkable = false,
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"map_maker_flag_grey.png",
		"map_maker_flag_grey.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			{ 0.250000,-0.500000,0.000000,0.312500,0.500000,0.062500},
			{ -0.5,0,0.000000,0.250000,0.500000,0.062500}
		}
	},
	groups = {oddly_breakable_by_hand=1,snappy=3},
	after_place_node = function(pos)
		table.insert(context.flags, vector.new(pos))
		storage:set_string("flags", minetest.write_json(context.flags))
	end,
	on_destruct = function(pos)
		for i, v in pairs(context.flags) do
			if vector.equals(pos, v) then
				context.flags[i] = nil
				return
			end
		end
	end,
})

local function check_step()
	for _, pos in pairs(context.flags) do
		if minetest.get_node(pos).name ~= "ctf_map:flag" then
			minetest.set_node(pos, { name = "ctf_map:flag" })
		end
	end

	minetest.after(1, check_step)
end
minetest.after(1, check_step)

local function get_flags()
	local negative = nil
	local positive = nil
	for _, pos in pairs(context.flags) do
		pos = vector.subtract(pos, context.center)

		if context.barrier_rot == 0 and pos.x < 0 or pos.z < 0 then
			negative = pos
		end

		if context.barrier_rot == 0 and pos.x > 0 or pos.z > 0 then
			positive = pos
		end
	end

	return negative, positive
end

local function to_2pos()
	return {
		x = context.center.x - context.center.r,
		y = context.center.y - context.center.h / 2,
		z = context.center.z - context.center.r,
	}, {
		x = context.center.x + context.center.r,
		y = context.center.y + context.center.h / 2,
		z = context.center.z + context.center.r,
	}
end

local function max(a, b)
	if a > b then
		return a
	else
		return b
	end
end

--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------

function map_maker.get_context()
	return context
end

function map_maker.emerge(name)
	local pos1, pos2 = to_2pos()
	map_maker.show_progress_formspec(name, "Emerging area...")
	ctf_map.emerge_with_callbacks(name, pos1, pos2, function()
		map_maker.show_gui(name)
	end, map_maker.emerge_progress)
	return true
end

function map_maker.we_select(name)
	local pos1, pos2 = to_2pos()
	worldedit.pos1[name] = pos1
	worldedit.mark_pos1(name)
	worldedit.player_notify(name, "position 1 set to " .. minetest.pos_to_string(pos1))
	worldedit.pos2[name] = pos2
	worldedit.mark_pos2(name)
	worldedit.player_notify(name, "position 2 set to " .. minetest.pos_to_string(pos2))
end

function map_maker.we_import(name)
	local pos1 = worldedit.pos1[name]
	local pos2 = worldedit.pos2[name]
	if pos1 and pos2 then
		local size = vector.subtract(pos2, pos1)
		local r = max(size.x, size.z) / 2
		context.center = vector.divide(vector.add(pos1, pos2), 2)
		context.center.r = r
		context.center.h = size.y
		storage:set_string("center", minetest.write_json(context.center))
	end
end

function map_maker.set_meta(k, v)
	if v ~= context[k] then
		context[k] = v

		if type(v) == "number" then
			storage:set_int(k, v)
		else
			storage:set_string(k, v)
		end
	end
end

function map_maker.set_center(name, center)
	if center then
		for k, v in pairs(center) do
			context.center[k] = v
		end
	else
		local r   = context.center.r
		local h   = context.center.h
		local pos = minetest.get_player_by_name(name):get_pos()
		context.center = vector.floor(pos)
		context.center.r = r
		context.center.h = h
	end
	storage:set_string("center", minetest.write_json(context.center))
end

function map_maker.get_flag_status()
	if #context.flags > 2 then
		return "Too many flags! (" .. #context.flags .. "/2)"
	elseif #context.flags < 2 then
		return "Place more flags (" .. #context.flags .. "/2)"
	else
		local negative, positive = get_flags()
		if positive and negative then
			return "Flags placed (" .. #context.flags .. "/2)"
		else
			return "Place one flag on each side of the barrier."
		end
	end
end

function map_maker.place_barriers(name)
	local pos1, pos2 = to_2pos()
	map_maker.show_progress_formspec(name, "Emerging area...")
	ctf_map.emerge_with_callbacks(name, pos1, pos2, function()
		map_maker.show_progress_formspec(name,
			"Placing center barrier, this may take a while...")

		minetest.after(0.1, function()
			ctf_map.place_middle_barrier(context.center, context.barrier_r,
					context.center.h, (context.barrier_rot == 0) and "x" or "z")

			map_maker.show_progress_formspec(name,
				"Placing outer barriers, this may take a while...")
			minetest.after(0.1, function()
				ctf_map.place_outer_barrier(context.center, context.barrier_r, context.center.h)
				map_maker.show_gui(name)
			end)
		end)
	end, map_maker.emerge_progress)
	return true
end

function map_maker.export(name)
	if #context.flags ~= 2 then
		minetest.chat_send_all("You need to place two flags!")
		return
	end

	map_maker.we_select(name)
	map_maker.show_progress_formspec(name, "Exporting...")

	local path = minetest.get_worldpath() .. "/schems/" .. context.mapname .. "/"
	minetest.mkdir(path)

	-- Reset mod_storage
	storage:set_string("center", "")
	storage:set_string("maptitle", "")
	storage:set_string("mapauthor", "")
	storage:set_string("mapname", "")
	storage:set_string("mapinitial", "")
	storage:set_string("barrier_rot", "")
	storage:set_string("barrier_r", "")

	-- Write to .conf
	local meta = Settings(path .. "map.conf")
	meta:set("name", context.maptitle)
	meta:set("author", context.mapauthor)
	if context.mapinitial ~= "" then
		meta:set("initial_stuff", context.mapinitial)
	end
	meta:set("rotation", context.barrier_rot)
	meta:set("r", context.center.r)
	meta:set("h", context.center.h)

	for _, flags in pairs(context.flags) do
		local pos = vector.subtract(flags, context.center)
		if context.barrier_rot == 0 then
			local old = vector.new(pos)
			pos.x = old.z
			pos.z = -old.x
		end

		local idx = pos.z > 0 and 1 or 2
		meta:set("team." .. idx, pos.z > 0 and "red" or "blue")
		meta:set("team." .. idx .. ".color", pos.z > 0 and "red" or "blue")
		meta:set("team." .. idx .. ".pos", minetest.pos_to_string(pos))
	end
	meta:write()

	minetest.after(0.1, function()
		local filepath = path .. "map.mts"
		if minetest.create_schematic(worldedit.pos1[name], worldedit.pos2[name],
				worldedit.prob_list[name], filepath) then
			minetest.chat_send_all("Exported " .. context.mapname .. " to " .. path)
			minetest.close_formspec(name, "")
		else
			minetest.chat_send_all("Failed!")
			map_maker.show_gui(name)
		end
	end)
	return
end
