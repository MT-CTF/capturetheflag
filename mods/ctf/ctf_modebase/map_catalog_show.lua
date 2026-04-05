local S = minetest.get_translator(minetest.get_current_modname())

local function show_catalog(pname, current_map)
	if not current_map then
		current_map = ctf_modebase.map_catalog.current_map
	end

	if not current_map then
		current_map = 1
	end

	local current_map_meta = ctf_modebase.map_catalog.maps[current_map]

	ctf_gui.show_formspec(pname, "ctf_modebase:catalog", function(ctx)
		-- EDITOR: Fix crash
		-- local S = function(x) return x end

		local SIZE_X = 18.3
		local SIZE_Y = 13.7

		local COL1 = 1.0
		local COL2 = 7.0

		local PAST_HEADER = 0.7

		local image_texture = ctx.current_map_meta.dirname .. "_screenshot.png"

		local out = {
			"formspec_version[4]",
			{"size[%.1f,%.1f]", SIZE_X, SIZE_Y},

			-- Header
			{
				"hypertext[0,0.3;%.1f,0.8;title;<center><big>%s</big></center>]",
				SIZE_X,
				S("Maps catalog")
			},

			-- Column 1
			"tablecolumns[text]",
			{
				"table[%.1f,%.1f;4.99,8.0;list;%s;%d]",
				COL1,
				PAST_HEADER + 1,
				ctx.map_names,
				current_map
			},
			{"button[%.1f,%.1f;5.0,0.5;previous;<<]", COL1, PAST_HEADER + 0.5},
			{"button[%.1f,%.1f;5.0,0.5;next;>>]", COL1, PAST_HEADER + 9},

			-- Column 2
			{
				"hypertext[%.1f,1.1;%.1f,0.6;title;<style font=mono><big>%s</big></style>]",
				COL2,
				SIZE_X,
				ctx.map_names[current_map]
			},
			{
				"image[%.1f,2.2;10.0,6.0;%s]",
				COL2,
				image_texture,
			},
			{
				"label[%.1f,1.9;%s: %s]",
				COL2,
				S("By"),
				core.colorize("#cccccc", ctx.current_map_meta.author)
			},
		}

		if minetest.check_player_privs(pname, {ctf_admin=true}) then
			table.insert(out, {
				"button[%.1f,%.1f;2.5,1.0;set_as_next_map;%s]",
				COL1 + 2.5,
				PAST_HEADER + 10,
				S("Set as next map"),
			})
			table.insert(out, {
				"button_exit[%.1f,%.1f;2.5,1.0;skip_to_map;%s]",
				COL1,
				PAST_HEADER + 10,
				S("Skip to map"),
			})
		end

		local info_idx = 8.8
		if ctx.current_map_meta.game_modes and #ctx.current_map_meta.game_modes > 0 then
			table.insert(out, {
				"textarea[%.1f,%.1f;10.0,0.7;;%s;%s]",
				COL2,
				info_idx,
				core.colorize("#ffff00",
				S("GAME MODES")),
				HumanReadable(ctx.current_map_meta.game_modes)
			})
			info_idx = info_idx + 1
		end

		if ctx.current_map_meta.license and ctx.current_map_meta.license ~= "" then
			table.insert(out, {
				"textarea[%.1f,%.1f;10.0,1.0;;%s;%s]",
				COL2,
				info_idx,
				core.colorize("#ffff00", S("LICENSE")..":"),
				ctx.current_map_meta.license
			})
			info_idx = info_idx + 1.3
		end

		if ctx.current_map_meta.hint and ctx.current_map_meta.hint ~= "" then
			table.insert(out, {
				"textarea[%.1f,%.1f;10.0,1.0;;%s;%s]",
				COL2,
				info_idx,
				core.colorize("#ffff00", S("HINT")..":"),
				ctx.current_map_meta.hint,
			})
			info_idx = info_idx + 1.3
		end

		if ctx.current_map_meta.others and ctx.current_map_meta.others ~= "" then
			table.insert(out, {
				"textarea[%.1f,%.1f;10.0,1.0;;%s;%s]",
				COL2,
				info_idx,
				core.colorize("#ffff00", S("MORE INFORMATION")..":"),
				ctx.current_map_meta.others
			})
		end

		return ctf_gui.list_to_formspec_str(out)
	end,
	{
		current_map_meta = current_map_meta,
		map_names = ctf_modebase.map_catalog.map_names,
		_on_formspec_input = function(playername, context, fields)
			if minetest.check_player_privs(pname, {ctf_admin=true}) then
				if fields.set_as_next_map then
					local mapname = ctf_modebase.map_catalog.maps[current_map].dirname
					minetest.log("action", string.format("[ctf_admin] %s set next map to %s", playername, mapname))
					core.chat_send_player(playername, "[Maps Catalog] Set the next map to " .. mapname)
					ctf_modebase.map_on_next_match = mapname
				end

				if fields.skip_to_map then
					local mapname = ctf_modebase.map_catalog.maps[current_map].dirname
					minetest.log("action", string.format("[ctf_admin] %s skipped to new map %s", playername, mapname))
					core.chat_send_player(playername, "[Maps Catalog] Skipping to map " .. mapname .. "...")

					ctf_modebase.map_on_next_match = mapname
					ctf_modebase.start_new_match()
				end
			end

			if fields.next and current_map < #ctf_modebase.map_catalog.maps then
				show_catalog(pname, current_map + 1)
			end

			if fields.previous and current_map > 1 then
				show_catalog(pname, current_map - 1)
			end

			if fields.list then
				local evt = minetest.explode_table_event(fields.list)

				if evt.type == "CHG" and evt.row >= 1 and evt.row <= #ctf_modebase.map_catalog.maps then
					show_catalog(pname, evt.row)
				end
			end
		end,
	})
end

minetest.register_chatcommand("maps", {
	description = S("Show the map catalog"),
	func = function(name)
		show_catalog(name)
	end
})
