ctf_modebase.map_catalog = {
	maps = {},
	map_names = {},
	map_dirnames = {},
	current_map = false,
}

local maps = minetest.get_dir_list(ctf_map.maps_dir, true)
table.sort(maps)

for i, dirname in ipairs(maps) do
	local map = ctf_map.load_map_meta(i, dirname)
	if map.map_version then
		table.insert(ctf_modebase.map_catalog.maps, map)
		table.insert(ctf_modebase.map_catalog.map_names, map.name)
		ctf_modebase.map_catalog.map_dirnames[map.dirname] = #ctf_modebase.map_catalog.maps
	end
end

assert(#ctf_modebase.map_catalog.maps > 0 or ctf_core.settings.server_mode == "mapedit")

local function show_catalog(pname, current_map)
	local map_names = {}
	for _, map in ipairs(ctf_modebase.map_catalog.maps) do
		table.insert(map_names, map.name)
	end

	if not current_map then
		current_map = ctf_modebase.map_catalog.current_map
	end

	if not current_map then
		current_map = 1
	end

	local current_map_meta = ctf_modebase.map_catalog.maps[current_map]

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
				default_idx = current_map,
				func = function(_, fields, name)
					local evt = minetest.explode_table_event(fields[name])
					if evt.type == "CHG" then
						show_catalog(pname, evt.row)
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
	local image_texture = current_map_meta.dirname .. "_screenshot.png"
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

	if current_map > 1 then
		formspec.elements.previous = {
			type = "button",
			label = "<<",
			pos = {1, ctf_gui.FORM_SIZE.y - ctf_gui.ELEM_SIZE.y - 2.5},
			func = function()
				show_catalog(pname, current_map - 1)
			end,
		}
	end

	if current_map < #ctf_modebase.map_catalog.maps then
		formspec.elements.next = {
			type = "button",
			label = ">>",
			pos = {5, ctf_gui.FORM_SIZE.y - ctf_gui.ELEM_SIZE.y - 2.5},
			func = function()
				show_catalog(pname, current_map + 1)
			end,
		}
	end

	ctf_gui.show_formspec(pname, "ctf_map:catalog", formspec)
end

minetest.register_chatcommand("maps", {
	description = "Show the map catalog",
	func = function(name)
		show_catalog(name)
	end
})
