ctf_gui.init()

local context = {}

function ctf_map.show_map_editor(player)
	if context[player] then
		ctf_map.show_map_save_form(player)
		return
	end

	local dirlist = minetest.get_dir_list(ctf_map.maps_dir, true)
	local dirlist_sorted = dirlist
	table.sort(dirlist_sorted)

	ctf_gui.show_formspec(player, "ctf_map:start", {
		size = {x = 8, y = 8},
		title = "Capture The Flag Map Editor",
		description = "Would you like to edit an existing map or create a new one?",
		privs = {ctf_map_editor = true},
		elements = {
			newmap = {
				type = "button", exit = true, label = "Create New Map",
				pos = {"center", 0},
				func = function(pname)
					minetest.chat_send_player(pname,
							"Please decide what the size of your map will be and punch nodes on two opposite corners of it")
					ctf_map.get_pos_from_player(pname, 2, function(p, positions)
						local pos1, pos2 = vector.sort(positions[1], positions[2])

						context[p] = {
							pos1          = pos1,
							pos2          = pos2,
							enabled       = false,
							dirname       = "new_map",
							name          = "My New Map",
							author        = player,
							hint          = "hint",
							license       = "CC-BY",
							others        = "Other info",
							base_node     = "ctf_map:cobble",
							initial_stuff = {},
							treasures     = {},
							skybox        = "none",
							-- Also see the save form for defaults
							start_time    = ctf_map.DEFAULT_START_TIME,
							time_speed    = 1,
							phys_speed    = 1,
							phys_jump     = 1,
							phys_gravity  = 1,
							--
							chests        = {},
							teams         = {},
							barrier_area  = {pos1 = pos1, pos2 = pos2},
						}

						minetest.chat_send_player(pname, "Build away!")
					end)
				end,
			},
			editexisting = {
				type = "button", exit = true, label = "Edit Existing map",
				pos = {"center", 1.8},
				func = function(pname, fields)
					local p = PlayerObj(pname)

					minetest.after(0.1, function()
						ctf_gui.show_formspec(pname, "ctf_map:loading", {
							size = {x = 6, y = 4},
							title = "Capture The Flag Map Editor",
							description = "Placing map '"..fields.currentmaps.."'. This will take a few seconds..."
						})
					end)

					minetest.after(0.5, function()
						local idx = table.indexof(dirlist, fields.currentmaps)
						local map = ctf_map.load_map_meta(idx, fields.currentmaps)

						ctf_map.place_map(map, function()
							minetest.after(2, function()
								ctf_map.announce_map(map)

								minetest.close_formspec(pname, "ctf_map:loading")

								p:set_pos(vector.add(map.pos1, vector.divide(map.size, 2)))

								skybox.set(p, table.indexof(ctf_map.skyboxes, map.skybox)-1)

								physics.set(pname, "ctf_map_editor_speed", {
									speed = map.phys_speed,
									jump = map.phys_jump,
									gravity = map.phys_gravity,
								})

								minetest.settings:set("time_speed", map.time_speed * 72)
								minetest.registered_chatcommands["time"].func(pname, tostring(map.start_time))
							end)

							minetest.after(10, function()
								minetest.fix_light(map.pos1, map.pos2)
							end)

							context[pname] = map
						end)
					end)
				end,
			},
			currentmaps = {
				type = "dropdown",
				pos = {"center", 1.9 + ctf_gui.ELEM_SIZE.y},
				size = {5, ctf_gui.ELEM_SIZE.y},
				items = dirlist_sorted,
			},
		}
	})
end

