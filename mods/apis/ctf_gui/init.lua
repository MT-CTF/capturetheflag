ctf_gui = {
	ELEM_SIZE = {x = 3, y = 0.7},
	SCROLLBAR_WIDTH = 0.7,
	FORM_SIZE = {x = 18, y = 13},
}

local context = {}
local gui_users_initialized = {}

function ctf_gui.init()
	local modname = minetest.get_current_modname()

	assert(not gui_users_initialized[modname], "Already initialized for mod "..dump(modname))

	gui_users_initialized[modname] = true

	ctf_core.register_on_formspec_input(modname..":", function(pname, formname, fields, ...)
		local ctx = context[pname]
		if not ctx then return end

		if ctx._formname == formname and ctx._on_formspec_input then
			if ctx._privs then
				local playerprivs = minetest.get_player_privs(pname)

				for priv, needed in pairs(ctx._privs) do
					if needed and not playerprivs[priv] then
						minetest.log("warning", string.format(
							"Player '%q' doesn't have the privs needed to access the formspec '%s'",
							pname, formname
						))
						return
					end
				end
			end

			if fields.quit and ctx._on_quit then
				ctx._on_quit(pname, fields)
			else
				local action = ctx._on_formspec_input(pname, ctx, fields, ...)

				if action == "refresh" then
					minetest.log("action", "Refreshing formspec "..dump(ctx._formname).." to "..dump(pname))
					minetest.show_formspec(pname, ctx._formname, ctx._formspec(ctx))
				end
			end
		end
	end)
end

function ctf_gui.old_init()
	local modname = minetest.get_current_modname()

	assert(not gui_users_initialized[modname], "Already initialized for mod: "..modname)

	gui_users_initialized[modname] = true

	ctf_core.register_on_formspec_input(modname..":", function(pname, formname, fields)
		local ctx = context[pname]
		if not ctx then return end

		if ctx.formname == formname and ctx.elements then
			if ctx.privs then
				local playerprivs = minetest.get_player_privs(pname)

				for priv, needed in pairs(ctx.privs) do
					if needed and not playerprivs[priv] then
						minetest.log("warning", string.format(
							"Player '%q' doesn't have the privs needed to access the formspec '%s'",
							pname, formname
						))
						return
					end
				end
			end

			for name, info in pairs(fields) do
				local element = ctx.elements[name]
				local bad = false
				if element then
					if element.type == "dropdown" then
						if element.give_idx then
							bad = not element.items[info]
						else
							bad = table.indexof(element.items, info) == -1
						end
					end
				end
				if bad then
					minetest.log("warning", string.format(
						"Player %s sent unallowed values for formspec %s : %s",
						pname, formname, dump(fields)
					))
					return
				end
			end

			for name, info in pairs(fields) do
				local element = ctx.elements[name]
				if element and element.func then
					element.func(pname, fields, name)
				end
			end
		end

		if fields.quit and ctx.on_quit then
			ctx.on_quit(pname, fields)
		end
	end)
end

function ctf_gui.show_formspec(player, formname, formspec, formcontext)
	player = PlayerName(player)

	context[player] = formcontext or {}

	context[player]._formname = formname
	context[player]._formspec = formspec

	minetest.log("action", "Showing new_formspec "..dump(formname).." to "..dump(player))
	if type(formspec) == "function" then
		minetest.show_formspec(player, formname, formspec(formcontext))
	else
		minetest.show_formspec(player, formname, formspec)
	end
end

do
	local remove = table.remove
	local concat = table.concat
	local formspec_escape = minetest.formspec_escape
	local format = string.format
	local unpck = unpack

	function ctf_gui.list_to_element(l)
		local base = remove(l, 1)

		for k, format_var in ipairs(l) do
			if type(format_var) == "string" then
				l[k] = formspec_escape(format_var)
			elseif type(format_var) == "table" then -- Assuming it's a list of strings
				for a, v in ipairs(format_var) do
					format_var[a] = formspec_escape(v)
				end

				l[k] = table.concat(format_var, ",")
			end
		end

		-- minetest.log("action", "[ctf_gui] unpacking: "..dump(l))
		return format(base, unpck(l))
	end

	local lte = ctf_gui.list_to_element

	function ctf_gui.list_to_formspec_str(l)
		for k, v in ipairs(l) do
			if type(v) == "table" then
				l[k] = lte(v)
			end
		end

		return concat(l, "")
	end
end

