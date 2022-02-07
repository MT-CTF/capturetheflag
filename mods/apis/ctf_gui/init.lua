ctf_gui = {
	ELEM_SIZE = {x = 3, y = 0.7},
	SCROLLBAR_WIDTH = 0.6,
	FORM_SIZE = {x = 18, y = 13},
}

local context = {}

local gui_users_initialized = {}
function ctf_gui.init()
	local modname = minetest.get_current_modname()

	assert(not gui_users_initialized[modname], "Already initialized for mod "..dump(modname))

	gui_users_initialized[modname] = true

	ctf_core.register_on_formspec_input(modname..":", function(pname, formname, fields)
		if not context[pname] then return end

		if context[pname]._info.formname == formname and context[pname].elements then
			for name, info in pairs(fields) do
				if context[pname].elements[name] then
					if context[pname].privs then
						local playerprivs = minetest.get_player_privs(pname)

						for priv, needed in pairs(context[pname].privs) do
							if needed and not playerprivs[priv] then
								minetest.log("warning", "Player " .. dump(pname) ..
										" doesn't have the privs needed to access the formspec " .. dump(formname))
								return
							end
						end
					end

					if type(context[pname].elements[name]) == "table" then
						if context[pname].elements[name].func then
							context[pname].elements[name].func(pname, fields, context[pname])
						end
					else
						local action = context[pname].elements[name](pname, fields, context[pname])

						if action == "refresh" then
							minetest.show_formspec(pname, context[pname]._info.formname, context[pname]._info.formspec(context[pname]))
						end
					end
				end
			end
		end

		if fields.quit and context[pname].on_quit then
			context[pname].on_quit(pname, fields)
		end
	end)
end

function ctf_gui.show_formspec_dev(player, formname, formspec, formcontext)
	local filepath = minetest.get_worldpath().."/ctf_gui/"
	local filename = filepath.."file_edit.txt"

	minetest.mkdir(filepath)

	local file, error = io.open(filename, "w")

	assert(file, error)

	file:write(formspec)

	file:close()

	local function interval()
		if formspec:sub(1, 3) == "[f]" then
			local result, form = pcall(loadstring(formspec:sub(4)), formcontext)
			ctf_gui.show_formspec(player, formname, result and form or "")
		else
			ctf_gui.show_formspec(player, formname, formspec)
		end

		minetest.after(1, function()
			local f = io.open(filename, "r")

			formspec = f:read("*a")

			f:close()

			if formspec ~= "exit" then
				interval()
			else
				minetest.request_shutdown("Formspec dev requested shutdown", true)
			end
		end)
	end

	interval()
end

function ctf_gui.show_formspec(player, formname, formspec, formcontext)
	player = PlayerName(player)

	context[player] = formcontext or {}

	context[player]._info = {
		formname = formname,
		formspec = formspec
	}

	if type(formspec) == "function" then
		minetest.show_formspec(player, formname, formspec(formcontext))
	else
		minetest.show_formspec(player, formname, formspec)
	end
end

