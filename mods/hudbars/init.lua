hb = {}

hb.hudtables = {}

-- number of registered HUD bars
hb.hudbars_count = 0

-- table which records which HUD bar slots have been “registered” so far; used for automatic positioning
hb.registered_slots = {}

hb.settings = {}

function hb.load_setting(sname, stype, defaultval, valid_values)
	local sval
	if stype == "string" then
		sval = minetest.setting_get(sname)
	elseif stype == "bool" then
		sval = minetest.setting_getbool(sname)
	elseif stype == "number" then
		sval = tonumber(minetest.setting_get(sname))
	end
	if sval ~= nil then
		if valid_values ~= nil then
			local valid = false
			for i=1,#valid_values do
				if sval == valid_values[i] then
					valid = true
				end
			end
			if not valid then
				minetest.log("error", "[hudbars] Invalid value for "..sname.."! Using default value ("..tostring(defaultval)..").")
				return defaultval
			else
				return sval
			end
		else
			return sval
		end
	else
		return defaultval
	end
end

-- (hardcoded) default settings
hb.settings.max_bar_length = 160
hb.settings.statbar_length = 20

-- statbar positions
hb.settings.pos_left = {}
hb.settings.pos_right = {}
hb.settings.start_offset_left = {}
hb.settings.start_offset_right= {}
hb.settings.pos_left.x = hb.load_setting("hudbars_pos_left_x", "number", 0.5)
hb.settings.pos_left.y = hb.load_setting("hudbars_pos_left_y", "number", 1)
hb.settings.pos_right.x = hb.load_setting("hudbars_pos_right_x", "number", 0.5)
hb.settings.pos_right.y = hb.load_setting("hudbars_pos_right_y", "number", 1)
hb.settings.start_offset_left.x = hb.load_setting("hudbars_start_offset_left_x", "number", -175)
hb.settings.start_offset_left.y = hb.load_setting("hudbars_start_offset_left_y", "number", -86)
hb.settings.start_offset_right.x = hb.load_setting("hudbars_start_offset_right_x", "number", 15)
hb.settings.start_offset_right.y = hb.load_setting("hudbars_start_offset_right_y", "number", -86)

hb.settings.vmargin  = hb.load_setting("hudbars_tick", "number", 24)
hb.settings.tick = hb.load_setting("hudbars_tick", "number", 0.1)

-- experimental setting: Changing this setting is not officially supported, do NOT rely on it!
hb.settings.forceload_default_hudbars = hb.load_setting("hudbars_forceload_default_hudbars", "bool", true)

--[[
- hudbars_alignment_pattern: This setting changes the way the HUD bars are ordered on the display. You can choose
  between a zig-zag pattern or a vertically stacked pattern.
  The following values are allowed:
    zigzag: Starting from the left bottom, the next is right from the first,
              the next is above the first, the next is right of the third, etc.
              This is the default.
    stack_up: The HUD bars are stacked vertically, going upwards.
    stack_down: The HUD bars are stacked vertically, going downwards.
]]

-- Misc. settings
hb.settings.alignment_pattern = hb.load_setting("hudbars_alignment_pattern", "string", "zigzag", {"zigzag", "stack_up", "stack_down"})
hb.settings.bar_type = hb.load_setting("hudbars_bar_type", "string", "progress_bar", {"progress_bar", "statbar_classic", "statbar_modern"})
hb.settings.autohide_breath = hb.load_setting("hudbars_autohide_breath", "bool", true)

local sorting = minetest.setting_get("hudbars_sorting")
if sorting ~= nil then
	hb.settings.sorting = {}
	hb.settings.sorting_reverse = {}
	for k,v in string.gmatch(sorting, "(%w+)=(%w+)") do
		hb.settings.sorting[k] = tonumber(v)
		hb.settings.sorting_reverse[tonumber(v)] = k
	end
else
	hb.settings.sorting = { ["health"] = 0, ["breath"] = 1 }
	hb.settings.sorting_reverse = { [0] = "health", [1] = "breath" }
end

-- Table which contains all players with active default HUD bars (only for internal use)
hb.players = {}

function hb.value_to_barlength(value, max)
	if max == 0 then
		return 0
	else
		if hb.settings.bar_type == "progress_bar" then
			local x
			if value < 0 then x=-0.5 else x = 0.5 end
			local ret = math.modf((value/max) * hb.settings.max_bar_length + x)
			return ret
		else
			local x
			if value < 0 then x=-0.5 else x = 0.5 end
			local ret = math.modf((value/max) * hb.settings.statbar_length + x)
			return ret
		end
	end
