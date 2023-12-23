local unset_function = "[f]\nreturn "

function ctf_gui.show_formspec_dev(player, formname, formspec, formcontext)
	local filepath = minetest.get_worldpath().."/ctf_gui/"
	local filename = filepath.."file_edit.txt"
	local slower_loop = false

	minetest.chat_send_all("Started formspec editing file at "..filename)

	minetest.mkdir(filepath)

	local file = assert(io.open(filename, "w"))
		if type(formspec) ~= "function" then
			file:write(formspec)
		else
			file:write(unset_function)
		end
	file:close()

	local function interval()
		if type(formspec) == "function" then
			ctf_gui.show_formspec(player, formname, formspec(formcontext))
		elseif formspec:sub(1, 3) == "[f]" then
			local result, form = pcall((loadstring(formspec:sub(4)) or function() return function() end end)(), formcontext)

			ctf_gui.show_formspec(player, formname,
				result and form or "size[10,10]hypertext[0,0;10,10;err;"..minetest.formspec_escape(form or "").."]"
			)

			slower_loop = not result
		else
			ctf_gui.show_formspec(player, formname, formspec)
		end

		minetest.after(slower_loop and 3 or 1, function()
			local f = assert(io.open(filename, "r"))
			local new_form = f:read("*a")

			if new_form ~= unset_function then
				formspec = new_form
			end

			f:close()

			if type(formspec) == "function" or not formspec:match("^exit") then
				interval()
			else
				minetest.request_shutdown("Formspec dev requested shutdown", true)
			end
		end)
	end

	interval()
end