function ctf_gui.old_show_formspec(player, formname, formdef)
	player = PlayerName(player)

	formdef.formname = formname

	if not formdef.size then
		formdef.size = ctf_gui.FORM_SIZE
	end

	local maxyscroll = 0
	local formspec = "formspec_version[4]" ..
			string.format("size[%f,%f]", formdef.size.x, formdef.size.y) ..
				"hypertext[0,0.2;"..formdef.size.x..
					",1.6;title;<center><big>"..formdef.title.."</big>\n" ..
					(formdef.description or "\b") .."</center>]" ..
				"scroll_container[0.1,1.5;"..formdef.size.x..
				","..formdef.size.y..";formcontent;vertical]"

	local using_scrollbar = false
	if formdef.elements then
		for _, def in pairs(formdef.elements) do
			if def.pos then
				if not def.pos.x then def.pos.x = def.pos[1] end
				if not def.pos.y then def.pos.y = def.pos[2] end

				if def.pos.y > maxyscroll then
					maxyscroll = def.pos.y
				end
			end
		end

		using_scrollbar = maxyscroll > 10

		for id, def in pairs(formdef.elements) do
			id = minetest.formspec_escape(id)

			if not def.size then
				def.size = ctf_gui.ELEM_SIZE
			else
				if not def.size.x then def.size.x = def.size[1] or ctf_gui.ELEM_SIZE.x end
				if not def.size.y then def.size.y = def.size[2] or ctf_gui.ELEM_SIZE.y end
			end


			if def.pos.x == "center" then
				def.pos.x = ( (formdef.size.x-(using_scrollbar and ctf_gui.SCROLLBAR_WIDTH or 0)) - def.size.x )/2
			end

			if def.type == "label" then
				if def.centered then
					formspec = formspec .. string.format(
						"style[%s;border=false]" ..
						"button[%f,%d;%f,%f;%s;%s]",
						id,
						def.pos.x,
						def.pos.y,
						def.size.x,
						def.size.y,
						id,
						minetest.formspec_escape(def.label)
					)
				else
					formspec = formspec .. string.format(
						"label[%f,%f;%s]",
						def.pos.x,
						def.pos.y,
						minetest.formspec_escape(def.label)
					)
				end
			elseif def.type == "field" then
				formspec = formspec .. string.format(
					"field_close_on_enter[%s;%s]"..
					"field[%f,%f;%f,%f;%s;%s;%s]",
					id,
					def.close_on_enter == true and "true" or "false",
					def.pos.x,
					def.pos.y,
					def.size.x,
					def.size.y,
					id,
					minetest.formspec_escape(def.label or ""),
					minetest.formspec_escape(def.default or "")
				)
			elseif def.type == "button" then
				formspec = formspec .. string.format(
					"button%s[%f,%f;%f,%f;%s;%s]",
					def.exit and "_exit" or "",
					def.pos.x,
					def.pos.y,
					def.size.x,
					def.size.y,
					id,
					minetest.formspec_escape(def.label)
				)
			elseif def.type == "dropdown" then
				formspec = formspec .. string.format(
					"dropdown[%f,%f;%f,%f;%s;%s;%d;%s]",
					def.pos.x,
					def.pos.y,
					def.size.x,
					def.size.y,
					id,
					table.concat(def.items, ","),
					def.default_idx or 1,
					def.give_idx and "true" or "false"
				)
			elseif def.type == "checkbox" then
				formspec = formspec .. string.format(
					"checkbox[%f,%f;%s;%s;%s]",
					def.pos.x,
					def.pos.y,
					id,
					minetest.formspec_escape(def.label),
					def.default and "true" or "false"
				)
			elseif def.type == "textarea" then
				formspec = formspec .. string.format(
					"textarea[%f,%f;%f,%f;%s;%s;%s]",
					def.pos.x,
					def.pos.y,
					def.size.x,
					def.size.y,
					def.read_only and "" or id,
					minetest.formspec_escape(def.label or ""),
					minetest.formspec_escape(def.default or "")
				)
			elseif def.type == "image" then
				formspec = formspec .. string.format(
					"image[%f,%f;%f,%f;%s]",
					def.pos.x,
					def.pos.y,
					def.size.x,
					def.size.y,
					minetest.formspec_escape(def.texture or "")
				)
			elseif def.type == "textlist" then
				if def.items then
					for k, v in pairs(def.items) do
						def.items[k] = minetest.formspec_escape(v)
					end
				end

				formspec = formspec .. string.format(
					"textlist[%f,%f;%f,%f;%s;%s;%d;%s]",
					def.pos.x,
					def.pos.y,
					def.size.x,
					def.size.y,
					id,
					def.items and table.concat(def.items, ",") or "",
					def.default_idx or 1,
					def.transparent and "true" or "false"
				)
			elseif def.type == "table" then
				if def.options then
					local tableoptions = {}
					for name, option in pairs(def.options) do
						if type(tonumber(name)) ~= "number" then
							table.insert(tableoptions, string.format("%s=%s", name, option))
						else
							table.insert(tableoptions, option)
						end
					end

					formspec = formspec ..
						string.format(
							"tableoptions[%s]",
							table.concat(tableoptions, ";")
						)
				end

				local tablecolumns = {}
				for _, column in ipairs(def.columns) do
					if type(column) == "table" then
						local tc_out = column.type

						column.type = nil

						for k, v in pairs(column) do
							tc_out = string.format("%s,%s=%s", tc_out, k, minetest.formspec_escape(v))
						end

						table.insert(tablecolumns, tc_out)
					else
						table.insert(tablecolumns, column)
					end
				end


				formspec = formspec ..
					string.format(
						"tablecolumns[%s]",
						table.concat(tablecolumns, ";")
					) ..
					string.format(
						"table[%f,%f;%f,%f;%s;%s;%d]",
						def.pos.x,
						def.pos.y,
						def.size.x,
						def.size.y,
						id,
						table.concat(def.rows, ","),
						def.default_idx or 1
					)
			end
		end
	end
	formspec = formspec .. "scroll_container_end[]"

	-- Add scrollbar if needed
	if using_scrollbar then
		if not formdef.scroll_pos then
			formdef.scroll_pos = 0
		elseif formdef.scroll_pos == "max" then
			formdef.scroll_pos = formdef.scrollheight or 500
		end

		formspec = formspec ..
				"scrollbaroptions[max=" .. (formdef.scrollheight or 500) ..";]" ..
				"scrollbar["..formdef.size.x-(ctf_gui.SCROLLBAR_WIDTH - 0.1) ..
					",1.8;"..(ctf_gui.SCROLLBAR_WIDTH - 0.1)..","..formdef.size.y - 1.8 ..
					";vertical;formcontent;" .. formdef.scroll_pos ..
				"]"
	end

	formdef._info = formdef
	context[player] = formdef

	minetest.show_formspec(player, formdef.formname, formspec)
end
