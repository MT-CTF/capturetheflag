minetest.register_on_joinplayer(function(player)
	minetest.after(1, function(name)
		minetest.chat_send_player(name, "*** CTF_MAP IS IN MAP MAKER MODE ***")
	end, player:get_player_name())
end)

assert(minetest.get_modpath("worldedit") and
		minetest.get_modpath("worldedit_commands"),
		"worldedit and worldedit_commands are required!")

local flag_positions = {}
local function check_step()
	for _, pos in pairs(flag_positions) do
		if minetest.get_node(pos).name ~= "ctf_map:flag" then
			minetest.set_node(pos, { name = "ctf_map:flag" })
		end
	end

	minetest.after(1, check_step)
end
minetest.after(1, check_step)

minetest.register_node("ctf_map:flag", {
	description = "Flag",
	drawtype="nodebox",
	paramtype = "light",
	walkable = false,
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"flag_grey2.png",
		"flag_grey.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			{ 0.250000,-0.500000,0.000000,0.312500,0.500000,0.062500},
			{ -0.5,0,0.000000,0.250000,0.500000,0.062500}
		}
	},
	groups = {oddly_breakable_by_hand=1,snappy=3},
	on_construct = function(pos)
		table.insert(flag_positions, vector.new(pos))
	end,
	on_destruct = function(pos)
		for i, v in pairs(flag_positions) do
			if vector.equals(pos, v) then
				flag_positions[i] = nil
				return
			end
		end
	end,
})

local randint = math.random(100)
local barrier_r = 110
local mapname = "ctf_" .. randint
local maptitle = "Untitled Map " .. randint
local mapauthor = nil
local center_barrier_rot = 0
local center = { x = 0, y = 0, z = 0, r = 115, h = 140 }
local function to_2pos()
	return {
			x = center.x - center.r,
			y = center.y - center.h / 2,
			z = center.z - center.r,
		}, {
			x = center.x + center.r,
			y = center.y + center.h / 2,
			z = center.z + center.r,
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
		center = vector.divide(vector.add(pos1, pos2), 2)
		center.r = r
		center.h = size.y
	end
end

local function get_flags()
	local negative = nil
	local positive = nil
	for _, pos in pairs(flag_positions) do
		pos = vector.subtract(pos, center)

		if center_barrier_rot == 0 and pos.x < 0 or pos.z < 0 then
			negative = pos
		end

		if center_barrier_rot == 0 and pos.x > 0 or pos.z > 0 then
			positive = pos
		end
	end

	return negative, positive
end

local function get_flag_status()
	if #flag_positions > 2 then
		return "Too many flags! (" .. #flag_positions .. "/2)"
	elseif #flag_positions < 2 then
		return "Place more flags (" .. #flag_positions .. "/2)"
	else
		local negative, positive = get_flags()
		if positive and negative then
			return "Flags placed (" .. #flag_positions .. "/2)"
		else
			return "Place one flag on each side of the barrier."
		end
	end
end

local function show_gui(name)
	mapauthor = mapauthor or name

	local formspec = {
		"size[9,9.5]",
		"bgcolor[#080808BB;true]",
		default.gui_bg,
		default.gui_bg_img,

		"label[0,0;1. Select Area]",
		"field[0.4,1;1,1;posx;X;", center.x, "]",
		"field[1.4,1;1,1;posy;Y;", center.y, "]",
		"field[2.4,1;1,1;posz;Z;", center.z, "]",
		"field[0.4,2;1,1;posr;R;", center.r, "]",
		"field[1.4,2;1,1;posh;H;", center.h, "]",
		"button[4.3,0.7;1.5,1;set_center;Player Pos]",
		"button[5.8,0.7;1.1,1;towe;To WE]",
		"button[6.9,0.7;1.1,1;fromwe;From WE]",
		"button[4.3,1.7;1.5,1;emerge;Emerge Area]",

		"label[0,3;2. Place Barriers]",
		"label[0,3.5;This may take a few minutes.]",
		"field[0.4,4.5;1,1;barrier_r;R;", barrier_r, "]",
		"dropdown[1.15,4.25;1,1;center_barrier_rot;X=0,Z=0;", center_barrier_rot + 1, "]",
		"button[2.3,4.2;2,1;place_barrier;Place Barriers]",

		"label[5.3,3;3. Place Flags]",
		"label[5.3,3.5;", minetest.formspec_escape(get_flag_status()), "]",
		"button[5.3,4.2;3.5,1;giveme;Giveme Flags]",

		"label[0,5.5;4. Meta Data]",
		"field[0.4,6.5;7.5,1;title;Title;" , minetest.formspec_escape(maptitle), "]",
		"field[0.4,7.8;3.75,1;name;File Name;" , minetest.formspec_escape(mapname), "]",
		"field[4.15,7.8;3.75,1;author;Author;", minetest.formspec_escape(mapauthor), "]",

		"button_exit[0.8,8.8;3,1;close;Close]",
		"button_exit[3.8,8.8;3,1;export;Export]",
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
		center.x  = tonumber(fields.posx)
		center.y  = tonumber(fields.posy)
		center.z  = tonumber(fields.posz)
		center.r  = tonumber(fields.posr)
		center.h  = tonumber(fields.posh)
		barrier_r = tonumber(fields.barrier_r)
		maptitle  = fields.title
		mapauthor = fields.author
		mapname   = fields.name
	end

	if fields.center_barrier_rot and fields.center_barrier_rot ~= "" then
		center_barrier_rot = fields.center_barrier_rot == "X=0" and 0 or 1
	end

	if fields.set_center then
		local r = center.r
		local h = center.h
		center = vector.floor(player:get_pos())
		center.r = r
		center.h = h
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
				ctf_map.place_middle_barrier(center, barrier_r, center.h, (center_barrier_rot == 0) and "x" or "z")
				show_progress_formspec(player_name, "Placing outer barriers, this may take a while...")
				minetest.after(0.1, function()
					ctf_map.place_outer_barrier(center, barrier_r, center.h)
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
		if #flag_positions ~= 2 then
			minetest.chat_send_all("You need to place two flags!")
			return
		end

		we_select(player_name)
		show_progress_formspec(player_name, "Exporting...")

		local path = minetest.get_worldpath() .. "/schems/"
		minetest.mkdir(path)

		local meta = Settings(path .. mapname .. ".conf")
		meta:set("name", maptitle)
		meta:set("author", mapauthor)
		meta:set("rotation", center_barrier_rot == 0 and "x" or "z")
		meta:set("r", center.r)
		meta:set("h", center.h)
		meta:write()

		for _, flags in pairs(flag_positions) do
			local pos = vector.subtract(flags, center)
			if center_barrier_rot == 0 then
				local old = vector.new(pos)
				pos.x = old.z
				pos.z = -old.x
			end

			local idx = pos.z > 0 and 1 or 2
			meta:set("team." .. idx, pos.z > 0 and "red" or "blue")
			meta:set("team." .. idx .. ".color", pos.z > 0 and "red" or "blue")
			meta:set("team." .. idx .. ".pos", minetest.pos_to_string(pos))
		end

		minetest.after(0.1, function()
			local filepath = path .. mapname .. ".mts"
			if minetest.create_schematic(worldedit.pos1[player_name],
					worldedit.pos2[player_name], worldedit.prob_list[player_name],
					filepath) then
				minetest.chat_send_all("Exported " .. mapname .. " to " .. path)
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
