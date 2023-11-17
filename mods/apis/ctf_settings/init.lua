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

function ctf_settings.set(player, setting, value)
	player:get_meta():set_string("ctf_settings:"..setting, value)
end

---@return string Returns the player's chosen setting value, the default given at registration, or if both are unset: ""
function ctf_settings.get(player, setting)
	local value = player:get_meta():get_string("ctf_settings:"..setting)
	local info = ctf_settings.settings[setting]

	return value == "" and info.default or value
end

minetest.register_on_mods_loaded(function()
	sfinv.register_page("ctf_settings:settings", {
		title = "Settings",
		get = function(self, player, context)
			local setting_list = {}
			local lastypos = -0.5

			for k, setting in ipairs(ctf_settings.settings_list) do
				local settingdef = ctf_settings.settings[setting]

				if settingdef.type == "bool" then
					setting_list[k] = {
						"checkbox[0,%f;%s;%s;%s]tooltip[%s;%s]",
						lastypos,
						setting,
						settingdef.label or setting,
						ctf_settings.get(player, setting),
						setting,
						settingdef.description or HumanReadable(setting)
					}

					lastypos = lastypos + 0.5
				elseif settingdef.type == "list" then
					lastypos = lastypos + 0.3
					setting_list[k] = {
						"dropdown[0,%f;%f;%s;%s;%d]tooltip[0,%f;%f,0.6;%s]",
						lastypos,
						FORMSIZE.x/1.7,
						setting,
						settingdef.list,
						ctf_settings.get(player, setting),
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
				{"scrollbaroptions[max=%d]", math.ceil((lastypos - 3.833) * 11.538)},
				{"scrollbar[%f,-0.1;%f,%f;vertical;settings_scrollbar;%f]",
				 FORMSIZE.x - SCROLLBAR_W,
				 SCROLLBAR_W,
				 FORMSIZE.y,
				 context and context.settings_scrollbar or 0
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

						ctf_settings.set(player, field, newvalue)

						if setting.on_change then
							setting.on_change(player, newvalue)
						end
					elseif setting.type == "list" then
						local idx = table.indexof(setting.list, value)

						if idx ~= -1 then
							ctf_settings.set(player, field, tostring(idx))

							if setting.on_change then
								setting.on_change(player, idx)
							end
						end
					end

					refresh = true
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
