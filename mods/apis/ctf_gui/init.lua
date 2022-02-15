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
		local ctx = context[pname]
		if not ctx then return end

		if ctx.formname == formname and ctx.elements then
			if ctx.privs then
				local playerprivs = minetest.get_player_privs(pname)

				for priv, needed in pairs(ctx.privs) do
					if needed and not playerprivs[priv] then
						minetest.log("warning", "Player " .. dump(pname) ..
							" doesn't have the privs needed to access the formspec " .. dump(formname))
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
					minetest.log("warning", "Player " .. dump(pname) ..
						" sent unallowed values for formspec " .. dump(formname) .. " : " .. dump(fields))
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

function ctf_gui.show_formspec(player, formname, formdef)
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

	context[player] = formdef

	minetest.show_formspec(player, formdef.formname, formspec)
end
