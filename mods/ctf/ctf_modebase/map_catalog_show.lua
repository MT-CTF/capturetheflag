local function show_catalog(pname, current_map)
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
				rows = ctf_modebase.map_catalog.map_names,
				default_idx = current_map,
				func = function(_, fields)
					local evt = minetest.explode_table_event(fields.list)
					if evt.type == "CHG" then
						show_catalog(pname, evt.row)
					end
				end,
			}
		}
	}

	local y = 0.7

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
		formspec.elements.hint = {
			type = "textarea",
			pos = {7, y},
			size = {10, 1},
			label = minetest.colorize("#ffff00", "HINT:"),
			read_only = true,
			default = current_map_meta.hint,
		}
		y = y + 1.5
	end

	if current_map_meta.license and current_map_meta.license ~= "" then
		formspec.elements.license = {
			type = "textarea",
			pos = {7, y},
			size = {10, 1},
			label = minetest.colorize("#ffff00", "LICENSE:"),
			read_only = true,
			default = current_map_meta.license,
		}
		y = y + 1.5
	end

	if current_map_meta.game_modes and #current_map_meta.game_modes > 0 then
		formspec.elements.game_modes = {
			type = "textarea",
			pos = {7, y},
			size = {10, 3},
			label = minetest.colorize("#ffff00", "GAME MODES"),
			read_only = true,
			default = HumanReadable(current_map_meta.game_modes),
		}
		y = y + 1.5
	end

	if current_map_meta.others and current_map_meta.others ~= "" then
		formspec.elements.others = {
			type = "textarea",
			pos = {7, y},
			size = {10, 3},
			label = minetest.colorize("#ffff00", "MORE INFORMATION"),
			read_only = true,
			default = current_map_meta.others,
		}
	end

	if current_map > 1 then
		formspec.elements.previous = {
			type = "button",
			label = "<<",
			pos = {1, ctf_gui.FORM_SIZE.y - ctf_gui.ELEM_SIZE.y - 11.8},
			size = {5, 0.5},
			func = function()
				show_catalog(pname, current_map - 1)
			end,
		}
	end

	if current_map < #ctf_modebase.map_catalog.maps then
		formspec.elements.next = {
			type = "button",
			label = ">>",
			pos = {1, ctf_gui.FORM_SIZE.y - ctf_gui.ELEM_SIZE.y - 3.3},
			size = {5, 0.5},
			func = function()
				show_catalog(pname, current_map + 1)
			end,
		}
	end

	if minetest.check_player_privs(pname, {ctf_admin=true}) then
		formspec.elements.skip_to_map = {
			type = "button",
			exit = true,
			label = "Skip to map",
			pos = {1, ctf_gui.FORM_SIZE.y - ctf_gui.ELEM_SIZE.y - 2.2},
			size = {2.5, 1},
			func = function()
				local mapname = ctf_modebase.map_catalog.maps[current_map].dirname
				minetest.log("action", string.format("[ctf_admin] %s skipped to new map %s", pname, mapname))

				ctf_modebase.map_on_next_match = mapname
				ctf_modebase.start_new_match()
			end
		}
	end

	if minetest.check_player_privs(pname, {ctf_admin=true}) then
		formspec.elements.set_as_next_map = {
			type = "button",
			label = "Set as next map",
			pos = {3.5, ctf_gui.FORM_SIZE.y - ctf_gui.ELEM_SIZE.y - 2.2},
			size = {2.5, 1},
			func = function()
				local mapname = ctf_modebase.map_catalog.maps[current_map].dirname
				minetest.log("action", string.format("[ctf_admin] %s set new map %s", pname, mapname))

				ctf_modebase.map_on_next_match = mapname
			end
		}
	end

	ctf_gui.old_show_formspec(pname, "ctf_map:catalog", formspec)
end

minetest.register_chatcommand("maps", {
	description = "Show the map catalog",
	func = function(name)
		show_catalog(name)
	end
})
