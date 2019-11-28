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
local config = {
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

if config.mapname == "" then
	config.mapname = defaults.mapname
end
if config.mapauthor == "" then
	config.mapauthor = defaults.mapauthor
end
if config.maptitle == "" then
	config.maptitle = defaults.maptitle
end
if config.barrier_r == 0 then
	config.barrier_r = defaults.barrier_r
end
if config.center == "" then
	config.center = defaults.center
else
	config.center = minetest.parse_json(storage:get_string("center"))
end
if config.flags == "" then
	config.flags = defaults.flags
else
	config.flags = minetest.parse_json(storage:get_string("flags"))
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

local function check_step()
	for _, pos in pairs(config.flags) do
		if minetest.get_node(pos).name ~= "ctf_map:flag" then
			minetest.set_node(pos, { name = "ctf_map:flag" })
		end
	end

	minetest.after(1, check_step)
end
minetest.after(1, check_step)

minetest.register_node(":ctf_map:flag", {
	description = "Flag",
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
		table.insert(config.flags, vector.new(pos))
		storage:set_string("flags", minetest.write_json(config.flags))
	end,
	on_destruct = function(pos)
		for i, v in pairs(config.flags) do
			if vector.equals(pos, v) then
				config.flags[i] = nil
				return
			end
		end
	end,
})

local function to_2pos()
	return {
			x = config.center.x - config.center.r,
			y = config.center.y - config.center.h / 2,
			z = config.center.z - config.center.r,
		}, {
			x = config.center.x + config.center.r,
			y = config.center.y + config.center.h / 2,
			z = config.center.z + config.center.r,
		}
end

local function max(a, b)
	if a > b then
		return a
	else
		return b
	end
end

local function we_select(name)
	local pos1, pos2 = to_2pos()
	worldedit.pos1[name] = pos1
	worldedit.mark_pos1(name)
	worldedit.player_notify(name, "position 1 set to " .. minetest.pos_to_string(pos1))
	worldedit.pos2[name] = pos2
	worldedit.mark_pos2(name)
	worldedit.player_notify(name, "position 2 set to " .. minetest.pos_to_string(pos2))
end

local function we_import(name)
	local pos1 = worldedit.pos1[name]
	local pos2 = worldedit.pos2[name]
	if pos1 and pos2 then
		local size = vector.subtract(pos2, pos1)
		local r = max(size.x, size.z) / 2
		config.center = vector.divide(vector.add(pos1, pos2), 2)
		config.center.r = r
		config.center.h = size.y
		storage:set_string("center", minetest.write_json(config.center))
	end
end

local function get_flags()
	local negative = nil
	local positive = nil
	for _, pos in pairs(config.flags) do
		pos = vector.subtract(pos, config.center)

		if config.barrier_rot == 0 and pos.x < 0 or pos.z < 0 then
			negative = pos
		end

		if config.barrier_rot == 0 and pos.x > 0 or pos.z > 0 then
			positive = pos
		end
	end

	return negative, positive
end

local function get_flag_status()
	if #config.flags > 2 then
		return "Too many flags! (" .. #config.flags .. "/2)"
	elseif #config.flags < 2 then
		return "Place more flags (" .. #config.flags .. "/2)"
	else
		local negative, positive = get_flags()
		if positive and negative then
			return "Flags placed (" .. #config.flags .. "/2)"
		else
			return "Place one flag on each side of the barrier."
		end
	end
end

local function show_gui(name)
	if not config.mapauthor then
		config.mapauthor = name
		storage:set_string("mapauthor", config.mapauthor)
	end

	local formspec = {
		"size[9,9.5]",
		"bgcolor[#080808BB;true]",
		default.gui_bg,
		default.gui_bg_img,

		"label[0,0;1. Select Area]",
		"field[0.4,1;1,1;posx;X;", config.center.x, "]",
		"field[1.4,1;1,1;posy;Y;", config.center.y, "]",
		"field[2.4,1;1,1;posz;Z;", config.center.z, "]",
		"field[0.4,2;1.5,1;posr;R;", config.center.r, "]",
		"field[1.9,2;1.5,1;posh;H;", config.center.h, "]",
		"button[4.3,0.7;1.75,1;set_center;Player Pos]",
		"button[6.05,0.7;1.5,1;towe;To WE]",
		"button[7.55,0.7;1.5,1;fromwe;From WE]",
		"button[4.3,1.7;4.75,1;emerge;Emerge Area]",

		"box[0,2.65;8.85,0.05;#111111BB]",

		"label[0,2.8;2. Place Barriers]",
		"label[0.1,3.3;This may take a few minutes.]",
		"field[0.4,4.3;1,1;barrier_r;R;", config.barrier_r, "]",
		"dropdown[1.15,4.05;1,1;barrier_rot;X=0,Z=0;",
		config.barrier_rot == "x" and 1 or 2, "]",
		"button[2.3,4;2,1;place_barrier;Place Barriers]",

		"box[4.4,2.8;0.05,2.2;#111111BB]",

		"label[4.8,2.8;3. Place Flags]",
		"label[4.8,3.3;", minetest.formspec_escape(get_flag_status()), "]",
		"button[4.8,4;3.5,1;giveme;Giveme Flags]",

		"box[0,5.06;8.85,0.05;#111111BB]",

		"label[0,5.15;4. Meta Data]",
		"field[0.4,6.2;8.5,1;title;Title;",
		minetest.formspec_escape(config.maptitle), "]",
		"field[0.4,7.3;8.5,1;initial;Stuff to give on (re)spawn, comma-separated itemstrings;",
		minetest.formspec_escape(config.mapinitial), "]",
		"field[0.4,8.4;4.25,1;name;File Name;",
		minetest.formspec_escape(config.mapname), "]",
		"field[4.625,8.4;4.25,1;author;Author;",
		minetest.formspec_escape(config.mapauthor), "]",

		"button_exit[1.3,9;3,1;close;Close]",
		"button_exit[4.3,9;3,1;export;Export]",
	}

	formspec = table.concat(formspec, "")
	minetest.show_formspec(name, "ctf_map:tool", formspec)
end

local function show_progress_formspec(name, text)
	minetest.show_formspec(name, "ctf_map:progress",
		"size[6,1]bgcolor[#080808BB;true]" ..
		default.gui_bg ..
		default.gui_bg_img .. "label[0,0;" ..
		minetest.formspec_escape(text) .. "]")
end

local function emerge_progress(ctx)
	show_progress_formspec(ctx.name, string.format("Emerging Area - %d/%d blocks emerged (%.1f%%)",
		ctx.current_blocks, ctx.total_blocks,
		(ctx.current_blocks / ctx.total_blocks) * 100))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "ctf_map:tool" then
		return
	end

	if fields.posx then
		config.center.x = tonumber(fields.posx)
		config.center.y = tonumber(fields.posy)
		config.center.z = tonumber(fields.posz)
		config.center.r = tonumber(fields.posr)
		config.center.h = tonumber(fields.posh)
		storage:set_string("center", minetest.write_json(config.center))
	end

	fields.barrier_r = tonumber(fields.barrier_r)
	if fields.barrier_r and fields.barrier_r ~= config.barrier_r then
		config.barrier_r = fields.barrier_r
		storage:set_int("barrier_r", config.barrier_r)
	end

	if fields.title and fields.title ~= config.maptitle then
		config.maptitle  = fields.title
		storage:set_string("maptitle", config.maptitle)
	end

	if fields.author and fields.author ~= config.mapauthor then
		config.mapauthor = fields.author
		storage:set_string("mapauthor", config.mapauthor)
	end

	if fields.name and fields.name ~= config.mapname then
		config.mapname = fields.name
		storage:set_string("mapname", config.mapname)
	end

	if fields.initial and fields.initial ~= config.mapinitial then
		config.mapinitial = fields.initial
		storage:set_string("mapinitial", config.mapinitial)
	end

	if fields.barrier_rot and fields.barrier_rot ~= "" then
		config.barrier_rot = fields.barrier_rot == "X=0" and "x" or "z"
		storage:set_string("barrier_rot", config.barrier_rot)
	end

	if fields.set_center then
		local r = config.center.r
		local h = config.center.h
		config.center = vector.floor(player:get_pos())
		config.center.r = r
		config.center.h = h
		storage:set_string("center", minetest.write_json(config.center))
	end

	if fields.giveme then
		player:get_inventory():add_item("main", "ctf_map:flag 2")
	end

	local player_name = player:get_player_name()

	if fields.emerge then
		local pos1, pos2 = to_2pos()
		show_progress_formspec(player_name, "Emerging area...")
		ctf_map.emerge_with_callbacks(player_name, pos1, pos2, function()
			show_gui(player_name)
		end, emerge_progress)
		return true
	end

	if fields.place_barrier then
		local pos1, pos2 = to_2pos()
		show_progress_formspec(player_name, "Emerging area...")
		ctf_map.emerge_with_callbacks(player_name, pos1, pos2, function()
			show_progress_formspec(player_name, "Placing center barrier, this may take a while...")

			minetest.after(0.1, function()
				ctf_map.place_middle_barrier(config.center, config.barrier_r,
						config.center.h, (config.barrier_rot == 0) and "x" or "z")
				show_progress_formspec(player_name, "Placing outer barriers, this may take a while...")
				minetest.after(0.1, function()
					ctf_map.place_outer_barrier(config.center, config.barrier_r, config.center.h)
					show_gui(player_name)
				end)
			end)
		end, emerge_progress)
		return true
	end

	if fields.towe then
		we_select(player_name)
	end

	if fields.fromwe then
		we_import(player_name)
	end

	if fields.export then
		if #config.flags ~= 2 then
			minetest.chat_send_all("You need to place two flags!")
			return
		end

		we_select(player_name)
		show_progress_formspec(player_name, "Exporting...")

		local path = minetest.get_worldpath() .. "/schems/" .. config.mapname .. "/"
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
		meta:set("name", config.maptitle)
		meta:set("author", config.mapauthor)
		if config.mapinitial ~= "" then
			meta:set("initial_stuff", config.mapinitial)
		end
		meta:set("rotation", config.barrier_rot)
		meta:set("r", config.center.r)
		meta:set("h", config.center.h)

		for _, flags in pairs(config.flags) do
			local pos = vector.subtract(flags, config.center)
			if config.barrier_rot == 0 then
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
			if minetest.create_schematic(worldedit.pos1[player_name],
					worldedit.pos2[player_name], worldedit.prob_list[player_name],
					filepath) then
				minetest.chat_send_all("Exported " .. config.mapname .. " to " .. path)
				minetest.close_formspec(player_name, "")
			else
				minetest.chat_send_all("Failed!")
				show_gui(player_name)
			end
		end)
		return
	end

	if not fields.quit then
		show_gui(player_name)
	end
end)

minetest.register_chatcommand("gui", {
	func = function(name)
		show_gui(name)
		return true
	end
})

-- Register special pickaxe to break indestructible nodes
minetest.register_tool("map_maker:adminpick", {
	description = "Admin pickaxe used to break indestructible nodes.",
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