function ctf_gui.old_show_formspec(player, formname, formdef)
	player = PlayerName(player)
	formdef.formname = formname

	if not formdef.size then
		formdef.size = ctf_gui.FORM_SIZE
	end
	if not formdef.header_height then
		formdef.header_height = 1.6
	end
	if not formdef.scroll_extra then
		formdef.scroll_extra = {}
	end
	if not formdef.scroll_pos then
		formdef.scroll_pos = {}
	end

	minetest.handle_async(function(fdef, ELEM_SIZE, SCROLLBAR_WIDTH)
		local maxscroll = {x = 0, y = 0}
		local formspec = "formspec_version[4]" ..
				string.format("size[%f,%f]", fdef.size.x + SCROLLBAR_WIDTH, fdef.size.y + SCROLLBAR_WIDTH) ..
					"hypertext[0,0.2;"..fdef.size.x..","..fdef.header_height..
						";title;<center><big>"..fdef.title.."</big>" ..
						(fdef.description and ("\n"..fdef.description) or "") .."</center>]"

		local using_scrollbar = {x = false, y = false}
		if fdef.elements then
			for _, def in pairs(fdef.elements) do
				if def.pos then
					if not def.pos.x then def.pos.x = def.pos[1] end
					if not def.pos.y then def.pos.y = def.pos[2] end

					if not def.size then
						def.size = ELEM_SIZE
					else
						if not def.size.x then def.size.x = def.size[1] or ELEM_SIZE.x end
						if not def.size.y then def.size.y = def.size[2] or ELEM_SIZE.y end
					end

					if def.pos.x == "center" then
						def.pos.x = ( (fdef.size.x-(using_scrollbar.y and SCROLLBAR_WIDTH or 0)) - def.size.x )/2
					end

					if def.pos.x + def.size.x > maxscroll.x then
						maxscroll.x = def.pos.x + def.size.x
					end
					if def.pos.y + def.size.y > maxscroll.y then
						maxscroll.y = def.pos.y + def.size.y
					end
				end
			end

			formspec = string.format([[
				%s
				scroll_container[0.1,%f;%f,%f;formcontenty;vertical;0.1]
				scroll_container[0.1,0.1;%f,%f;formcontentx;horizontal;0.1]
				]],
				formspec,

				fdef.header_height-0.1,
				fdef.size.x,
				fdef.size.y,

				fdef.size.x,
				maxscroll.y
			)

			for id, def in pairs(fdef.elements) do
				id = minetest.formspec_escape(id)

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

			formspec = formspec .. "scroll_container_end[]scroll_container_end[]"

			local extscroll = {
				x = (maxscroll.x - fdef.size.x) * 10,
				y = ((maxscroll.y + fdef.header_height) - fdef.size.y) * 10,
			}

			for _, a in pairs({"x", "y"}) do
				if not fdef.scroll_pos[a] then
					fdef.scroll_pos[a] = 0
				elseif fdef.scroll_pos[a] == "max" then
					fdef.scroll_pos[a] = extscroll[a] or 0
				end
				if not fdef.scroll_extra[a] or fdef.scroll_extra[a] == "max" then
					fdef.scroll_extra[a] = extscroll[a] or 0
				end
			end

			if fdef.scroll_extra.x ~= "hide" and fdef.scroll_extra.x > 0 then
				formspec = string.format([[
					%s
					box[0,%f;%f,%f;#333333DD]
					scrollbaroptions[max=%f]
					scrollbar[0.1,%f;%f,%f;horizontal;formcontentx;%f]
					]],
					formspec,

					fdef.size.y+0.1,
					fdef.size.x + SCROLLBAR_WIDTH,
					SCROLLBAR_WIDTH,

					fdef.scroll_extra.x + 2,

					fdef.size.y+0.2,
					fdef.size.x,
					SCROLLBAR_WIDTH - 0.3,
					fdef.scroll_pos.x
				)
			end

			if fdef.scroll_extra.y ~= "hide" and fdef.scroll_extra.y > 0 then
				formspec = string.format([[
					%s
					scrollbaroptions[max=%f]
					scrollbar[%f,%f;%f,%f;vertical;formcontenty;%f]
					]],
					formspec,

					fdef.scroll_extra.y + 2,

					fdef.size.x+0.2,
					fdef.header_height,
					SCROLLBAR_WIDTH - 0.3,
					(fdef.size.y + SCROLLBAR_WIDTH) - (fdef.header_height + 0.1),
					fdef.scroll_pos.y
				)
			end
		end

		return fdef, formspec
	end,
	function(fdef, formspec)
		formdef.scroll_extra = fdef.scroll_extra
		formdef.scroll_pos = fdef.scroll_pos

		formdef._info = formdef
		context[player] = formdef

		if minetest.get_player_by_name(player) then
			minetest.log("action", "Showing formspec "..dump(formname).." to "..dump(player))
			minetest.show_formspec(player, formname, formspec)
		end
	end,
	formdef, ctf_gui.ELEM_SIZE, ctf_gui.SCROLLBAR_WIDTH)
end

minetest.register_on_leaveplayer(function(player)
	context[player:get_player_name()] = nil
end)

dofile(minetest.get_modpath("ctf_gui").."/dev.lua")
