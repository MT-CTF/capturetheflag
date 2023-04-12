function ctf_gui.show_formspec_dev(player, formname, formspec, formcontext)
	local filepath = minetest.get_worldpath().."/ctf_gui/"
	local filename = filepath.."file_edit.txt"

	minetest.mkdir(filepath)

	local file = assert(io.open(filename, "w"))

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
			local f = assert(io.open(filename, "r"))

			formspec = f:read("*a")

			f:close()

			if formspec:match("^exit") then
				interval()
			else
				minetest.request_shutdown("Formspec dev requested shutdown", true)
			end
		end)
	end

	interval()
end
