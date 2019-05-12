-- Maps Catalog Formspec

local indices = {}

local function show_catalog(name, idx)
	indices[name] = idx

	-- Select map to be displayed
	local map = ctf_map.available_maps[idx]

	local fs = "size[10,8]"

	fs = fs .. "container[0,0]"
	fs = fs .. "box[0,0;9.8,1;#111]"
	if idx > 1 then
		fs = fs .. "button[0.5,0.1;1,1;btn_prev;<---]"
	end
	if idx < #ctf_map.available_maps then
		fs = fs .. "button[8.5,0.1;1,1;btn_next;--->]"
	end

	-- Map name and author
	fs = fs .. "label[3,0;" .. minetest.formspec_escape(map.name) .. "]"
	fs = fs .. "label[5,0.5;" .. "(by " .. minetest.formspec_escape(map.author) .. ")]"
	fs = fs .. "container_end[]"

	-- List of maps
	fs = fs .. "textlist[0,1.2;3.5,6.8;maps_list;"
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
	if map.screenshot then
		fs = fs .. "image[4,1.5;6.5,3.5;" .. map.screenshot .. "]"
		y = y + 4
	end

	-- Other fields
	fs = fs .. "container[3.5," .. y + 0.5 .. "]"
	fs = fs .. "label[0.5,0;HINT: " ..
			minetest.formspec_escape(map.hint or "---") .. "]"
	fs = fs .. "label[0.5,0.5;LICENSE: " ..
			minetest.formspec_escape(map.license or "---") .. "]"
	fs = fs .. "container_end[]"

	minetest.show_formspec(name, "ctf_map:maps_catalog", fs)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not player or formname ~= "ctf_map:maps_catalog" then
		return
	end

	local name = player:get_player_name()

	if fields.btn_prev then
		show_catalog(name, indices[name] - 1)
	elseif fields.btn_next then
		show_catalog(name, indices[name] + 1)
	end

	if fields.maps_list then
		local evt = minetest.explode_textlist_event(fields.maps_list)
		if evt.type ~= "INV" then
			show_catalog(name, evt.index)
		end
	end
end)

minetest.register_chatcommand("maps", {
	privs = {interact = true},
	func = function(name, param)
		if not minetest.get_player_by_name(name) then
			return false, "You must be online to view the maps catalog!"
		end

		-- Set param to nil if it's empty
		if param and param:trim() == "" then
			param = nil
		end

		local idx

		-- If arg. supplied, set idx to index of the matching map name
		-- or path. Else, set to indices[name] or index of current map
		if param then
			idx = ctf_map.get_idx_and_map(param)
		else
			idx = indices[name] or ctf_map.map.idx
		end

		show_catalog(name, idx or 1)
		return true
	end
})