end

function hb.get_hudtable(identifier)
	return hb.hudtables[identifier]
end

function hb.get_hudbar_position_index(identifier)
	if hb.settings.sorting[identifier] ~= nil then
		return hb.settings.sorting[identifier]
	else
		local i = 0
		while true do
			if hb.registered_slots[i] ~= true and hb.settings.sorting_reverse[i] == nil then
				return i
			end
			i = i + 1
		end
	end
end

function hb.register_hudbar(identifier, text_color, label, textures, default_start_value, default_start_max, default_start_hidden, format_string)
	minetest.log("action", "hb.register_hudbar: "..tostring(identifier))
	local hudtable = {}
	local pos, offset
	local index = math.floor(hb.get_hudbar_position_index(identifier))
	hb.registered_slots[index] = true
	if hb.settings.alignment_pattern == "stack_up" then
		pos = hb.settings.pos_left
		offset = {
			x = hb.settings.start_offset_left.x,
			y = hb.settings.start_offset_left.y - hb.settings.vmargin * index
		}
	elseif hb.settings.alignment_pattern == "stack_down" then
		pos = hb.settings.pos_left
		offset = {
			x = hb.settings.start_offset_left.x,
			y = hb.settings.start_offset_left.y + hb.settings.vmargin * index
		}
	else
		if index % 2 == 0 then
			pos = hb.settings.pos_left
			offset = {
				x = hb.settings.start_offset_left.x,
				y = hb.settings.start_offset_left.y - hb.settings.vmargin * (index/2)
			}
		else
			pos = hb.settings.pos_right
			offset = {
				x = hb.settings.start_offset_right.x,
				y = hb.settings.start_offset_right.y - hb.settings.vmargin * ((index-1)/2)
			}
		end
	end
	if format_string == nil then
		format_string = "%s: %d/%d"
	end

	hudtable.add_all = function(player, hudtable, start_value, start_max, start_hidden)
		if start_value == nil then start_value = hudtable.default_start_value end
		if start_max == nil then start_max = hudtable.default_start_max end
		if start_hidden == nil then start_hidden = hudtable.default_start_hidden end
		local ids = {}
		local state = {}
		local name = player:get_player_name()
		local bgscale, iconscale, text, barnumber
		if start_max == 0 or start_hidden then
			bgscale = { x=0, y=0 }
		else
			bgscale = { x=1, y=1 }
		end
		if start_hidden then
			iconscale = { x=0, y=0 }
			barnumber = 0
			text = ""
		else
			iconscale = { x=1, y=1 }
			barnumber = hb.value_to_barlength(start_value, start_max)
			text = string.format(format_string, label, start_value, start_max)
		end
		if hb.settings.bar_type == "progress_bar" then
			ids.bg = player:hud_add({
				hud_elem_type = "image",
				position = pos,
				scale = bgscale,
				text = "hudbars_bar_background.png",
				alignment = {x=1,y=1},
				offset = { x = offset.x - 1, y = offset.y - 1 },
			})
			if textures.icon ~= nil then
				ids.icon = player:hud_add({
					hud_elem_type = "image",
					position = pos,
					scale = iconscale,
					text = textures.icon,
					alignment = {x=-1,y=1},
					offset = { x = offset.x - 3, y = offset.y },
				})
			end
		elseif hb.settings.bar_type == "statbar_modern" then
			if textures.bgicon ~= nil then
				ids.bg = player:hud_add({
					hud_elem_type = "statbar",
					position = pos,
					scale = bgscale,
					text = textures.bgicon,
					number = hb.settings.statbar_length,
					alignment = {x=-1,y=-1},
					offset = { x = offset.x, y = offset.y },
				})
			end
		end
		local bar_image
		if hb.settings.bar_type == "progress_bar" then
			bar_image = textures.bar
		elseif hb.settings.bar_type == "statbar_classic" or hb.settings.bar_type == "statbar_modern" then
			bar_image = textures.icon
		end
		ids.bar = player:hud_add({
			hud_elem_type = "statbar",
			position = pos,
			text = bar_image,
			number = barnumber,
			alignment = {x=-1,y=-1},
			offset = offset,
		})
		if hb.settings.bar_type == "progress_bar" then
			ids.text = player:hud_add({
				hud_elem_type = "text",
				position = pos,
				text = text,
				alignment = {x=1,y=1},
				number = text_color,
				direction = 0,
				offset = { x = offset.x + 2,  y = offset.y },
		})
		end
		-- Do not forget to update hb.get_hudbar_state if you add new fields to the state table
		state.hidden = start_hidden
		state.value = start_value
		state.max = start_max
		state.text = text
		state.barlength = hb.value_to_barlength(start_value, start_max)

		local main_error_text =
			"[hudbars] Bad initial values of HUD bar identifier “"..tostring(identifier).."” for player "..name..". "

		if start_max < start_value then
			minetest.log("error", main_error_text.."start_max ("..start_max..") is smaller than start_value ("..start_value..")!")
		end
		if start_max < 0 then
			minetest.log("error", main_error_text.."start_max ("..start_max..") is smaller than 0!")
		end
		if start_value < 0 then
			minetest.log("error", main_error_text.."start_value ("..start_value..") is smaller than 0!")
		end

		hb.hudtables[identifier].hudids[name] = ids
		hb.hudtables[identifier].hudstate[name] = state
	end

	hudtable.identifier = identifier
	hudtable.format_string = format_string
	hudtable.label = label
	hudtable.hudids = {}
	hudtable.hudstate = {}
	hudtable.default_start_hidden = default_start_hidden
	hudtable.default_start_value = default_start_value
	hudtable.default_start_max = default_start_max

	hb.hudbars_count= hb.hudbars_count + 1
	
	hb.hudtables[identifier] = hudtable