function ctf_map.show_map_save_form(player, scroll_pos)
	if not context[player] then
		minetest.log("error", "Cannot show save form because "..player.." is not editing a map!")
		return
	end

	if not context[player].teams then
		context[player].teams = {}
	end

	for name in pairs(ctf_teams.team) do
		if not context[player].teams[name] then
			context[player].teams[name] = {
				enabled = false,
				flag_pos = vector.new(),
				pos1 = vector.new(),
				pos2 = vector.new(),
			}
		end
	end

	local elements = {}

	-- MAP CORNERS
	elements.positions = {
		type = "button", exit = true,
		label = "Corners - " .. minetest.pos_to_string(context[player].pos1, 0) ..
				" - " .. minetest.pos_to_string(context[player].pos2, 0),
		pos = {0, 0.5},
		size = {10 - (ctf_gui.SCROLLBAR_WIDTH + 0.1), ctf_gui.ELEM_SIZE.y},
		func = function(pname)
			ctf_map.get_pos_from_player(pname, 2, function(p, positions)
				context[p].pos1 = positions[1]
				context[p].pos2 = positions[2]
			end)
		end,
	}

	-- MAP ENABLED
	elements.enabled = {
		type = "checkbox", label = "Map Enabled", pos = {0, 2}, default = context[player].enabled,
		func = function(pname, fields, name) context[pname].enabled = fields[name] == "true" or false end,
	}

	-- FOLDER NAME, MAP NAME, MAP AUTHOR(S), MAP HINT, MAP LICENSE, OTHER INFO
	local ypos = 3
	for name, label in pairs({
			dirname = "Folder Name", name = "Map Name"   , author = "Map Author(s)",
			hint    = "Map Hint"   , license = "Map License", others = "Other Info"
		}) do
		elements[name] = {
			type = "field", label = label,
			pos = {0, ypos}, size = {6, 0.7},
			default = context[player][name],
			func = function(pname, fields, fname)
				context[pname][name] = fields[fname]
			end,
		}

		ypos = ypos + 1.4
	end

	-- MAP INITIAL STUFF
	elements.initial_stuff = {
		type = "field", label = "Map Initial Stuff", pos = {0, 12.8}, size = {6, 0.7},
		default = table.concat(context[player].initial_stuff or {"none"}, ","),
		func = function(pname, fields, name)
			context[pname].initial_stuff = string.split(fields[name]:gsub("%s?,%s?", ","), ",")
		end,
	}

	-- MAP TREASURES
	elements.treasures = {
		type = "field", label = "Map Treasures", pos = {0, 14.2}, size = {6, 0.7},
		default = table.concat(context[player].treasures or {"none"}, ","),
		func = function(pname, fields, name)
			context[pname].treasures = string.split(fields[name], ",")
		end,
	}

	-- SKYBOX SELECTOR
	elements.skybox_label = {
		type = "label",
		pos = {0, 15.4},
		label = (context[player].skybox_forced and "Skybox: Using the one provided in map folder") or "Skybox",
	}

	if not context[player].skybox_forced then
		elements.skybox = {
			type = "dropdown",
			pos = {0, 15.6},
			size = {6, ctf_gui.ELEM_SIZE.y},
			items = ctf_map.skyboxes,
			default_idx = table.indexof(ctf_map.skyboxes, context[player].skybox),
			func = function(pname, fields, name)
				local oldval = context[pname].skybox
				context[pname].skybox = fields[name]

				if context[pname].skybox ~= oldval then
					skybox.set(PlayerObj(pname), table.indexof(ctf_map.skyboxes, fields[name])-1)
				end
			end,
		}
	end

	-- MAP PHYSICS
	ypos = 17
	for name, label in pairs({speed = "Map Movement Speed", jump = "Map Jump Height", gravity = "Map Gravity"}) do
		elements[name] = {
			type = "field", label = label,
			pos = {0, ypos}, size = {4, 0.7},
			default = context[player]["phys_"..name] or 1,
			func = function(pname, fields, fname)
				local oldval = context[pname]["phys_"..name]
				context[pname]["phys_"..name] = tonumber(fields[fname]) or 1

				if context[pname]["phys_"..name] ~= oldval then
					physics.set(pname, "ctf_map_editor_"..name, {[name] = tonumber(fields[fname] or 1)})
				end
			end,
		}

		ypos = ypos + 1.4
	end

	-- MAP START TIME
	elements.start_time = {
		type = "field", label = "Map start_time", pos = {0, 21.2}, size = {4, 0.7},
		default = context[player].start_time or ctf_map.DEFAULT_START_TIME,
		func = function(pname, fields, name)
			local oldval = context[pname].start_time
			context[pname].start_time = tonumber(fields[name] or ctf_map.DEFAULT_START_TIME)

			if context[pname].start_time ~= oldval then
				minetest.registered_chatcommands["time"].func(pname, tostring(context[pname].start_time))
			end
		end,
	}

	-- MAP time_speed
	elements.time_speed = {
		type = "field", label = "Map time_speed (Multiplier)", pos = {0, 22.6},
		size = {4, 0.7}, default = context[player].time_speed or "1",
		func = function(pname, fields, name)
			local oldval = context[pname].time_speed
			context[pname].time_speed = tonumber(fields[name] or "1")

			if context[pname].time_speed ~= oldval then
				minetest.settings:set("time_speed", context[pname].time_speed * 72)
			end
		end,
	}

	-- TEAMS
	local idx = 24.2
	for teamname, def in pairs(context[player].teams) do
		elements[teamname.."_checkbox"] = {
			type = "checkbox",
			label = HumanReadable(teamname) .. " Team",
			pos = {0, idx},
			default = def.enabled,
			func = function(pname, fields, name)
				context[pname].teams[teamname].enabled = fields[name] == "true" or false
			end,
		}
		idx = idx + 1

		elements[teamname.."_button"] = {
			type = "button",
			exit = true,
			label = "Set Flag Pos: " .. minetest.pos_to_string(def.flag_pos),
			pos = {0.2, idx-(ctf_gui.ELEM_SIZE.y/2)},
			size = {5, ctf_gui.ELEM_SIZE.y},
			func = function(pname, fields)
					ctf_map.get_pos_from_player(pname, 1, function(name, positions)
						local p = positions[1]

						context[pname].teams[teamname].flag_pos = p

						minetest.after(0.1, function()
							ctf_map.show_map_save_form(pname, minetest.explode_scrollbar_event(fields.formcontent).value)
						end)
					end)
			end,
		}

		elements[teamname.."_teleport"] = {
			type = "button",
			exit = true,
			label = "Go to pos",
			pos = {0.2 + 5 + 0.1, idx-(ctf_gui.ELEM_SIZE.y/2)},
			size = {2, ctf_gui.ELEM_SIZE.y},
			func = function(pname)
				PlayerObj(pname):set_pos(context[pname].teams[teamname].flag_pos)
			end,
		}

		idx = idx + 1

		elements[teamname.."_positions"] = {
			type = "button", exit = true,
			label = "Zone Bounds - " .. minetest.pos_to_string(context[player].teams[teamname].pos1, 0) ..
					" - " .. minetest.pos_to_string(context[player].teams[teamname].pos2, 0),
			pos = {0.2, idx-(ctf_gui.ELEM_SIZE.y/2)},
			size = {9 - (ctf_gui.SCROLLBAR_WIDTH + 0.1), ctf_gui.ELEM_SIZE.y},
			func = function(pname)
				ctf_map.get_pos_from_player(pname, 2, function(p, positions)
					context[pname].teams[teamname].pos1 = positions[1]
					context[pname].teams[teamname].pos2 = positions[2]
				end)
			end,
		}
		idx = idx + 1.5
	end

	-- CHEST ZONES
	elements.addchestzone = {
		type = "button",
		exit = true,
		label = "Add Chest Zone",
		pos = {(5 - 0.2) - (ctf_gui.ELEM_SIZE.x / 2), idx},
		func = function(pname)
			table.insert(context[pname].chests, {
				pos1 = vector.new(),
				pos2 = vector.new(),
				amount = ctf_map.DEFAULT_CHEST_AMOUNT,
			})
			minetest.after(0.1, function()
				ctf_map.show_map_save_form(pname, "max")
			end)
		end,
	}
	idx = idx + 1

	if #context[player].chests > 0 then
		for id, def in pairs(context[player].chests) do
			elements["chestzone_"..id] = {
				type = "button",
				exit = true,
				label = "Chest Zone "..id.." - "..minetest.pos_to_string(def.pos1, 0) ..
						" - "..minetest.pos_to_string(def.pos2, 0),
				pos = {0, idx},
				size = {7, ctf_gui.ELEM_SIZE.y},
				func = function(pname, fields)
					if not context[pname].chests[id] then return end

					ctf_map.get_pos_from_player(pname, 2, function(name, new_positions)
						context[pname].chests[id].pos1 = new_positions[1]
						context[pname].chests[id].pos2 = new_positions[2]

						minetest.after(0.1, function()
							ctf_map.show_map_save_form(pname, minetest.explode_scrollbar_event(fields.formcontent).value)
						end)
					end)
				end,
			}
			elements["chestzone_chests_"..id] = {
				type = "field",
				label = "Amount",
				pos = {7.2, idx},
				size = {1, ctf_gui.ELEM_SIZE.y},
				default = context[player].chests[id].amount,
				func = function(pname, fields, name)
					if not context[pname].chests[id] then return end

					local newnum = tonumber(fields[name])
					if newnum then
						context[pname].chests[id].amount = newnum
					end
				end,
			}
			elements["chestzone_remove_"..id] = {
				type = "button",
				exit = true,
				label = "X",
				pos = {8.4, idx},
				size = {ctf_gui.ELEM_SIZE.y, ctf_gui.ELEM_SIZE.y},
				func = function(pname, fields)
					table.remove(context[pname].chests, id)
					minetest.after(0.1, function()
						ctf_map.show_map_save_form(pname, minetest.explode_scrollbar_event(fields.formcontent).value)
					end)
				end,
			}
			idx = idx + 1
		end
	end
	idx = idx + 1

	elements.barrier_area = {
		type = "button", exit = true,
		label = "Barrier Area - " .. minetest.pos_to_string(context[player].barrier_area.pos1, 0) ..
				" - " .. minetest.pos_to_string(context[player].barrier_area.pos2, 0),
		pos = {0, idx},
		size = {9 - (ctf_gui.SCROLLBAR_WIDTH + 0.1), ctf_gui.ELEM_SIZE.y},
		func = function(pname)
			ctf_map.get_pos_from_player(pname, 2, function(p, positions)
				context[pname].barrier_area.pos1 = positions[1]
				context[pname].barrier_area.pos2 = positions[2]
			end)
		end,
	}
	idx = idx + 1.5

	-- FINISH EDITING
	elements.finishediting = {
		type = "button",
		exit = true,
		pos = {(5 - 0.2) - (ctf_gui.ELEM_SIZE.x / 2), idx},
		label = "Finish Editing",
		func = function(pname)
			minetest.after(0.1, function()
				if context[pname].initial_stuff[1] == "none" then
					table.remove(context[player].initial_stuff, 1)
				end

				ctf_map.save_map(context[pname])
				context[pname] = nil
			end)
		end,
	}
	idx = idx + 1

	-- Show formspec
	ctf_gui.show_formspec(player, "ctf_map:save", {
		title = "Capture The Flag Map Editor",
		description = "Save your map or edit the config.\nRemember to press ENTER after writing to a field",
		scrollheight = 176 + ((idx - 24) * 10) + 4,
		privs = {ctf_map_editor = true},
		elements = elements,
		scroll_pos = scroll_pos or 0,
	})
end
