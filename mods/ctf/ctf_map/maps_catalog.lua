-- Maps Catalog Formspec

local indices = {}

local function show_catalog(name)
	-- Select map to be displayed
	local idx = indices[name]
	local map = ctf_map.available_maps[idx]

	local fs = "size[10,9]"

	fs = fs .. "container[0,0]"
	fs = fs .. "box[0,0;9.8,1;#111]"
	if idx > 1 then
		fs = fs .. "button[0.5,0.1;1,1;btn_prev;<---]"
	end
	if idx < #ctf_map.available_maps then
		fs = fs .. "button[8.5,0.1;1,1;btn_next;--->]"
	end

	-- Map name and author
	fs = fs .. "label[1.75,0;" ..
			minetest.colorize("#ffff00", minetest.formspec_escape(map.name)) .. "]"
	fs = fs .. "label[1.75,0.5;" .. minetest.colorize("#cccccc",
			"by " .. minetest.formspec_escape(map.author)) .. "]"
	fs = fs .. "container_end[]"

	-- List of maps
	fs = fs .. "textlist[0,1.2;3.5,7.8;maps_list;"
	for i, v in pairs(ctf_map.available_maps) do
		local mname = v.name

		-- If entry corresponds to selected map, highlight in yellow
		if i == idx then
			mname = "#FFFF00" .. mname
		end

		fs = fs .. mname
		if i < #ctf_map.available_maps then
			fs = fs .. ","
		end
	end
	fs = fs .. ";" .. idx .. ";false]"

	-- Display screenshot if present, and move other elements down
	local y = 1
	if ctf_map.file_exists(map.dirname, "screenshot.png") then
		-- Check for mapdir .. "/screenshot.png", but pass in the texture
		-- name, which would've been renamed to mapdir .. ".png"
		fs = fs .. "image[4,1.5;6.5,3.5;" .. map.dirname .. ".png" .. "]"
		y = y + 3.5
	end

	-- Other fields
	fs = fs .. "container[3.5," .. y + 0.5 .. "]"
	y = 0
	if map.hint then
		fs = fs .. "label[0.5," .. y .. ";" ..
				minetest.colorize("#FFFF00", "HINT:") .. "]"
		fs = fs .. "textarea[0.8," .. y + 0.5 .. ";5.5,1;;;" ..
				minetest.formspec_escape(map.hint) .. "]"
		y = y + 1.375
	end
	if map.license then
		fs = fs .. "label[0.5," .. y .. ";" ..
				minetest.colorize("#FFFF00", "LICENSE:") .. "]"
		fs = fs .. "textarea[0.8," .. y + 0.5 .. ";5.5,1;;;" ..
				minetest.formspec_escape(map.license) .. "]"
		y = y + 1.375
	end
	if map.others then
		fs = fs .. "label[0.5," .. y .. ";" ..
				minetest.colorize("#FFFF00", "MORE INFORMATION:") .. "]"
		fs = fs .. "textarea[0.8," .. y + 0.5 .. ";5.5,1;;;" ..
				minetest.formspec_escape(map.others) .. "]"
	end
	fs = fs .. "container_end[]"

	-- Add some special buttons, if player has ctf_admin priv
	if minetest.check_player_privs(name, { ctf_admin = true }) then
		fs = fs .. "button[4,8;2,1;btn_jump;Skip to map]"
		fs = fs .. "button[6,8;2,1;btn_set;Set as next map]"
	end

	minetest.show_formspec(name, "ctf_map:maps_catalog", fs)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not player or formname ~= "ctf_map:maps_catalog" then
		return
	end

	local name = player:get_player_name()

	if fields.btn_prev then
		indices[name] = indices[name] - 1
		show_catalog(name)
	elseif fields.btn_next then
		indices[name] = indices[name] + 1
		show_catalog(name)
	end

	if fields.maps_list then
		local evt = minetest.explode_textlist_event(fields.maps_list)
		if evt.type ~= "INV" then
			indices[name] = evt.index
			show_catalog(name)
		end
	end

	if minetest.check_player_privs(name, { ctf_admin = true }) then
		if fields.btn_set then
			ctf_map.next_idx = indices[name]
			minetest.chat_send_player(name, "Selected " ..
					ctf_map.available_maps[ctf_map.next_idx].name .. " as next map.")
		end

		if fields.btn_jump then
			ctf_map.next_idx = indices[name]
			minetest.chat_send_player(name, "Skipping to next map")
			ctf_match.next()
		end
	end
end)

local function send_irc_catalog(name)
	-- Select map to be displayed
	local map = ctf_map.available_maps[indices[name]]

	-- IRC color codes
	local red = string.char(3) .. "4"
	local normal = string.char(3)

	minetest.chat_send_player(name, red .. "Map: " .. normal .. map.name)
	minetest.chat_send_player(name, red .. "Author: " .. normal .. map.author)
	if map.hint then
		minetest.chat_send_player(name, red .. "Hint: " .. normal .. map.hint)
	end
	if map.license then
		minetest.chat_send_player(name, red .. "License: " .. normal .. map.license)
	end
	if map.others then
		minetest.chat_send_player(name,
				red .. "More Information: " .. normal .. map.others)
	end
end

minetest.register_chatcommand("maps", {
	privs = {interact = true},
	func = function(name, param)
		if #ctf_map.available_maps == 0 then
			return false, "No maps are available!"
		end

		-- Set param to nil if it's empty
		if param and param:trim() == "" then
			param = nil
		end

		local player = minetest.get_player_by_name(name)

		-- If param supplied, set to idx of specified map
		if param then
			indices[name] = ctf_map.get_idx_and_map(param)
		end

		-- If no player and no param supplied, or indices[name] doesn't
		-- exist, set to idx of current map, or 1 as fallback
		if not player and not param or not indices[name] then
			indices[name] = ctf_map.map and ctf_map.map.idx or 1
		end

		if player then
			show_catalog(name)
		else
			minetest.chat_send_player(name, " *** CTF Maps Catalog for IRC *** ")
			if not param then
				minetest.chat_send_player(name,
					"No param supplied, showing information for current map.")
			end
			send_irc_catalog(name)
		end

		minetest.log("action", name .. " views the map catalog")
		return true
	end
})