end

function hb.init_hudbar(player, identifier, start_value, start_max, start_hidden)
	local hudtable = hb.get_hudtable(identifier)
	hb.hudtables[identifier].add_all(player, hudtable, start_value, start_max, start_hidden)
end

function hb.change_hudbar(player, identifier, new_value, new_max_value)
	if new_value == nil and new_max_value == nil then
		return
	end

	local name = player:get_player_name()
	local hudtable = hb.get_hudtable(identifier)
	local value_changed, max_changed = false, false

	if new_value ~= nil then
		if new_value ~= hudtable.hudstate[name].value then
			hudtable.hudstate[name].value = new_value
			value_changed = true
		end
	else
		new_value = hudtable.hudstate[name].value
	end
	if new_max_value ~= nil then
		if new_max_value ~= hudtable.hudstate[name].max then
			hudtable.hudstate[name].max = new_max_value
			max_changed = true
		end
	else
		new_max_value = hudtable.hudstate[name].max
	end

	local main_error_text =
		"[hudbars] Bad call to hb.change_hudbar, identifier: “"..tostring(identifier).."”, player name: “"..name.."”. "
	if new_max_value < new_value then
		minetest.log("error", main_error_text.."new_max_value ("..new_max_value..") is smaller than new_value ("..new_value..")!")
	end
	if new_max_value < 0 then
		minetest.log("error", main_error_text.."new_max_value ("..new_max_value..") is smaller than 0!")
	end
	if new_value < 0 then
		minetest.log("error", main_error_text.."new_value ("..new_value..") is smaller than 0!")
	end

	if hudtable.hudstate[name].hidden == false then
		if max_changed and hb.settings.bar_type == "progress_bar" then
			if hudtable.hudstate[name].max == 0 then
				player:hud_change(hudtable.hudids[name].bg, "scale", {x=0,y=0})
			else
				player:hud_change(hudtable.hudids[name].bg, "scale", {x=1,y=1})
			end
		end

		if value_changed or max_changed then
			local new_barlength = hb.value_to_barlength(new_value, new_max_value)
			if new_barlength ~= hudtable.hudstate[name].barlength then
				player:hud_change(hudtable.hudids[name].bar, "number", hb.value_to_barlength(new_value, new_max_value))
				hudtable.hudstate[name].barlength = new_barlength
			end

			if hb.settings.bar_type == "progress_bar" then
				local new_text = string.format(hudtable.format_string, hudtable.label, new_value, new_max_value)
				if new_text ~= hudtable.hudstate[name].text then
					player:hud_change(hudtable.hudids[name].text, "text", new_text)
					hudtable.hudstate[name].text = new_text
				end
			end
		end
	end
end

function hb.hide_hudbar(player, identifier)
	local name = player:get_player_name()
	local hudtable = hb.get_hudtable(identifier)
	if(hudtable.hudstate[name].hidden == false) then
		if hb.settings.bar_type == "progress_bar" then
			if hudtable.hudids[name].icon ~= nil then
				player:hud_change(hudtable.hudids[name].icon, "scale", {x=0,y=0})
			end
			player:hud_change(hudtable.hudids[name].bg, "scale", {x=0,y=0})
			player:hud_change(hudtable.hudids[name].text, "text", "")
		end
		player:hud_change(hudtable.hudids[name].bar, "number", 0)
		hudtable.hudstate[name].hidden = true
	end
