ctf_settings = {
	settings = {},
	settings_list = {},
}

local FORMSIZE = {x = 8, y = 9.4}
local SCROLLBAR_W = 0.4

minetest.after(0, function()
	table.sort(ctf_settings.settings_list, function(a, b) return a < b end)
end)

--[[
Settings should only be registered at loadtime
{
	type = "bool" || "list",
	label = "Setting name/label", -- not used for list
	description = "Text in tooltip",
	list = {i1, i2, i3, i4}, -- used for list, remember to escape contents
	default = "default value/index",
	on_change = function(player, new_value)
		<...>
	end
}
]]
---@param def table
function ctf_settings.register(name, def)
	ctf_settings.settings[name] = def
	table.insert(ctf_settings.settings_list, name)
end

---@param player ObjectRef
function ctf_settings.set(player, setting, value)
	player:get_meta():set_string("ctf_settings:"..setting, value)
end

---@param player ObjectRef
---@return string Returns the player's chosen setting value, the default given at registration, or if both are unset: ""
function ctf_settings.get(player, setting)
	local value = player:get_meta():get_string("ctf_settings:"..setting)
	local info = ctf_settings.settings[setting]

	return value == "" and (info and info.default) or value
end

-- This Function MIT by Rubenwardy
--- Creates a scrollbaroptions for a scroll_container
--
-- @param visible_l the length of the scroll_container and scrollbar
-- @param total_l length of the scrollable area
-- @param scroll_factor as passed to scroll_container
local function make_scrollbaroptions_for_scroll_container(visible_l, total_l, scroll_factor)

	assert(total_l >= visible_l)

	local thumb_size = (visible_l / total_l) * (total_l - visible_l)

	local max = total_l - visible_l

	return ("scrollbaroptions[min=0;max=%f;thumbsize=%f]"):format(max / scroll_factor, thumb_size / scroll_factor)
end

minetest.register_on_mods_loaded(function()
	sfinv.register_page("ctf_settings:settings", {
		title = "Settings",
		get = function(self, player, context)
			local setting_list = {}
			local lastypos = -0.5

			if not context then
				context = {}
			end

			if not context.setting then
				context.setting = {}
			end

			for k, setting in ipairs(ctf_settings.settings_list) do
				local settingdef = ctf_settings.settings[setting]

				if not context.setting[setting] then
					context.setting[setting] = ctf_settings.get(player, setting)
				end

				if settingdef.type == "bool" then
					setting_list[k] = {
						"checkbox[0,%f;%s;%s;%s]tooltip[%s;%s]",
						lastypos,
						setting,
						settingdef.label or setting,
						context.setting[setting],
						setting,
						settingdef.description or HumanReadable(setting)
					}

					lastypos = lastypos + 0.5
				elseif settingdef.type == "list" then
					local max_len = 0

					for _, val in pairs(settingdef.list) do
						max_len = math.max(val:len(), max_len)
					end

					lastypos = lastypos + 0.3
					setting_list[k] = {
						"dropdown[0,%f;%f;%s;%s;%d]tooltip[0,%f;%f,0.6;%s]",
						lastypos,
						math.max(FORMSIZE.x / 2, math.min(FORMSIZE.x - SCROLLBAR_W + 2, 0.5 + (max_len * 0.23))),
						setting,
						settingdef.list,
						context.setting[setting],
						--label
						lastypos,
						(FORMSIZE.x/1.7) - 0.3,
						settingdef.description or HumanReadable(setting),
					}
					lastypos = lastypos + 0.6
				end
			end

			local form = {
			{"box[-0.1,-0.1;%f,%f;#00000055]", FORMSIZE.x - SCROLLBAR_W, FORMSIZE.y},
				{"scroll_container[-0.1,0.3;%f,%f;settings_scrollbar;vertical;0.1]",
					FORMSIZE.x - SCROLLBAR_W + 2,
					FORMSIZE.y + 0.7
				},
				ctf_gui.list_to_formspec_str(setting_list),
				"scroll_container_end[]",
				make_scrollbaroptions_for_scroll_container(FORMSIZE.y + 0.7, math.max(lastypos+1, FORMSIZE.y + 0.7), 0.1),
				{"scrollbar[%f,-0.1;%f,%f;vertical;settings_scrollbar;%f]",
					FORMSIZE.x - SCROLLBAR_W,
					SCROLLBAR_W,
					FORMSIZE.y,
					context.settings_scrollbar or 0
				},
			}

			return sfinv.make_formspec(player, context, ctf_gui.list_to_formspec_str(form), false)
		end,
		on_player_receive_fields = function(self, player, context, fields)
			local refresh = false

			for field, value in pairs(fields) do
				local setting = ctf_settings.settings[field]

				if setting then
					if setting.type == "bool" then
						local newvalue = value == "true" and "true" or "false"

						if context.setting[field] ~= newvalue then
							context.setting[field] = newvalue
							ctf_settings.set(player, field, newvalue)

							if setting.on_change then
								setting.on_change(player, newvalue)
							end

							refresh = true
						end
					elseif setting.type == "list" then
						local idx = table.indexof(setting.list, value)

						if idx ~= -1 and context.setting[field] ~= tostring(idx) then
							context.setting[field] = tostring(idx)
							ctf_settings.set(player, field, tostring(idx))

							if setting.on_change then
								setting.on_change(player, tostring(idx))
							end

							refresh = true
						end
					end
				end
			end

			if not refresh then return end

			if fields.settings_scrollbar then
				local scrollevent = minetest.explode_scrollbar_event(fields.settings_scrollbar)

				if scrollevent.value then
					context.settings_scrollbar = scrollevent.value
				end
			end


			sfinv.set_page(player, sfinv.get_page(player))
		end,
	})
end)

ctf_core.include_files("global_settings.lua")
