local function show_catalog(pname, current_map)
	local maps = minetest.get_dir_list(ctf_map.maps_dir, true)
	table.sort(maps)
	local map_names = {}
	local current_map_index = nil
	local current_map_meta = {}
	local previous = nil
	local next = nil

	if not current_map then
		current_map = maps[1]
	end

	for i, map in ipairs(maps) do
		local map_meta = ctf_map.load_map_meta(0, map)
		table.insert(map_names, map_meta.name)
		if map == current_map then
			current_map_index = i
			current_map_meta = map_meta
			previous = maps[i - 1]
			next = maps[i + 1]
		end
	end

	local formspec = {
		title = "Maps catalog",
		elements = {
			list = {
				type = "table",
				pos = {1, 1},
				size = {5, ctf_gui.FORM_SIZE.y - 5},
				columns = {
					{type = "text"},
				},
				rows = map_names,
				default_idx = current_map_index,
				func = function(_, fields, name)
					local evt = minetest.explode_table_event(fields[name])
					if evt.type == "CHG" then
						show_catalog(pname, maps[evt.row])
					end
				end,
			}
		}
	}

	local y = 1

	if current_map_meta.author and current_map_meta.author ~= "" then
		formspec.elements.author = {
			type = "label",
			pos = {7, y},
			label = "By: " .. minetest.colorize("#cccccc", current_map_meta.author),
		}
		y = y + 0.5
	end

	-- "maps/{current_map}/screenshot.png" is copied to "textures/{current_map}_screenshot.png"
	local image_texture = current_map .. "_screenshot.png"
	if ctf_core.file_exists(string.format("%s/textures/%s", minetest.get_modpath("ctf_map"), image_texture)) then
		formspec.elements.image = {
			type = "image",
			pos = {7, y},
			size = {10, 6},
			texture = image_texture,
		}
		y = y + 6.5
	end

	if current_map_meta.hint and current_map_meta.hint ~= "" then
		formspec.elements.hint_label = {
			type = "label",
			pos = {7, y},
			label = minetest.colorize("#ffff00", "HINT:"),
		}
		formspec.elements.hint = {
			type = "textarea",
			pos = {7, y + 0.5},
			size = {10, 1},
			text = current_map_meta.hint,
		}
		y = y + 1.5
	end

	if current_map_meta.license and current_map_meta.license ~= "" then
		formspec.elements.license_label = {
			type = "label",
			pos = {7, y},
			label = minetest.colorize("#ffff00", "LICENSE:"),
		}
		formspec.elements.license = {
			type = "textarea",
			pos = {7, y + 0.5},
			size = {10, 1},
			text = current_map_meta.license,
		}
		y = y + 1.5
	end

	if current_map_meta.others and current_map_meta.others ~= "" then
		formspec.elements.others_label = {
			type = "label",
			pos = {7, y},
			label = minetest.colorize("#ffff00", "MORE INFORMATION"),
		}
		formspec.elements.others = {
			type = "textarea",
			pos = {7, y + 0.5},
			size = {10, 3},
			text = current_map_meta.others,
		}
	end

	if previous then
		formspec.elements.previous = {
			type = "button",
			label = "<<",
			pos = {1, ctf_gui.FORM_SIZE.y - ctf_gui.ELEM_SIZE.y - 2.5},
			func = function()
				show_catalog(pname, previous)
			end,
		}
	end

	if next then
		formspec.elements.next = {
			type = "button",
			label = ">>",
			pos = {5, ctf_gui.FORM_SIZE.y - ctf_gui.ELEM_SIZE.y - 2.5},
			func = function()
				show_catalog(pname, next)
			end,
		}
	end

	ctf_gui.show_formspec(pname, "ctf_map:catalog", formspec)
end

minetest.register_chatcommand("maps", {
	description = "Show the map catalog",
	func = function(name)
		local cur = nil
		if ctf_map.current_map then
			cur = ctf_map.current_map.dirname
		end
		show_catalog(name, cur)
	end
})