end

function hb.unhide_hudbar(player, identifier)
	local name = player:get_player_name()
	local hudtable = hb.get_hudtable(identifier)
	if(hudtable.hudstate[name].hidden) then
		local name = player:get_player_name()
		local value = hudtable.hudstate[name].value
		local max = hudtable.hudstate[name].max
		if hb.settings.bar_type == "progress_bar" then
			if hudtable.hudids[name].icon ~= nil then
				player:hud_change(hudtable.hudids[name].icon, "scale", {x=1,y=1})
			end
			if hudtable.hudstate[name].max ~= 0 then
				player:hud_change(hudtable.hudids[name].bg, "scale", {x=1,y=1})
			end
			player:hud_change(hudtable.hudids[name].text, "text", tostring(string.format(hudtable.format_string, hudtable.label, value, max)))
		end
		player:hud_change(hudtable.hudids[name].bar, "number", hb.value_to_barlength(value, max))
		hudtable.hudstate[name].hidden = false
	end
end

function hb.get_hudbar_state(player, identifier)
	local ref = hb.get_hudtable(identifier).hudstate[player:get_player_name()]
	-- Do not forget to update this chunk of code in case the state changes
	local copy = {
		hidden = ref.hidden,
		value = ref.value,
		max = ref.max,
		text = ref.text,
		barlength = ref.barlength,
	}
	return copy
end

--register built-in HUD bars
if minetest.setting_getbool("enable_damage") or hb.settings.forceload_default_hudbars then
	hb.register_hudbar("health", 0xFFFFFF, "Health", { bar = "hudbars_bar_health.png", icon = "hudbars_icon_health.png", bgicon = "hudbars_bgicon_health.png" }, 20, 20, false)
	hb.register_hudbar("breath", 0xFFFFFF, "Breath", { bar = "hudbars_bar_breath.png", icon = "hudbars_icon_breath.png" }, 10, 10, true)
end

local function hide_builtin(player)
	local flags = player:hud_get_flags()
	flags.healthbar = false
	flags.breathbar = false
	player:hud_set_flags(flags)
end


local function custom_hud(player)
	if minetest.setting_getbool("enable_damage") or hb.settings.forceload_default_hudbars then
		local hide
		if minetest.setting_getbool("enable_damage") then
			hide = false
		else
			hide = true
		end
		hb.init_hudbar(player, "health", player:get_hp(), nil, hide)
		local breath = player:get_breath()
		local hide_breath
		if breath == 11 and hb.settings.autohide_breath == true then hide_breath = true else hide_breath = false end
		hb.init_hudbar(player, "breath", math.min(breath, 10), nil, hide_breath or hide)
	end
end


-- update built-in HUD bars
local function update_hud(player)
	if minetest.setting_getbool("enable_damage") then
		if hb.settings.forceload_default_hudbars then
			hb.unhide_hudbar(player, "health")
		end
		--air
		local breath = player:get_breath()
		
		if breath == 11 and hb.settings.autohide_breath == true then
			hb.hide_hudbar(player, "breath")
		else
			hb.unhide_hudbar(player, "breath")
			hb.change_hudbar(player, "breath", math.min(breath, 10))
		end
		
		--health
		hb.change_hudbar(player, "health", player:get_hp())
	elseif hb.settings.forceload_default_hudbars then
		hb.hide_hudbar(player, "health")
		hb.hide_hudbar(player, "breath")
	end
end

minetest.register_on_joinplayer(function(player)
	hide_builtin(player)
	custom_hud(player)
	hb.players[player:get_player_name()] = player
end)

minetest.register_on_leaveplayer(function(player)
	hb.players[player:get_player_name()] = nil
end)

local main_timer = 0
local timer = 0
minetest.register_globalstep(function(dtime)
	main_timer = main_timer + dtime
	timer = timer + dtime
	if main_timer > hb.settings.tick or timer > 4 then
		if main_timer > hb.settings.tick then main_timer = 0 end
		-- only proceed if damage is enabled
		if minetest.setting_getbool("enable_damage") or hb.settings.forceload_default_hudbars then
			for playername, player in pairs(hb.players) do
				-- update all hud elements
				update_hud(player)
			end
		end
	end
	if timer > 4 then timer = 0 end
end)
