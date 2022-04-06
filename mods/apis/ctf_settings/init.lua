ctf_settings = {
	settings = {},
	settings_list = {},
}

local FORMSIZE = {x = 8, y = 5}
local SCROLLBAR_W = 0.4

minetest.after(0, function()
	table.sort(ctf_settings.settings_list, function(a, b) return a < b end)
end)

--[[
Settings should only be registered at loadtime

{
	type = "bool",
	label = "Setting name/label",
	description = "Text in tooltip",
	default = "default value",
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
			local lastypos

			for k, setting in ipairs(ctf_settings.settings_list) do
				local settingdef = ctf_settings.settings[setting]

				if settingdef.type == "bool" then
					lastypos = (k / 2) - 1
					setting_list[k] = {
						"checkbox[0,%f;%s;%s;%s]tooltip[%s;%s]",
						lastypos,
						setting,
						settingdef.label or setting,
						ctf_settings.get(player, setting),
						setting,
						settingdef.description or HumanReadable(setting)
					}
				end
			end

			local form = {
			{"box[-0.1,-0.1;%f,%f;#00000055]", FORMSIZE.x - SCROLLBAR_W, FORMSIZE.y},
				{"scroll_container[-0.1,0.3;%f,%f;settings_scrollbar;vertical;0.1]",
					FORMSIZE.x - SCROLLBAR_W,
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

			return sfinv.make_formspec(player, context, ctf_gui.list_to_formspec_str(form), true)
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
